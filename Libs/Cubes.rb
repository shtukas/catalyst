# encoding: UTF-8

class Cubes

    # ----------------------------------------
    # File Management

    # Cubes::readUUIDFromFile(filepath)
    def self.readUUIDFromFile(filepath)
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
            if Cubes::readUUIDFromFile(path) == uuid then
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

    # ----------------------------------------
    # Blobs

    # Cubes::getBlobOrNull(uuid, nhash)
    def self.getBlobOrNull(uuid, nhash)
        filepath = Cubes::existingFilepathOrNull(uuid)
        return nil if !File.exist?(filepath)
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
end
