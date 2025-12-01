
class UxPayloads

    # ---------------------------------------
    # Types

    # UxPayloads::types()
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

    # UxPayloads::interactivelySelectTypeOrNull()
    def self.interactivelySelectTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type", UxPayloads::types())
    end

    # UxPayloads::interactivelyMakeBreakdownPayload()
    def self.interactivelyMakeBreakdownPayload()
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "Breakdown",
            "lines"    => Operations::interactivelyGetLinesUsingTextEditor()
        }
    end

    # UxPayloads::locationToPayload(location)
    def self.locationToPayload(location)
        nhash = AionCore::commitLocationReturnHash(Elizabeth.new(), location)
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "AionPoint",
            "nhash"    => nhash
        }
    end

    # UxPayloads::makeNewPayloadOrNull()
    def self.makeNewPayloadOrNull()
        type = UxPayloads::interactivelySelectTypeOrNull()
        return nil if type.nil?
        if type == "text" then
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "Text",
                "text"     => CommonUtils::editTextSynchronously("")
            }
        end
        if type == "todo-text-file-by-name-fragment" then
            name1 = LucilleCore::askQuestionAnswerAsString("name fragment (empty to abort): ")
            return nil if name1 == ""
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "TodoTextFileByNameFragment",
                "name"     => name1
            }
        end
        if type == "aion-point" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return UxPayloads::locationToPayload(location)
        end
        if type == "Dx8Unit" then
            identifier = LucilleCore::askQuestionAnswerAsString("Dx8Unit identifier (empty to abort): ")
            return nil if identifier == ""
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "Dx8Unit",
                "id"       => identifier
            }
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "URL",
                "url"      => url
            }
        end
        if type == "unique-string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique-string (empty to abort): ")
            return nil if uniquestring == ""
            return {
                "uuid"         => SecureRandom.uuid,
                "mikuType"     => "UniqueString",
                "uniquestring" => uniquestring
            }
        end
        if type == "sequence" then
            return {
                "uuid"         => SecureRandom.uuid,
                "mikuType"     => "Sequence",
                "sequenceuuid" => SecureRandom.hex
            }
        end
        if type == "open cycle" then
            name1 = LucilleCore::askQuestionAnswerAsString("name (empty to abort): ")
            return nil if name1 == ""
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "OpenCycle",
                "name"     => name1
            }
        end
        if type == "breakdown" then
            return UxPayloads::interactivelyMakeBreakdownPayload()
        end
        raise "(error: 9dc106ff-44c6)"
    end

    # UxPayloads::interactivelyIssueNewGetReferenceOrNull() # issues the new payload and return a uuid
    def self.interactivelyIssueNewGetReferenceOrNull()
        payload = UxPayloads::makeNewPayloadOrNull()
        return nil if payload.nil?
        Items::commitObject(payload)
        payload["uuid"]
    end

    # UxPayloads::issueNewSequenceGetReference() # issues the new sequence and return a uuid
    def self.issueNewSequenceGetReference()
        payload = {
            "uuid"         => SecureRandom.uuid,
            "mikuType"     => "Sequence",
            "sequenceuuid" => SecureRandom.hex
        }
        Items::commitObject(payload)
        payload["uuid"]
    end

    # ---------------------------------------
    # Data

    # UxPayloads::toString(payload)
    def self.toString(payload)
        return "" if payload.nil?
        if payload["mikuType"] == "Sequence" then
            item = Cx18s::firstItem(payload["sequenceuuid"])
            return "(sequence: empty)" if item.nil?
            return "(sequence: next: #{item["description"]})"
        end
        if payload["mikuType"] == "URL" then
            return "(url)"
        end
        if payload["mikuType"] == "AionPoint" then
            return "(aion-point)"
        end
        if payload["mikuType"] == "Breakdown" then
            return "(breakdown)"
        end
        if payload["mikuType"] == "Dx8Unit" then
            return "(Dx8Unit)"
        end
        if payload["mikuType"] == "OpenCycle" then
            return "(open-cycle)"
        end
        if payload["mikuType"] == "Text" then
            return "(text)"
        end
        if payload["mikuType"] == "UniqueString" then
            return "(unique-string)"
        end
        if payload["mikuType"] == "TodoTextFileByNameFragment" then
            return "(todo-file-by-name-fragment)"
        end
    end

    # UxPayloads::suffixString(item)
    def self.suffixString(item)
        return "" if item["payload-uuid-1141"].nil?
        payload = Items::objectOrNull(item["payload-uuid-1141"])
        return "" if payload.nil?
        " #{UxPayloads::toString(payload)}".green
    end

    # UxPayloads::itemToPayloadOrNull(item)
    def self.itemToPayloadOrNull(item)
        return nil if item["payload-uuid-1141"].nil?
        Items::objectOrNull(item["payload-uuid-1141"])
    end

    # ---------------------------------------
    # Operation

    # UxPayloads::access(payload)
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
            item = Cx18s::firstItem(payload["sequenceuuid"])
            return if item.nil?
            UxPayloads::access(UxPayloads::itemToPayloadOrNull(item))
            return
        end
        raise "(error: e0040ec0-1c8f) type: #{payload["type"]}"
    end

    # UxPayloads::edit(payload)
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
            UxPayloads::access(payload)
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

    # UxPayloads::fsck(payload)
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

    # UxPayloads::payloadProgram(item)
    def self.payloadProgram(item)
        if Sequences::isNonEmptySequence(item) then
            puts "You cannot payload program a sequence carrier that is not empty"
            LucilleCore::pressEnterToContinue()
            return
        end
        payload = UxPayloads::itemToPayloadOrNull(item)
        if payload.nil? then
            Items::setAttribute(item["uuid"], "payload-uuid-1141", UxPayloads::interactivelyIssueNewGetReferenceOrNull())
            return
        end
        options = ["access", "edit", "make new (default)", "delete existing payload"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        if option == "access" then
            UxPayloads::access(payload)
        end
        if option == "edit" then
            UxPayloads::edit(payload)
        end
        if option.nil? or option == "make new (default)" then
            Items::setAttribute(item["uuid"], "payload-uuid-1141", UxPayloads::interactivelyIssueNewGetReferenceOrNull())
        end
        if option == "delete existing payload" then
            Items::setAttribute(item["uuid"], "payload-uuid-1141", nil)
        end
    end
end
