# encoding: UTF-8

class Cubes

    # ----------------------------------------
    # File Management

    # Cubes::renameFile(filepath1)
    def self.renameFile(filepath1)
        filename2 = "#{Digest::SHA1.file(filepath1).hexdigest}.catalyst-cube"
        filepath2 = "#{File.dirname(filepath1)}/#{filename2}"
        return filepath1 if (filepath1 == filepath2)
        puts "filepath1: #{filepath1}".yellow
        puts "filepath2: #{filepath2}".yellow
        FileUtils.mv(filepath1, filepath2)
        filepath2
    end

    # Cubes::uuidFromFile(filepath)
    def self.uuidFromFile(filepath)
        if !File.exist?(filepath) then
            raise "(error: 1fe836ef-01a9-447e-87ee-11c3dcb9128f); filepath: #{filepath}"
        end
        uuid = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from _cube_ where _recordType_=? and _name_=?", ["attribute", "uuid"]) do |row|
            uuid = JSON.parse(row["_value_"])
        end
        db.close
        if uuid.nil? then
            raise "(error: dc064375-fa98-453a-9fc8-c242c6a9a270): filepath: #{filepath}"
        end
        uuid
    end

    # Cubes::existingFilepathOrNull(uuid)
    def self.existingFilepathOrNull(uuid)
        sha1 = Digest::SHA1.hexdigest(uuid)
        nhash = "SHA1-#{sha1}"
        folder = "#{Config::pathToGalaxy()}/DataHub/catalyst/Cubes/repository/#{sha1[0, 2]}/#{sha1[2, 2]}"
        return nil if !File.exist?(folder)
        Find.find(folder) do |path|
            next if !path.include?(".catalyst-cube")
            next if File.basename(path).start_with?('.') # .syncthing.82aafe48c87c22c703b32e35e614f4d7.catalyst-cube.tmp 
            if Cubes::uuidFromFile(path) == uuid then
                return path
            end
        end
        nil
    end

    # Cubes::createFile(uuid)
    def self.createFile(uuid)
        sha1 = Digest::SHA1.hexdigest(uuid)
        nhash = "SHA1-#{sha1}"
        folder = "#{Config::pathToGalaxy()}/DataHub/catalyst/Cubes/repository/#{sha1[0, 2]}/#{sha1[2, 2]}"
        if !File.exist?(folder) then
            FileUtils::mkpath(folder)
        end
        filename = "#{SecureRandom.hex}.catalyst-cube"
        filepath = "#{folder}/#{filename}"
        puts "> create item file: #{filepath}".yellow
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table _cube_ (_recorduuid_ text primary key, _recordTime_ float, _recordType_ string, _name_ text, _value_ blob)", [])
        db.execute "insert into _cube_ (_recorduuid_, _recordTime_, _recordType_, _name_, _value_) values (?, ?, ?, ?, ?)", [SecureRandom.hex(10), Time.new.to_f, "attribute", "uuid", JSON.generate(uuid)]
        db.close
        filepath
    end

    # Cubes::getFilepathCreateIfNeeded(uuid)
    def self.getFilepathCreateIfNeeded(uuid)
        filepath = Cubes::existingFilepathOrNull(uuid)
        return filepath if filepath
        filepath = Cubes::createFile(uuid)
        filepath
    end

    # Cubes::itemInit(uuid, mikuType)
    def self.itemInit(uuid, mikuType)
        Cubes::createFile(uuid)
        Cubes::setAttribute(uuid, "mikuType", mikuType)
    end

    # Cubes::destroy(uuid)
    def self.destroy(uuid)
        filepath = Cubes::existingFilepathOrNull(uuid)
        return if filepath.nil?

        item = Cubes::filepathToItem(filepath)
        if item and item["mikuType"] then
            folderpath = "#{Config::pathToGalaxy()}/DataHub/catalyst/Cubes/mikuTypes/#{item["mikuType"]}"
            if File.exist?(folderpath) then
                f2 = "#{folderpath}/#{SecureRandom.hex}.json"
                File.open(f2, "w"){|f| f.puts("[]") }
            end
        end

        puts "> delete item file: #{filepath}".yellow
        FileUtils.rm(filepath)
    end

    # ----------------------------------------
    # Blobs

    # Cubes::getBlobOrNull(uuid, nhash)
    def self.getBlobOrNull(uuid, nhash)
        filepath = Cubes::existingFilepathOrNull(uuid)
        return nil if filepath.nil?
        blob = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from _cube_ where _recordType_=? and _name_=?", ["datablob", nhash]) do |row|
            bx = row["_value_"]
            if "SHA256-#{Digest::SHA256.hexdigest(bx)}" == nhash then
                blob = bx
            end
        end
        db.close
        # We return a blob that was checked against the nhash
        # Also note that we allow for corrupted records before finding the right one.
        # See Cubes::putBlob, for more.
        blob
    end

    # Cubes::putBlob(uuid, blob)
    def self.putBlob(uuid, blob) # nhash
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        if bx = Cubes::getBlobOrNull(uuid, nhash) then
            return nhash
        end
        filepath = Cubes::getFilepathCreateIfNeeded(uuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        # Unlike other implementations, we do not delete a possible existing record.
        # Either there was none, ot there was one, but it's in correct
        # Also, treating these files as happen only ensure that we can merge them without logical issues.
        db.execute "insert into _cube_ (_recorduuid_, _recordTime_, _recordType_, _name_, _value_) values (?, ?, ?, ?, ?)", [SecureRandom.hex(10), Time.new.to_f, "datablob", nhash, blob]
        db.close
        Cubes::renameFile(filepath)
        nhash
    end

    # ----------------------------------------
    # Attributes

    # Cubes::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        filepath = Cubes::getFilepathCreateIfNeeded(uuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into _cube_ (_recorduuid_, _recordTime_, _recordType_, _name_, _value_) values (?, ?, ?, ?, ?)", [SecureRandom.hex(10), Time.new.to_f, "attribute", attrname, JSON.generate(attrvalue)]
        db.close

        # ----------------------------------------------------------------------
        filepath = Cubes::renameFile(filepath)
        item = Cubes::filepathToItem(filepath)
        return if item["mikuType"].nil?
        datum = {
            "item" => item,
            "filepath" => filepath
        }
        folderpath = "#{Config::pathToGalaxy()}/DataHub/catalyst/Cubes/mikuTypes/#{item["mikuType"]}"
        filecontents = JSON.pretty_generate([datum])
        filename = "#{Digest::SHA1.hexdigest(filecontents)}.json"
        filepath = "#{folderpath}/#{filename}"
        File.open(filepath, "w"){|f| f.puts(filecontents) }
        # ----------------------------------------------------------------------

        nil
    end

    # Cubes::getAttributeOrNull(uuid, attrname)
    def self.getAttributeOrNull(uuid, attrname)
        filepath = Cubes::existingFilepathOrNull(uuid)
        return nil if filepath.nil?
        value = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        # We extract the most recent value
        db.execute("select * from _cube_ where _recordType_=? and _name_=? order by _recordTime_", ["attribute", attrname]) do |row|
            value = JSON.parse(row["_value_"])
        end
        db.close
        value
    end

    # ----------------------------------------
    # Items

    # Cubes::mikuTypes()
    def self.mikuTypes()
        folderpath = "#{Config::pathToGalaxy()}/DataHub/catalyst/Cubes/mikuTypes"
        LucilleCore::locationsAtFolder(folderpath)
            .select{|location| !File.basename(location).start_with?('.') }
            .map{|location| File.basename(location) }
    end

    # Cubes::filepathToItem(filepath)
    def self.filepathToItem(filepath)
        raise "(error: 20013646-0111-4434-9d8f-9c90baca90a6)" if !File.exist?(filepath)
        return nil if filepath.nil?
        item = {}
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        # We extract the most recent value
        db.execute("select * from _cube_ where _recordType_=? order by _recordTime_", ["attribute"]) do |row|
            item[row["_name_"]] = JSON.parse(row["_value_"])
        end
        db.close
        item
    end

    # Cubes::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        filepath = Cubes::existingFilepathOrNull(uuid)
        return nil if filepath.nil?
        Cubes::filepathToItem(filepath)
    end

    # Cubes::generateCompleteMikuTypeFile(mikuType)
    def self.generateCompleteMikuTypeFile(mikuType)
        puts "generate mikutype file from zero: #{mikuType}".yellow
        data = []
        Find.find("#{Config::pathToGalaxy()}/DataHub/catalyst/Cubes/repository") do |path|
            next if !path.include?(".catalyst-cube")
            next if File.basename(path).start_with?('.') # .syncthing.82aafe48c87c22c703b32e35e614f4d7.catalyst-cube.tmp 
            item = Cubes::filepathToItem(path)
            next if item["mikuType"] != mikuType
            data << {
                "item" => item,
                "filepath" => path
            }
        end
        data
    end

    # Cubes::mikuType(mikuType)
    def self.mikuType(mikuType)
        folderpath = "#{Config::pathToGalaxy()}/DataHub/catalyst/Cubes/mikuTypes/#{mikuType}"
        filepath = "#{folderpath}/#{Config::thisInstanceId()}.json"
        if !File.exist?(filepath) then
            data = Cubes::generateCompleteMikuTypeFile(mikuType)
            File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(data)) }
        end
        data = JSON.parse(IO.read(filepath))
        if data.any?{|datum| !File.exist?(datum["filepath"]) } then
            data = data
                .map{|datum|
                    if File.exist?(datum["filepath"]) then
                        datum
                    else
                        filepath = Cubes::existingFilepathOrNull(uuid)
                        if filepath then
                            {
                                "item" => Cubes::filepathToItem(filepath),
                                "filepath" => filepath
                            }
                        else
                            nil
                        end
                    end
                }
                .compact
            File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(data)) }
        end
        data.map{|datum| datum["item"] }
    end

    # Cubes::catalystItems()
    def self.catalystItems()
        Cubes::mikuTypes()
            .map{|mikuType| Cubes::mikuType(mikuType) }
            .flatten
    end
end

class Elizabeth

    def initialize(uuid)
        @uuid = uuid
    end

    def putBlob(datablob) # nhash
        Cubes::putBlob(@uuid, datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        Cubes::getBlobOrNull(@uuid, nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        raise "(error: ff339aa3-b7ea-4b92-a211-5fc1048c048b, nhash: #{nhash})"
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 900a9a53-66a3-4860-be5e-dffa7a88c66d) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
