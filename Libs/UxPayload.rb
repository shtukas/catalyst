
class UxPayload

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
            "stored-procedure",
            "unique-string",
            "Dx8Unit",
        ]
    end

    # UxPayload::interactivelySelectTypeOrNull()
    def self.interactivelySelectTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type", UxPayload::types())
    end

    # UxPayload::locationToPayload(uuid, location)
    def self.locationToPayload(uuid, location)
        nhash = AionCore::commitLocationReturnHash(Elizabeth.new(uuid), location)
        {
            "type" => "aion-point",
            "nhash" => nhash
        }
    end

    # UxPayload::makeNewOrNull(uuid)
    def self.makeNewOrNull(uuid)
        type = UxPayload::interactivelySelectTypeOrNull()
        return nil if type.nil?
        if type == "text" then
            return {
                "type" => "text",
                "text" => CommonUtils::editTextSynchronously("")
            }
        end
        if type == "todo-text-file-by-name-fragment" then
            name1 = LucilleCore::askQuestionAnswerAsString("name fragment (empty to abort): ")
            return nil if name1 == ""
            return {
                "type" => "todo-text-file-by-name-fragment",
                "name" => name1
            }
        end
        if type == "aion-point" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return UxPayload::locationToPayload(uuid, location)
        end
        if type == "Dx8Unit" then
            identifier = LucilleCore::askQuestionAnswerAsString("Dx8Unit identifier (empty to abort): ")
            return nil if identifier == ""
            return {
                "type" => "Dx8Unit",
                "id" => identifier
            }
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            return {
                "type" => "url",
                "url" => url
            }
        end
        if type == "unique-string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique-string (empty to abort): ")
            return nil if uniquestring == ""
            return {
                "type" => "unique-string",
                "uniquestring" => uniquestring
            }
        end
        if type == "sequence" then
            return {
                "type" => "sequence",
                "sequenceuuid" => SecureRandom.hex
            }
        end
        if type == "open cycle" then
            name1 = LucilleCore::askQuestionAnswerAsString("name (empty to abort): ")
            return nil if name1 == ""
            return {
                "type" => "open cycle",
                "name" => name1
            }
        end
        if type == "breakdown" then
            return UxPayload::interactivelyMakeBreakdown()
        end
        if type == "stored-procedure" then
            ticket = LucilleCore::askQuestionAnswerAsString("ticket (empty to abort): ")
            return nil if ticket == ""
            return {
                "type" => "stored-procedure",
                "ticket" => ticket
            }
        end
        raise "(error: 9dc106ff-44c6)"
    end

    # UxPayload::access(uuid, payload)
    def self.access(uuid, payload)
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
                payload = {
                    "type" => "text",
                    "text" => IO.read(filepath)
                }
                Items::setAttribute(uuid, "uxpayload-b4e4", payload)
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
            AionCore::exportHashAtFolder(Elizabeth.new(uuid), nhash, exportFolderpath)
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
            UxPayload::access(item["uuid"], item["uxpayload-b4e4"])
            return
        end
        raise "(error: e0040ec0-1c8f) type: #{payload["type"]}"
    end

    # UxPayload::edit(itemuuid, payload) -> nil or new payload
    def self.edit(itemuuid, payload)
        if payload["type"] == "text" then
            return {
                "type" => "text",
                "text" => CommonUtils::editTextSynchronously(payload["text"])
            }
        end
        if payload["type"] == "todo-text-file-by-name-fragment" then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["edit the text fragment itself", "access the text file"])
            return nil if option.nil?
            if option == "edit the text fragment itself" then
                name1 = LucilleCore::askQuestionAnswerAsString("name fragment (empty to abort): ")
                return nil if name1 == ""
                return {
                    "type" => "todo-text-file-by-name-fragment",
                    "name" => name1
                }
            end
            if option == "access the text file" then
                UxPayload::access(uuid, payload)
                return nil
            end
            raise "(error: f1ee6b3d)"
        end
        if payload["type"] == "aion-point" then
            UxPayload::access(itemuuid, payload)
            LucilleCore::pressEnterToContinue()
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return UxPayload::locationToPayload(itemuuid, location)
        end
        if payload["type"] == "Dx8Unit" then
            puts "You can't edit a Dx8Unit"
            LucilleCore::pressEnterToContinue()
            return nil
        end
        if payload["type"] == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            return {
                "type" => "url",
                "url" => url
            }
        end
        if payload["type"] == "unique-string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique-string (empty to abort): ")
            return nil if uniquestring == ""
            return {
                "type" => "unique-string",
                "uniquestring" => uniquestring
            }
        end
        if payload["type"] == "open cycle" then
            name1 = LucilleCore::askQuestionAnswerAsString("open cycle directory name (empty to abort): ")
            return nil if name1 == ""
            return {
                "type" => "open cycle",
                "name" => name1
            }
        end
        if payload["type"] == "breakdown" then
            return {
                "type"  => "breakdown",
                "lines" => Operations::interactivelyRecompileLines(payload["lines"])
            }
        end
        if payload["type"] == "stored-procedure" then
            ticket = LucilleCore::askQuestionAnswerAsString("ticket (empty to abort): ")
            return nil if ticket == ""
            return {
                "type" => "stored-procedure",
                "ticket" => ticket
            }
        end
        raise "(error: 9dc106ff-44c6)"
    end

    # UxPayload::fsck(uuid, payload)
    def self.fsck(uuid, payload)
        return if payload.nil?
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
            AionFsck::structureCheckAionHashRaiseErrorIfAny(Elizabeth.new(uuid), nhash)
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
        if payload["type"] == "stored-procedure" then
            return
        end
        raise "unkown payload type: #{payload["type"]} at #{payload}"
    end

    # UxPayload::interactivelyMakeBreakdown()
    def self.interactivelyMakeBreakdown()
        {
            "type"  => "breakdown",
            "lines" => Operations::interactivelyGetLinesUsingTextEditor()
        }
    end

    # UxPayload::payloadProgram(item)
    def self.payloadProgram(item)
        if UxPayload::isNonEmptySequence(item) then
            puts "You cannot payload program a sequence carrier that is not empty"
            LucilleCore::pressEnterToContinue()
            return
        end

        payload = nil
        if item["uxpayload-b4e4"] then
            options = ["access", "edit", "make new (default)", "delete existing payload"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            if option == "access" then
                payload = UxPayload::access(item["uuid"], item["uxpayload-b4e4"])
            end
            if option == "edit" then
                payload = UxPayload::edit(item["uuid"], item["uxpayload-b4e4"])
            end
            if option.nil? or option == "make new (default)" then
                payload = UxPayload::makeNewOrNull(item["uuid"])
            end
            if option == "delete existing payload" then
                Items::setAttribute(item["uuid"], "uxpayload-b4e4", nil)
            end
        else
            payload = UxPayload::makeNewOrNull(item["uuid"])
        end
        return if payload.nil?
        Items::setAttribute(item["uuid"], "uxpayload-b4e4", payload)
    end

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
        payload = item["uxpayload-b4e4"]
        return "" if payload.nil?
        " #{UxPayload::toString(payload)}".green
    end

    # UxPayload::itemIsSequenceCarrier(item)
    def self.itemIsSequenceCarrier(item)
        item["uxpayload-b4e4"] and item["uxpayload-b4e4"]["type"] == "sequence"
    end

    # UxPayload::isNonEmptySequence(item)
    def self.isNonEmptySequence(item)
        UxPayload::itemIsSequenceCarrier(item) and Sequences::sequenceSize(item["uxpayload-b4e4"]["sequenceuuid"]) > 0
    end
end
