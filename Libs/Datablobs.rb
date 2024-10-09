
# encoding: UTF-8

class Datablobs

    # Datablobs::repositoryPath()
    def self.repositoryPath()
        "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/Datablobs"
    end

    # Datablobs::putBlob(uuid, blob) # nhash
    def self.putBlob(uuid, blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        folderpath = "#{Datablobs::repositoryPath()}/#{nhash[7, 2]}/#{nhash[9, 2]}"
        if !File.exist?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{nhash}.data"
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # Datablobs::getBlobOrNull(uuid, nhash)
    def self.getBlobOrNull(uuid, nhash) # data | nil
        folderpath = "#{Datablobs::repositoryPath()}/#{nhash[7, 2]}/#{nhash[9, 2]}"
        filepath = "#{folderpath}/#{nhash}.data"
        return nil if !File.exist?(filepath)
        IO.read(filepath)
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