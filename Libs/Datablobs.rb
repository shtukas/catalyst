
# encoding: UTF-8

# The datablobs are currently stored in blades, one per uuid.

class Datablobs

    # Datablobs::putBlob(datablob) # nhash
    def self.putBlob(datablob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        repositoryFilePath = "#{Config::pathToCatalystDataRepository()}/Datablobs"
        folderpath = "#{repositoryFilePath}/2024/#{nhash[7, 2]}/#{nhash[9, 2]}"
        if !File.exist?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{nhash}.data"
        File.open(filepath, "w"){|f| f.write(datablob) }
        nhash
    end

    # Datablobs::getBlobOrNull(nhash, canWriteToXCache)
    def self.getBlobOrNull(nhash, canWriteToXCache) # data | nil

        # First we try XCache

        datablob = XCache::getOrNull("5cfe0b88-7ebd-46a6-aeda-b9b9284d7bd3:#{nhash}")
        if datablob then
            return datablob
        end

        # Then we try Galaxy's Datablob folder

        repositoryFilePath = "#{Config::pathToCatalystDataRepository()}/Datablobs"
        folderpath = "#{repositoryFilePath}/2024/#{nhash[7, 2]}/#{nhash[9, 2]}"
        filepath = "#{folderpath}/#{nhash}.data"
        if File.exist?(filepath) and canWriteToXCache then
            datablob = IO.read(filepath)
            puts "Writing datablob to XCache, #{nhash}".yellow
            XCache::set("5cfe0b88-7ebd-46a6-aeda-b9b9284d7bd3:#{nhash}", datablob)
            return datablob
        end

        # Then we try Orbital1

        repositoryFilePath = "/Volumes/Orbital1/Data/Catalyst/Datablobs"
        loop {
            break if File.exist?(repositoryFilePath)
            puts "I need to look up a datablob on Orbital1. Please plug and"
            LucilleCore::pressEnterToContinue()
        }

        folderpath = "#{repositoryFilePath}/2024/#{nhash[7, 2]}/#{nhash[9, 2]}"
        filepath = "#{folderpath}/#{nhash}.data"
        if File.exist?(filepath) then
            puts "reading from Orbital 1, #{nhash}".yellow
            datablob = IO.read(filepath)
            if canWriteToXCache then
                # We are not moving datablobs from Orbital1 to XCache during a global fsck
                puts "Writing datablob to XCache, #{nhash}".yellow
                XCache::set("5cfe0b88-7ebd-46a6-aeda-b9b9284d7bd3:#{nhash}", datablob)
            end
            return datablob
        end

        nil
    end
end

class Elizabeth

    def initialize(canWriteToXCache)
        @canWriteToXCache = canWriteToXCache
    end

    def putBlob(datablob) # nhash
        Datablobs::putBlob(datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        Datablobs::getBlobOrNull(nhash, @canWriteToXCache)
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