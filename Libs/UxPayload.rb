
class UxPayload

    # ---------------------------------------
    # Types

    # UxPayload::types()
    def self.types()
        [
            "text",
            "url",
            "breakdown",
            "aion-point",
            "sequence",
            "todo-text-file-by-name-fragment",
            "open cycle",
            "unique-string",
            "Dx8Unit",
        ]
    end

    # ---------------------------------------
    # Makers

    # UxPayload::interactivelySelectTypeOrNull()
    def self.interactivelySelectTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type", UxPayload::types())
    end

    # UxPayload::interactivelyMakeBreakdownPayload()
    def self.interactivelyMakeBreakdownPayload()
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "UxPayload",
            "type"     => "breakdown",
            "lines"    => Operations::interactivelyGetLinesUsingTextEditor()
        }
    end

    # UxPayload::locationToPayload(location)
    def self.locationToPayload(location)
        nhash = AionCore::commitLocationReturnHash(Elizabeth.new(), location)
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "UxPayload",
            "type"     => "aion-point",
            "nhash"    => nhash
        }
    end

    # UxPayload::makeNewPayloadOrNull()
    def self.makeNewPayloadOrNull()
        type = UxPayload::interactivelySelectTypeOrNull()
        return nil if type.nil?
        if type == "text" then
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "UxPayload",
                "type"     => "text",
                "text"     => CommonUtils::editTextSynchronously("")
            }
        end
        if type == "todo-text-file-by-name-fragment" then
            name1 = LucilleCore::askQuestionAnswerAsString("name fragment (empty to abort): ")
            return nil if name1 == ""
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "UxPayload",
                "type"     => "todo-text-file-by-name-fragment",
                "name"     => name1
            }
        end
        if type == "aion-point" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return UxPayload::locationToPayload(location)
        end
        if type == "Dx8Unit" then
            identifier = LucilleCore::askQuestionAnswerAsString("Dx8Unit identifier (empty to abort): ")
            return nil if identifier == ""
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "UxPayload",
                "type"     => "Dx8Unit",
                "id"       => identifier
            }
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "UxPayload",
                "type"     => "url",
                "url"      => url
            }
        end
        if type == "unique-string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique-string (empty to abort): ")
            return nil if uniquestring == ""
            return {
                "uuid"         => SecureRandom.uuid,
                "mikuType"     => "UxPayload",
                "type"         => "unique-string",
                "uniquestring" => uniquestring
            }
        end
        if type == "sequence" then
            return {
                "uuid"         => SecureRandom.uuid,
                "mikuType"     => "UxPayload",
                "type"         => "sequence",
                "sequenceuuid" => SecureRandom.hex
            }
        end
        if type == "open cycle" then
            name1 = LucilleCore::askQuestionAnswerAsString("name (empty to abort): ")
            return nil if name1 == ""
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "UxPayload",
                "type"     => "open cycle",
                "name"     => name1
            }
        end
        if type == "breakdown" then
            return UxPayload::interactivelyMakeBreakdownPayload()
        end
        raise "(error: 9dc106ff-44c6)"
    end

    # UxPayload::interactivelyIssueNewGetReferenceOrNull() # issues the new payload and return a uuid
    def self.interactivelyIssueNewGetReferenceOrNull()
        payload = UxPayload::makeNewPayloadOrNull()
        return nil if payload.nil?
        Items::commitObject(payload)
        payload["uuid"]
    end

    # UxPayload::issueNewSequenceGetReference() # issues the new sequence and return a uuid
    def self.issueNewSequenceGetReference()
        payload = {
            "uuid"         => SecureRandom.uuid,
            "mikuType"     => "UxPayload",
            "type"         => "sequence",
            "sequenceuuid" => SecureRandom.hex
        }
        Items::commitObject(payload)
        payload["uuid"]
    end

    # ---------------------------------------
    # Data

    # UxPayload::toString(payload)
    def self.toString(payload)
        return "" if payload.nil?
        if payload["type"] == "sequence" then
            item = Sequences::firstItemInSequenceOrNull(payload["sequenceuuid"])
            return "(sequence: empty)" if item.nil?
            return "(sequence: next: #{item["description"]})"
        end
        "(#{payload["type"]})"
    end

    # UxPayload::suffixString(item)
    def self.suffixString(item)
        return "" if item["payload-uuid-1141"].nil?
        payload = Items::itemOrNull(item["payload-uuid-1141"])
        return "" if payload.nil?
        " #{UxPayload::toString(payload)}".green
    end

    # UxPayload::itemToPayloadOrNull(item)
    def self.itemToPayloadOrNull(item)
        return nil if item["payload-uuid-1141"].nil?
        Items::itemOrNull(item["payload-uuid-1141"])
    end

    # ---------------------------------------
    # Operation

    # UxPayload::access(payload)
    def self.access(payload)
        return if payload.nil?
        if payload["type"] == "text" then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["in terminal", "in file (also does edit)"])
            return if option.nil?
            if option == "in terminal" then
                puts payload["text"].strip
                LucilleCore::pressEnterToContinue()
            end
            if option == "in file (also does edit)" then
                filepath = "#{ENV['HOME']}/x-space/xcache-v1-days/#{Time.new.to_s[0, 10]}/#{SecureRandom.hex(5)}.txt"
                File.open(filepath, "w"){|f| f.puts(payload["text"]) }
                system("open '#{filepath}'")
                LucilleCore::pressEnterToContinue()
                payload["text"] = IO.read(filepath)
                Items::commitObject(payload)
            end
            return
        end
        if payload["type"] == "todo-text-file-by-name-fragment" then
            name1 = payload["name"]
            location = CommonUtils::locateGalaxyFileByNameFragment(name1)
            if location.nil? then
                puts "Could not resolve this todo text file: #{name1}"
                LucilleCore::pressEnterToContinue()
                return
            end
            puts "found: #{location}"
            system("open '#{location}'")
            LucilleCore::pressEnterToContinue()
            return
        end
        if payload["type"] == "aion-point" then
            nhash = payload["nhash"]
            puts "accessing aion point: #{nhash}"
            exportId = SecureRandom.hex(4)
            exportFoldername = "#{exportId}-aion-point"
            exportFolderpath = "#{ENV['HOME']}/x-space/xcache-v1-days/#{Time.new.to_s[0, 10]}/#{exportFoldername}"
            FileUtils.mkpath(exportFolderpath)
            AionCore::exportHashAtFolder(Elizabeth.new(), nhash, exportFolderpath)
            system("open '#{exportFolderpath}'")
            LucilleCore::pressEnterToContinue()
            return
        end
        if payload["type"] == "Dx8Unit" then
            unitId = payload["id"]
            Dx8Units::access(unitId)
            LucilleCore::pressEnterToContinue()
            return
        end
        if payload["type"] == "url" then
            url = payload["url"]
            puts "url: #{url}"
            CommonUtils::openUrlUsingChrome(url)
            LucilleCore::pressEnterToContinue()
            return
        end
        if payload["type"] == "unique-string" then
            uniquestring = payload["uniquestring"]
            puts "accessing unique string: #{uniquestring}"
            location = Atlas::uniqueStringToLocationOrNull(uniquestring)
            if location then
                if File.file?(location) then
                    puts "location: #{location}"
                    LucilleCore::pressEnterToContinue()
                else
                    puts "opening directory: #{location}"
                    system("open '#{location}'")
                    LucilleCore::pressEnterToContinue()
                end
            else
                puts "could not locate: #{location}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if payload["type"] == "open cycle" then
            name1 = payload["name"]
            puts "accessing open cycle: #{name1}"
            location = Atlas::uniqueStringToLocationOrNull(name1)
            if location then
                puts "opening directory: #{location}"
                system("open '#{location}'")
                LucilleCore::pressEnterToContinue()
            else
                puts "could not locate: #{location}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if payload["type"] == "breakdown" then
            return if payload["lines"].empty?
            puts payload["lines"]
            LucilleCore::pressEnterToContinue()
            return
        end
        if payload["type"] == "sequence" then
            item = Sequences::firstItemInSequenceOrNull(payload["sequenceuuid"])
            return if item.nil?
            UxPayload::access(UxPayload::itemToPayloadOrNull(item))
            return
        end
        raise "(error: e0040ec0-1c8f) type: #{payload["type"]}"
    end

    # UxPayload::edit(payload)
    def self.edit(payload)
        return if payload.nil?
        if payload["type"] == "text" then
            payload["text"] = CommonUtils::editTextSynchronously(payload["text"])
            Items::commitObject(payload)
            return
        end
        if payload["type"] == "todo-text-file-by-name-fragment" then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["edit the name fragment itself", "access the text file"])
            return nil if option.nil?
            if option == "edit the name fragment itself" then
                name1 = LucilleCore::askQuestionAnswerAsString("name fragment (empty to abort): ")
                return nil if name1 == ""
                payload["name"] = name1
                Items::commitObject(payload)
                return
            end
            if option == "access the text file" then
                Items::commitObject(payload)
                return
            end
            raise "(error: f1ee6b3d)"
        end
        if payload["type"] == "aion-point" then
            UxPayload::access(payload)
            LucilleCore::pressEnterToContinue()
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            Items::commitObject(payload)
            return
        end
        if payload["type"] == "Dx8Unit" then
            puts "You can't edit a Dx8Unit"
            LucilleCore::pressEnterToContinue()
            return nil
        end
        if payload["type"] == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            payload["url"] = url
            Items::commitObject(payload)
            return
        end
        if payload["type"] == "unique-string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique-string (empty to abort): ")
            return nil if uniquestring == ""
            payload["uniquestring"] = uniquestring
            Items::commitObject(payload)
            return
        end
        if payload["type"] == "open cycle" then
            name1 = LucilleCore::askQuestionAnswerAsString("open cycle directory name (empty to abort): ")
            return nil if name1 == ""
            payload["name"] = name1
            Items::commitObject(payload)
            return
        end
        if payload["type"] == "breakdown" then
            payload["lines"] = Operations::interactivelyRecompileLines(payload["lines"])
            Items::commitObject(payload)
            return
        end
        raise "(error: 9dc106ff-44c6)"
    end

    # UxPayload::fsck(payload)
    def self.fsck(payload)
        return if payload.nil?
        if payload["uuid"].nil? then
            raise "could not find `uuid` attribute for payload #{payload}"
        end
        if payload["mikuType"].nil? then
            raise "could not find `mikuType` attribute for payload #{payload}"
        end
        if payload["type"] == "text" then
            if payload["text"].nil? then
                raise "could not find `text` attribute for payload #{payload}"
            end
            return
        end
        if payload["type"] == "todo-text-file-by-name-fragment" then
            if payload["name"].nil? then
                raise "could not find `name` attribute for payload #{payload}"
            end
            return
        end
        if payload["type"] == "aion-point" then
            nhash = payload["nhash"]
            AionFsck::structureCheckAionHashRaiseErrorIfAny(Elizabeth.new(), nhash)
            return
        end
        if payload["type"] == "Dx8Unit" then
            if payload["id"].nil? then
                raise "could not find `id` attribute for payload #{payload}"
            end
            return
        end
        if payload["type"] == "url" then
            if payload["url"].nil? then
                raise "could not find `url` attribute for payload #{payload}"
            end
            return
        end
        if payload["type"] == "unique-string" then
            if payload["uniquestring"].nil? then
                raise "could not find `uniquestring` attribute for payload #{payload}"
            end
            return
        end
        if payload["type"] == "open cycle" then
            return
        end
        if payload["type"] == "breakdown" then
            return
        end
        if payload["type"] == "sequence" then
            return
        end
        raise "unkown payload type: #{payload["type"]} at #{payload}"
    end

    # UxPayload::payloadProgram(item)
    def self.payloadProgram(item)
        if Sequences::isNonEmptySequence(item) then
            puts "You cannot payload program a sequence carrier that is not empty"
            LucilleCore::pressEnterToContinue()
            return
        end
        payload = UxPayload::itemToPayloadOrNull(item)
        if payload.nil? then
            Items::setAttribute(item["uuid"], "payload-uuid-1141", UxPayload::interactivelyIssueNewGetReferenceOrNull())
            return
        end
        options = ["access", "edit", "make new (default)", "delete existing payload"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        if option == "access" then
            UxPayload::access(payload)
        end
        if option == "edit" then
            UxPayload::edit(payload)
        end
        if option.nil? or option == "make new (default)" then
            Items::setAttribute(item["uuid"], "payload-uuid-1141", UxPayload::interactivelyIssueNewGetReferenceOrNull())
        end
        if option == "delete existing payload" then
            Items::setAttribute(item["uuid"], "payload-uuid-1141", nil)
        end
    end
end
