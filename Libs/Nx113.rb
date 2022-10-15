
# encoding: UTF-8

class Nx113Make

    # Nx113Make::text(text) # nhash pointer to DataStore1 location of JSON encoded Nx113
    def self.text(text)
        {
            "mikuType" => "Nx113",
            "type"     => "text",
            "text"     => text
        }
    end

    # Nx113Make::url(url) # nhash pointer to DataStore1 location of JSON encoded Nx113
    def self.url(url)
        {
            "mikuType" => "Nx113",
            "type"     => "url",
            "url"      => url
        }
    end

    # Nx113Make::file(filepath) # nhash pointer to DataStore1 location of JSON encoded Nx113
    def self.file(filepath)
        raise "(error: d3539fc0-5615-46ff-809b-85ac34850070)" if !File.exists?(filepath)

        operator = DataStore2SQLiteBlobStoreElizabethTheForge.new()
        dottedExtension, nhash, parts = PrimitiveFiles::commitFileReturnDataElements(filepath, operator) # [dottedExtension, nhash, parts]

        {
            "mikuType"        => "Nx113",
            "type"            => "file",
            "dottedExtension" => dottedExtension,
            "nhash"           => nhash,
            "parts"           => parts,
            "database"        => operator.publish()
        }
    end

    # Nx113Make::aionpoint(location) # nhash pointer to DataStore1 location of JSON encoded Nx113
    def self.aionpoint(location)
        raise "(error: 93590239-f8e0-4f35-af47-d7f1407e21f2)" if !File.exists?(location)
        operator = DataStore2SQLiteBlobStoreElizabethTheForge.new()
        rootnhash = AionCore::commitLocationReturnHash(operator, location)
        {
            "mikuType"   => "Nx113",
            "type"       => "aion-point",
            "rootnhash"  => rootnhash,
            "database"   => operator.publish()
        }
    end

    # Nx113Make::dx8Unit(unitId) # nhash pointer to DataStore1 location of JSON encoded Nx113
    def self.dx8Unit(unitId)
        {
            "mikuType" => "Nx113",
            "type"     => "Dx8Unit",
            "unitId"   => unitId,
        }
    end

    # Nx113Make::uniqueString(uniquestring) # nhash pointer to DataStore1 location of JSON encoded Nx113
    def self.uniqueString(uniquestring)
        {
            "mikuType"     => "Nx113",
            "type"         => "unique-string",
            "uniquestring" => uniquestring,
        }
    end

    # Nx113Make::types()
    def self.types()
        ["text", "url", "file", "aion-point", "Dx8Unit", "unique-string"]
    end

    # Nx113Make::interactivelySelectOneNx113TypeOrNull()
    def self.interactivelySelectOneNx113TypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type", Nx113Make::types())
    end

    # Nx113Make::interactivelyMakeNx113OrNull() # nhash pointer to DataStore1 location of JSON encoded Nx113
    def self.interactivelyMakeNx113OrNull()
        type = Nx113Make::interactivelySelectOneNx113TypeOrNull()
        return nil if type.nil?
        if type == "text" then
            text = CommonUtils::editTextSynchronously("")
            nx113 = Nx113Make::text(text)
            FileSystemCheck::fsck_Nx113(nx113, SecureRandom.hex, true)
            return nx113
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            nx113 = Nx113Make::url(url)
            FileSystemCheck::fsck_Nx113(nx113, SecureRandom.hex, true)
            return nx113
        end
        if type == "file" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return nil if !File.file?(location)
            filepath = location
            nx113 = Nx113Make::file(filepath)
            FileSystemCheck::fsck_Nx113(nx113, SecureRandom.hex, true)
            return nx113
        end
        if type == "aion-point" then
            location = CommonUtils::interactivelySelectDesktopLocation()
            nx113 = Nx113Make::aionpoint(location)
            FileSystemCheck::fsck_Nx113(nx113, SecureRandom.hex, true)
            return nx113
        end
        if type == "Dx8Unit" then
            unitId = LucilleCore::askQuestionAnswerAsString("unitId (empty to abort): ")
            return nil if  unitId == ""
            nx113 = Nx113Make::dx8Unit(unitId)
            FileSystemCheck::fsck_Nx113(nx113, SecureRandom.hex, true)
            return nx113
        end
        if type == "unique-string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
            return nil if uniquestring.nil?
            nx113 = Nx113Make::uniqueString(uniquestring)
            FileSystemCheck::fsck_Nx113(nx113, SecureRandom.hex, true)
            return nx113
        end
        raise "(error: 0d26fe42-8669-4f33-9a09-aeecbd52c77c)"
    end
end

class Nx113Access

    # Nx113Access::access(nx113)
    def self.access(nx113)

        if nx113["type"] == "text" then
            CommonUtils::accessText(nx113["text"])
        end

        if nx113["type"] == "url" then
            url = nx113["url"]
            puts "url: #{url}"
            CommonUtils::openUrlUsingSafari(url)
        end

        if nx113["type"] == "file" then
            dottedExtension  = nx113["dottedExtension"]
            nhash            = nx113["nhash"]
            parts            = nx113["parts"]
            databasefilepath = DataStore1::getNearestFilepathForReadingErrorIfNotAcquisable(nx113["database"], true)
            operator         = DataStore2SQLiteBlobStoreElizabethReadOnly.new(databasefilepath)
            filepath         = "#{ENV['HOME']}/Desktop/#{nhash}#{dottedExtension}"
            File.open(filepath, "w"){|f|
                parts.each{|nhash|
                    blob = operator.getBlobOrNull(nhash)
                    raise "(error: 13709695-3dca-493b-be46-62d4ef6cf18f)" if blob.nil?
                    f.write(blob)
                }
            }
            system("open '#{filepath}'")
            puts "Item exported at #{filepath}"
            LucilleCore::pressEnterToContinue()
        end

        if nx113["type"] == "aion-point" then
            databasefilepath = DataStore1::getNearestFilepathForReadingErrorIfNotAcquisable(nx113["database"], true)
            operator         = DataStore2SQLiteBlobStoreElizabethReadOnly.new(databasefilepath)
            rootnhash        = nx113["rootnhash"]
            parentLocation   = "#{ENV['HOME']}/Desktop/aion-point-#{SecureRandom.hex(4)}"
            FileUtils.mkdir(parentLocation)
            AionCore::exportHashAtFolder(operator, rootnhash, parentLocation)
            puts "Item exported at #{parentLocation}"
            LucilleCore::pressEnterToContinue()
        end

        if nx113["type"] == "Dx8Unit" then
            unitId = nx113["unitId"]
            location = Dx8UnitsUtils::acquireUnitFolderPathOrNull(unitId)
            if location.nil? then
                puts "I could not acquire the Dx8Unit. Aborting operation."
                LucilleCore::pressEnterToContinue()
                return
            end
            puts "location: #{location}"
            if LucilleCore::locationsAtFolder(location).size == 1 and LucilleCore::locationsAtFolder(location).first[-5, 5] == ".webm" then
                location2 = LucilleCore::locationsAtFolder(location).first
                if File.basename(location2).include?("'") then
                    location3 = "#{File.dirname(location2)}/#{File.basename(location2).gsub("'", "-")}"
                    FileUtils.mv(location2, location3)
                    location2 = location3
                end
                location = location2
            end
            system("open '#{location}'")
            LucilleCore::pressEnterToContinue()
        end

        if nx113["type"] == "unique-string" then
            uniquestring = item["uniquestring"]
            UniqueStringsFunctions::findAndAccessUniqueString(uniquestring)
        end
    end

    # Nx113Access::toStringOrNull(prefix, nx113, postfix)
    def self.toStringOrNull(prefix, nx113, postfix)
        return nil if nx113.nil?
        "#{prefix}(Nx113: #{nx113["type"]})#{postfix}"
    end

    # Nx113Access::toStringOrNullShort(prefix, nx113, postfix)
    def self.toStringOrNullShort(prefix, nx113, postfix)
        return nil if nx113.nil?
        "#{prefix}(#{nx113["type"]})#{postfix}"
    end
end

class Nx113Edit

    # Nx113Edit::edit(item)
    def self.edit(item)
        return if item["nx113"].nil?

        nx113 = item["nx113"]

        if nx113["type"] == "text" then
            newtext = CommonUtils::editTextSynchronously(nx113["text"])
            nx113 = Nx113Make::text(newtext)
            Phage::setAttribute2(item["uuid"], "nx113", nx113)
        end

        if nx113["type"] == "url" then
            puts "current url: #{nx113["url"]}"
            url2 = LucilleCore::askQuestionAnswerAsString("new url: ")
            nx113 = Nx113Make::url(url2)
            Phage::setAttribute2(item["uuid"], "nx113", nx113)
        end

        if nx113["type"] == "file" then
            Nx113Access::access(item["nx113"])
            filepath = CommonUtils::interactivelySelectDesktopLocationOrNull()
            nx113 = Nx113Make::file(filepath)
            Phage::setAttribute2(item["uuid"], "nx113", nx113)
        end

        if nx113["type"] == "aion-point" then
            databasefilepath = DataStore1::getNearestFilepathForReadingErrorIfNotAcquisable(nx113["database"], true)
            operator         = DataStore2SQLiteBlobStoreElizabethReadOnly.new(databasefilepath)
            rootnhash        = nx113["rootnhash"]
            exportLocation   = "#{ENV['HOME']}/Desktop/aion-point-#{SecureRandom.hex(4)}"
            FileUtils.mkdir(exportLocation)
            AionCore::exportHashAtFolder(operator, rootnhash, exportLocation)
            puts "Item exported at #{exportLocation} for edition"
            LucilleCore::pressEnterToContinue()

            acquireLocationInsideExportFolder = lambda {|exportLocation|
                locations = LucilleCore::locationsAtFolder(exportLocation).select{|loc| File.basename(loc)[0, 1] != "."}
                if locations.size == 0 then
                    puts "I am in the middle of a Nx113 aion-point edit. I cannot see anything inside the export folder"
                    puts "Exit"
                    exit
                end
                if locations.size == 1 then
                    return locations[0]
                end
                if locations.size > 1 then
                    puts "I am in the middle of a Nx113 aion-point edit. I found more than one location in the export folder."
                    puts "Exit"
                    exit
                end
            }

            operator = DataStore2SQLiteBlobStoreElizabethTheForge.new()
            location = acquireLocationInsideExportFolder.call(exportLocation)
            puts "reading: #{location}"
            rootnhash = AionCore::commitLocationReturnHash(operator, location)
            nx113 = {
                "mikuType"   => "Nx113",
                "type"       => "aion-point",
                "rootnhash"  => rootnhash,
                "database"   => operator.publish()
            }
            Phage::setAttribute2(item["uuid"], "nx113", nx113)
        end

        if nx113["type"] == "Dx8Unit" then
            puts "Edit is not implemented for Dx8Units"
            LucilleCore::pressEnterToContinue()
        end

        if nx113["type"] == "unique-string" then
            puts "Edit is not implemented for unique-string"
            LucilleCore::pressEnterToContinue()
        end
    end
end
