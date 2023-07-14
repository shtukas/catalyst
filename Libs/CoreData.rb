
# encoding: UTF-8

class CoreData

    # CoreData::coreDataReferenceTypes()
    def self.coreDataReferenceTypes()
        ["text", "url", "aion point", "open cycle", "unique string", "Dx8Unit"]
    end

    # CoreData::interactivelySelectCoreDataReferenceType()
    def self.interactivelySelectCoreDataReferenceType()
        types = CoreData::coreDataReferenceTypes()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("coredata reference type", types)
    end

    # CoreData::locationToAionPointCoreDataReference(location)
    def self.locationToAionPointCoreDataReference(location)
        if !File.exists?(location) then
            raise "(error: c1d975c5-8d18-4f28-abde-9a32869af017) CoreData::locationToAionPointCoreDataReference, location: '#{location}' does not exist."
        end
        nhash = AionCore::commitLocationReturnHash(DarkMatterElizabeth.new(), location)
        "aion-point:#{nhash}"
    end

    # CoreData::interactivelyMakeNewReferenceStringOrNull() # payload string
    def self.interactivelyMakeNewReferenceStringOrNull()
        # This function is called during the making of a new node (or when we are issuing a new payload of an existing node)
        # It does stuff and returns a payload string or null
        referencetype = CoreData::interactivelySelectCoreDataReferenceType()
        if referencetype.nil? then
            return nil
        end
        if referencetype == "text" then
            text = CommonUtils::editTextSynchronously("")
            nhash = DarkMatter::putBlob(text)
            return "text:#{nhash}"
        end
        if referencetype == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            nhash = DarkMatter::putBlob(url)
            return "url:#{nhash}"
        end
        if referencetype == "aion point" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return CoreData::locationToAionPointCoreDataReference(location)
        end
        if referencetype == "open cycle" then
            fname = LucilleCore::askQuestionAnswerAsString("OpenCycle directory name: ")
            if !fname.start_with?("20") then
                fname = "#{CommonUtils::today()} #{fname}"
            end
            folderpath = "#{Config::pathToGalaxy()}/OpenCycles/#{fname}"
            if !File.exist?(folderpath) then
                FileUtils.mkdir(folderpath)
            end
            return "open-cycle:#{fname}"
        end
        if referencetype == "unique string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (if needed use Nx01-#{SecureRandom.hex[0, 12]}): ")
            return "unique-string:#{uniquestring}"
        end
        if referencetype == "Dx8Unit" then
            unitId = LucilleCore::askQuestionAnswerAsString("Dx8Unit Id: ")
            return "Dx8UnitId:#{unitId}"
        end
        raise "(error: f75b2797-99e5-49d0-8d49-40b44beb538c) unsupported core data reference type: #{referencetype}"
    end

    # CoreData::referenceStringToSuffixString(referenceString)
    def self.referenceStringToSuffixString(referenceString)
        if referenceString.nil? then
            return ""
        end
        if referenceString == "null" then
            return ""
        end
        if referenceString.start_with?("text") then
            return " (text)"
        end
        if referenceString.start_with?("url") then
            return " (url)"
        end
        if referenceString.start_with?("aion-point") then
            return " (aion point)"
        end
        if referenceString.start_with?("open-cycle") then
            return " (open-cycle)"
        end
        if referenceString.start_with?("unique-string") then
            str = referenceString.split(":")[1]
            return " (unique string: #{str})"
        end
        if referenceString.start_with?("Dx8UnitId") then
            return " (Dx8Unit)"
        end
        raise "CoreData, I do not know how to string '#{referenceString}'"
    end

    # CoreData::itemToSuffixString(item)
    def self.itemToSuffixString(item)
        CoreData::referenceStringToSuffixString(item["field11"])
    end

    # CoreData::access(uuid, referenceString)
    def self.access(uuid, referenceString)
        if referenceString.nil? then
            puts "Accessing null reference string. Nothing to do."
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString == "null" then
            puts "Accessing null reference string. Nothing to do."
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString.start_with?("text") then
            nhash = referenceString.split(":")[1]
            text = DarkMatter::getBlobOrNull(nhash)
            puts "--------------------------------------------------------------"
            puts text
            puts "--------------------------------------------------------------"
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString.start_with?("url") then
            nhash = referenceString.split(":")[1]
            url = DarkMatter::getBlobOrNull(nhash)
            if url.nil? then
                puts "(error) I could not retrieve url for reference string: #{referenceString}"
                LucilleCore::pressEnterToContinue()
                return
            end
            puts "url: #{url}"
            CommonUtils::openUrlUsingSafari(url)
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString.start_with?("aion-point") then
            nhash = referenceString.split(":")[1]
            puts "CoreData, accessing aion point: #{nhash}"
            exportId = SecureRandom.hex(4)
            exportFoldername = "aion-point-#{exportId}"
            exportFolder = "#{Config::pathToDesktop()}/#{exportFoldername}"
            FileUtils.mkdir(exportFolder)
            AionCore::exportHashAtFolder(DarkMatterElizabeth.new(), nhash, exportFolder)
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString.start_with?("open-cycle") then
            fname = referenceString.split(":")[1]
            directoryFilepath = "#{Config::pathToGalaxy()}/OpenCycles/#{fname}"
            system("open '#{directoryFilepath}'")
            return
        end
        if referenceString.start_with?("unique-string") then
            uniquestring = referenceString.split(":")[1]
            puts "CoreData, accessing unique string: #{uniquestring}"
            location = Atlas::uniqueStringToLocationOrNull(uniquestring)
            if location then
                puts "location: #{location}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if referenceString.start_with?("Dx8UnitId") then
            unitId = referenceString.split(":")[1]
            Dx8Units::access(unitId)
            return
        end
        raise "CoreData, I do not know how to access '#{referenceString}'"
    end

    # CoreData::fsck(item)
    def self.fsck(item)
        uuid = item["uuid"]
        referenceString = item["field11"]
        puts "CoreData::fsck(#{JSON.pretty_generate(item)})"
        if referenceString.nil? then
            return
        end
        if referenceString == "null" then
            return
        end
        if referenceString.start_with?("text") then
            nhash = referenceString.split(":")[1]
            text = DarkMatter::getBlobOrNull(nhash)
            if text.nil? then
                raise "CoreData::fsck: could not extract text for uuid: #{uuid}, reference string: #{referenceString}"
            end
            return
        end
        if referenceString.start_with?("url") then
            nhash = referenceString.split(":")[1]
            url = DarkMatter::getBlobOrNull(nhash)
            if url.nil? then
                raise "CoreData::fsck: could not extract url for uuid: #{uuid}, reference string: #{referenceString}"
            end
            return
        end
        if referenceString.start_with?("aion-point") then
            nhash = referenceString.split(":")[1]
            AionFsck::structureCheckAionHashRaiseErrorIfAny(DarkMatterElizabeth.new(), nhash)
            return
        end
        if referenceString.start_with?("open-cycle") then
            return
        end
        if referenceString.start_with?("unique-string") then
            return
        end
        if referenceString.start_with?("Dx8UnitId") then
            return
        end
        raise "CoreData, I do not know how to access '#{referenceString}'"
    end
end
