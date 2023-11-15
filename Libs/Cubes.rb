# encoding: UTF-8

class Cubes

    # Cubes::filepath(uuid)
    def self.filepath(uuid)
        sha1 = Digest::SHA1.hexdigest(uuid)
        nhash = "SHA1-#{sha1}"
        filename = "#{nhash}.cube"
        folderpath = "#{Config::pathToGalaxy()}/DataHub/catalyst/Cubes/repository/#{sha1[0, 2]}/#{sha1[2, 2]}"
        if !File.exist?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        "#{folderpath}/#{filename}"
    end

    # Cubes::createFile(filepath, uuid)
    def self.createFile(filepath, uuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table _cube_ (_recorduuid_ text primary key, _recordTime_ float, _recordType_ string, _name_ text, _value_ blob)", [])
        db.execute "insert into _cube_ (_recorduuid_, _recordTime_, _recordType_, _name_, _value_) values (?, ?, ?, ?, ?)", [SecureRandom.hex(10), Time.new.to_f, "attribute", "uuid", JSON.generate(uuid)]
        db.close
    end

    # Cubes::ensureFile(uuid)
    def self.ensureFile(uuid)
        filepath = Cubes::filepath(uuid)
        return if File.exist?(filepath)
        Cubes::createFile(filepath, uuid)
    end

end
