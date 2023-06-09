# encoding: UTF-8

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

class NegativeSpace
    # NegativeSpace::bladeRepository()
    def self.bladeRepository()
        "#{ENV["HOME"]}/Galaxy/DataHub/Blades"
    end

    # NegativeSpace::isBlade(filepath) # boolean
    def self.isBlade(filepath)
        File.basename(filepath).start_with?("blade-")
    end

    # NegativeSpace::getAttributeOrNull1(filepath, attribute_name)
    def self.getAttributeOrNull1(filepath, attribute_name)
        raise "(error: b1584ef9-20e9-4109-82d6-fef6d88e1265) filepath: #{filepath}, attribute_name, #{attribute_name}" if !File.exist?(filepath)
        value = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        # We go through all the values, because the one we want is the last one
        db.execute("select * from records where operation_type=? and _name_=? order by operation_unixtime", ["attribute", attribute_name]) do |row|
            value = JSON.parse(row["_data_"])
        end
        db.close
        value
    end

    # NegativeSpace::getMandatoryAttribute1(filepath, attribute_name)
    def self.getMandatoryAttribute1(filepath, attribute_name)
        value = NegativeSpace::getAttributeOrNull1(filepath, attribute_name)
        if value.nil? then
            raise "(error: f6d8c9d9-84cb-4f14-95c2-402d2471ef93) Failing mandatory attribute '#{attribute_name}' at blade '#{filepath}'"
        end
        value
    end

    # NegativeSpace::uuidToFilepathOrNull(uuid) # filepath or null
    def self.uuidToFilepathOrNull(uuid)
        # Let's try the uuid -> filepath mapping
        filepath = XCache::getOrNull("blades:uuid->filepath:mapping:7239cf3f7b6d:#{uuid}")
        return filepath if (filepath and File.exist?(filepath))

        # Got nothing from the uuid -> filepath mapping
        # Running exhaustive search.
        puts "Running exhaustive search to find blade filepath for uuid: #{uuid}"

        Find.find(NegativeSpace::bladeRepository()) do |filepath|
            next if !File.file?(filepath)
            next if !NegativeSpace::isBlade(filepath)
            uuidx = NegativeSpace::getMandatoryAttribute1(filepath, "uuid")
            XCache::set("blades:uuid->filepath:mapping:7239cf3f7b6d:#{uuidx}", filepath)
            return filepath if uuidx == uuid
        end

        nil
    end

    # NegativeSpace::getDatablobOrNull1(filepath, nhash)
    def self.getDatablobOrNull1(filepath, nhash)
        blob = DarkMatter::getBlobOrNull(nhash)
        return blob if blob

        raise "(error: 273139ba-e4ef-4345-a4de-2594ce77c563) filepath: #{filepath}" if !File.exist?(filepath)
        datablob = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from records where operation_type=? and _name_=? order by operation_unixtime", ["datablob", nhash]) do |row|
            datablob = row["_data_"]
        end
        db.close

        if datablob.nil? then
            # If we did not find a blob, it could be that the blob is at next.
            # Let's try that!
            nextuuid = NegativeSpace::getAttributeOrNull1(filepath, "next")
            if nextuuid then
                datablob = NegativeSpace::getDatablobOrNull2(nextuuid, nhash)
                if datablob then
                    DarkMatter::putBlob(datablob)
                    return datablob # 🎉
                end
            end
        end

        DarkMatter::putBlob(datablob)
        datablob
    end

    # NegativeSpace::getDatablobOrNull2(uuid, nhash)
    def self.getDatablobOrNull2(uuid, nhash)
        filepath = NegativeSpace::uuidToFilepathOrNull(uuid)
        raise "(error: bee6247e-c798-44a9-b72b-62773f75254e) uuid: #{uuid}" if filepath.nil?
        NegativeSpace::getDatablobOrNull1(filepath, nhash)
    end
end


class DarkMatter

    # DarkMatter::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        fragment1 = nhash[7, 2]
        fragment2 = nhash[9, 2]
        folderpath = "#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkMatter/2023-06/#{fragment1}/#{fragment2}"
        filepath = "#{folderpath}/#{nhash}.data"
        return nil if !File.exist?(filepath)
        IO.read(filepath)
    end

    # DarkMatter::putBlob(datablob) # nhash
    def self.putBlob(datablob) # nhash
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        puts "DarkMatter put blob: nhash: #{nhash}".green
        fragment1 = nhash[7, 2]
        fragment2 = nhash[9, 2]
        folderpath = "#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkMatter/2023-06/#{fragment1}/#{fragment2}"
        if !File.exist?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{nhash}.data"
        File.open(filepath, "w"){|f| f.write(datablob) }
        nhash2 = "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
        if nhash2 != nhash then
            raise "DarkMatter put blob: check of the file failed (nhash: #{nhash})"
            exit
        end
        nhash
    end
end

class DarkMatterElizabeth

    def initialize()
    end

    def putBlob(datablob) # nhash
        DarkMatter::putBlob(datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        DarkMatter::getBlobOrNull(nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        raise "(error: 7e168c83-2720-4299-bdba-de5c3cca9c0a, nhash: #{nhash})"
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: c8b47339-03c3-484c-9207-c2106e88acb7) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end

class DarkMatterElizabethLegacy

    def initialize(uuid)
        @uuid = uuid
    end

    def putBlob(datablob) # nhash
        DarkMatter::putBlob(datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        NegativeSpace::getDatablobOrNull2(@uuid, nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        raise "(error: 6923aca5-2e83-4379-9d58-6c09c185d07c, nhash: #{nhash})"
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 63374c58-b2f3-4e79-9844-2a110c57674d) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
