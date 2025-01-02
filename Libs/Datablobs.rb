
# encoding: UTF-8

# The datablobs are currently stored in blades, one per uuid.

class Datablobs

    # Datablobs::repositoryPath()
    def self.repositoryPath()
        "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/Datablobs"
    end

    # Datablobs::uuidToFilepath(uuid)
    def self.uuidToFilepath(uuid)
        filepath1 = "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/Blades/#{uuid}.sqlite3"
        return filepath1 if File.exist?(filepath1)
        if !File.exist?("/Volumes/Orbital1/Data") then
            puts "I need Orbital 1, please plug and"
            LucilleCore::pressEnterToContinue()
        end
        filepath2 = "/Volumes/Orbital1/Data/Catalyst/Blades/#{uuid}.sqlite3"
        return filepath1 if !File.exist?(filepath2)
        FileUtils.mv(filepath2, filepath1)
        filepath1
    end

    # Datablobs::ensureFile(uuid)
    def self.ensureFile(uuid)
        filepath = Datablobs::uuidToFilepath(uuid)
        return if File.exist?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("CREATE TABLE datablobs (key string, datablob blob);", [])
        db.commit
        db.close
    end

    # Datablobs::deleteFile(uuid)
    def self.deleteFile(uuid)
        filepath = Datablobs::uuidToFilepath(uuid)
        return if !File.exist?(filepath)
        puts "remove filepath: #{filepath}".yellow
        FileUtils.rm(filepath)
    end

    # Datablobs::putBlob(uuid, datablob) # nhash
    def self.putBlob(uuid, datablob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"

        # Version 1
        #folderpath = "#{Datablobs::repositoryPath()}/#{nhash[7, 2]}/#{nhash[9, 2]}"
        #if !File.exist?(folderpath) then
        #    FileUtils.mkpath(folderpath)
        #end
        #filepath = "#{folderpath}/#{nhash}.data"
        #File.open(filepath, "w"){|f| f.write(blob) }

        # Version 2
        Datablobs::ensureFile(uuid)
        filepath = Datablobs::uuidToFilepath(uuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from datablobs where key=?", [nhash])
        db.execute("insert into datablobs (key, datablob) values (?, ?)", [nhash, datablob])
        db.commit
        db.close

        nhash
    end

    # Datablobs::getBlobOrNull(uuid, nhash)
    def self.getBlobOrNull(uuid, nhash) # data | nil
        datablob = nil

        # Version 1
        #folderpath = "#{Datablobs::repositoryPath()}/#{nhash[7, 2]}/#{nhash[9, 2]}"
        #filepath = "#{folderpath}/#{nhash}.data"
        #return nil if !File.exist?(filepath)
        #IO.read(filepath)

        # Version 2
        Datablobs::ensureFile(uuid)
        filepath = Datablobs::uuidToFilepath(uuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from datablobs where key=?", [nhash]) do |row|
            datablob = row["datablob"]
        end
        db.close

        datablob
    end
end

class Elizabeth

    def initialize(uuid)
        @uuid = uuid
    end

    def putBlob(datablob) # nhash
        Datablobs::putBlob(@uuid, datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        Datablobs::getBlobOrNull(@uuid, nhash)
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