# encoding: UTF-8

class Cubes1

    # ----------------------------------------
    # File Management (1)

    # Cubes1::pathToCubes()
    def self.pathToCubes()
        "#{Config::pathToCatalystDataRepository()}/Cubes"
    end

    # Cubes1::itemInit(uuid, mikuType)
    def self.itemInit(uuid, mikuType)
        filepath = "/tmp/#{SecureRandom.hex}"
        puts "> create item file: #{filepath}".yellow
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table _cube_ (_recorduuid_ text primary key, _recordTime_ float, _recordType_ string, _name_ text, _value_ blob)", [])
        db.execute "insert into _cube_ (_recorduuid_, _recordTime_, _recordType_, _name_, _value_) values (?, ?, ?, ?, ?)", [SecureRandom.hex(10), Time.new.to_f, "attribute", "uuid", JSON.generate(uuid)]
        db.execute "insert into _cube_ (_recorduuid_, _recordTime_, _recordType_, _name_, _value_) values (?, ?, ?, ?, ?)", [SecureRandom.hex(10), Time.new.to_f, "attribute", "mikuType", JSON.generate(mikuType)]
        db.close
        Cubes1::relocate(filepath)
    end

    # Cubes1::existingFilepathOrNull(uuid)
    def self.existingFilepathOrNull(uuid)
        filepath = XCache::getOrNull("ee710030-93d3-43db-bb18-1a5b7d5e24ec:#{uuid}")
        if filepath and File.exist?(filepath) then
            # We do not need to check the uuid of the file because of content addressing
            return filepath
        end

        LucilleCore::locationsAtFolder(Cubes1::pathToCubes())
            .select{|location| location[-14, 14] == ".catalyst-cube" }
            .each{|filepath|
                u1 = Cubes1::uuidFromFile(filepath)
                XCache::set("ee710030-93d3-43db-bb18-1a5b7d5e24ec:#{u1}", filepath)
                if u1 == uuid then
                    return filepath
                end
            }

        nil
    end

    # Cubes1::relocate(filepath1)
    def self.relocate(filepath1)
        folderpath2 = Cubes1::pathToCubes()
        filename2 = "#{Digest::SHA1.file(filepath1).hexdigest}.catalyst-cube"
        filepath2 = "#{folderpath2}/#{filename2}"
        return filepath1 if (filepath1 == filepath2)
        #puts "filepath1: #{filepath1}".yellow
        #puts "filepath2: #{filepath2}".yellow
        FileUtils.mv(filepath1, filepath2)
        uuid = Cubes1::uuidFromFile(filepath2)
        XCache::set("ee710030-93d3-43db-bb18-1a5b7d5e24ec:#{uuid}", filepath2)
        filepath2
    end

    # Cubes1::merge(filepath1, filepath2)
    def self.merge(filepath1, filepath2)
        filepath = "/tmp/#{SecureRandom.hex}"
        #puts "> merging files:".yellow
        #puts "    #{filepath1}".yellow
        #puts "    #{filepath2}".yellow

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table _cube_ (_recorduuid_ text primary key, _recordTime_ float, _recordType_ string, _name_ text, _value_ blob)", [])

        db1 = SQLite3::Database.new(filepath1)
        db1.busy_timeout = 117
        db1.busy_handler { |count| true }
        db1.results_as_hash = true
        # We extract the most recent value
        db1.execute("select * from _cube_", []) do |row|
            db.execute "insert into _cube_ (_recorduuid_, _recordTime_, _recordType_, _name_, _value_) values (?, ?, ?, ?, ?)", [row["_recorduuid_"], row["_recordTime_"], row["_recordType_"], row["_name_"], row["_value_"]]
        end
        db1.close

        db2 = SQLite3::Database.new(filepath2)
        db2.busy_timeout = 117
        db2.busy_handler { |count| true }
        db2.results_as_hash = true
        # We extract the most recent value
        db2.execute("select * from _cube_", []) do |row|
            db.execute("delete from _cube_ where _recorduuid_=?", [row["_recorduuid_"]])
            db.execute "insert into _cube_ (_recorduuid_, _recordTime_, _recordType_, _name_, _value_) values (?, ?, ?, ?, ?)", [row["_recorduuid_"], row["_recordTime_"], row["_recordType_"], row["_name_"], row["_value_"]]
        end
        db2.close

        db.close

        FileUtils.rm(filepath1)
        FileUtils.rm(filepath2)
        Cubes1::relocate(filepath)
    end

    # Cubes1::maintenance()
    def self.maintenance()
        filepaths = []
        Find.find(Cubes1::pathToCubes()) do |path|
            next if !path.include?(".catalyst-cube")
            next if File.basename(path).start_with?('.') # avoiding: .syncthing.82aafe48c87c22c703b32e35e614f4d7.catalyst-cube.tmp 
            filepaths << path
        end
        mapping = {}
        filepaths.each{|filepath|
            uuid = Cubes1::uuidFromFile(filepath)
            mapping[uuid] = (mapping[uuid] || []) + [filepath]
        }
        mapping.each{|uuid, filepaths|
            next if filepaths.size == 1
            if filepaths.size == 0 then
                raise "(error: ab8e-9926a61562b4) this should not happen: uuid: #{uuid}, filepaths: #{filepaths.join(", ")}"
            end
            filepath1, filepath2 = filepaths
            Cubes1::merge(filepath1, filepath2)
        }
    end

    # ----------------------------------------
    # File Management (2)

    # Cubes1::uuidFromFile(filepath)
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

    # Cubes1::filepathToItem(filepath)
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

    # ----------------------------------------
    # Items

    # Cubes1::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        filepath = Cubes1::existingFilepathOrNull(uuid)
        return nil if filepath.nil?
        Cubes1::filepathToItem(filepath)
    end

    # Cubes1::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        filepath = Cubes1::existingFilepathOrNull(uuid)
        if filepath.nil? then
            raise "(error: b2a27beb-7b23-4077-af2f-ba408ed37748); uuid: #{uuid}, attrname: #{attrname}, attrvalue: #{attrvalue}"
        end
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into _cube_ (_recorduuid_, _recordTime_, _recordType_, _name_, _value_) values (?, ?, ?, ?, ?)", [SecureRandom.hex(10), Time.new.to_f, "attribute", attrname, JSON.generate(attrvalue)]
        db.close
        Cubes1::relocate(filepath)
        nil
    end

    # Cubes1::getAttributeOrNull(uuid, attrname)
    def self.getAttributeOrNull(uuid, attrname)
        filepath = Cubes1::existingFilepathOrNull(uuid)
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

    # Cubes1::getBlobOrNull(uuid, nhash)
    def self.getBlobOrNull(uuid, nhash)
        filepath = Cubes1::existingFilepathOrNull(uuid)
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
        # See Cubes1::putBlob, for more.
        blob
    end

    # Cubes1::putBlob(uuid, blob)
    def self.putBlob(uuid, blob) # nhash
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        if bx = Cubes1::getBlobOrNull(uuid, nhash) then
            return nhash
        end
        filepath = Cubes1::existingFilepathOrNull(uuid)
        if filepath.nil? then
            raise "(error: e6cea94f-1b92-46ad-96af-adf9ecbded1d); uuid: #{uuid}"
        end
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        # Unlike other implementations, we do not delete a possible existing record.
        # Either there was none, ot there was one, but it's in correct
        # Also, treating these files as happen only ensure that we can merge them without logical issues.
        db.execute "insert into _cube_ (_recorduuid_, _recordTime_, _recordType_, _name_, _value_) values (?, ?, ?, ?, ?)", [SecureRandom.hex(10), Time.new.to_f, "datablob", nhash, blob]
        db.close
        Cubes1::relocate(filepath)
        nhash
    end

    # Cubes1::destroy(uuid)
    def self.destroy(uuid)
        filepath = Cubes1::existingFilepathOrNull(uuid)
        return if filepath.nil?
        puts "> delete item file: #{filepath}".yellow
        FileUtils.rm(filepath)
    end

    # ----------------------------------------
    # Items

    # Cubes1::items()
    def self.items()
        items = []
        Find.find(Cubes1::pathToCubes()) do |path|
            next if !path.include?(".catalyst-cube")
            next if File.basename(path).start_with?('.') # avoiding: .syncthing.82aafe48c87c22c703b32e35e614f4d7.catalyst-cube.tmp 
            items << Cubes1::filepathToItem(path)
        end
        items
    end

    # Cubes1::mikuType(mikuType)
    def self.mikuType(mikuType)
        Cubes1::items().select{|item| item["mikuType"] == mikuType }
    end
end

class Elizabeth

    def initialize(uuid)
        @uuid = uuid
    end

    def putBlob(datablob) # nhash
        Cubes1::putBlob(@uuid, datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        Cubes1::getBlobOrNull(@uuid, nhash)
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
