
class UxPayload

    # UxPayload::types()
    def self.types()
        [
            "text",
            "url",
            "breakdown",
            "aion-point",
            "Dx8Unit",
            "todo-text-file-by-name",
            "open cycle",
            "unique-string"
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
        if type == "todo-text-file-by-name" then
            name1 = LucilleCore::askQuestionAnswerAsString("name fragment (empty to abort): ")
            return nil if name1 == ""
            return {
                "type" => "todo-text-file-by-name",
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
        raise "(error: 9dc106ff-44c6)"
    end

    # UxPayload::access(uuid, payload)
    def self.access(uuid, payload)
        return if payload.nil?
        if payload["type"] == "text" then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["in terminal", "in file"])
            return if option.nil?
            if option == "in terminal" then
                puts payload["text"].strip
                LucilleCore::pressEnterToContinue()
            end
            if option == "in file" then
                filepath = "#{ENV['HOME']}/x-space/xcache-v1-days/#{Time.new.to_s[0, 10]}/#{SecureRandom.hex(5)}.txt"
                File.open(filepath, "w"){|f| f.puts(payload["text"]) }
                system("open '#{filepath}'")
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if payload["type"] == "todo-text-file-by-name" then
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
            CommonUtils::openUrlUsingSafari(url)
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
            puts "focus: #{payload["lines"].first.green}"
            LucilleCore::pressEnterToContinue()
            return
        end
    end

    # UxPayload::edit(itemuuid, payload)
    def self.edit(itemuuid, payload)
        if payload["type"] == "text" then
            return {
                "type" => "text",
                "text" => CommonUtils::editTextSynchronously(payload["text"])
            }
        end
        if payload["type"] == "todo-text-file-by-name" then
            name1 = LucilleCore::askQuestionAnswerAsString("name fragment (empty to abort): ")
            return nil if name1 == ""
            return {
                "type" => "todo-text-file-by-name",
                "name" => name1
            }
        end
        if payload["type"] == "aion-point" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            if location.nil? then
                puts "There was no location chosen, the payload is going to be erased"
                if LucilleCore::askQuestionAnswerAsBoolean("confirm: ", yes) then
                    return nil
                else
                    return payload
                end
            end
            return UxPayload::locationToPayload(uuid, location)
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
        if payload["type"] == "todo-text-file-by-name" then
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
        raise "unkown payload type: #{payload["type"]} at #{payload}"
    end

    # UxPayload::suffix_string(item)
    def self.suffix_string(item)
        payload = item["uxpayload-b4e4"]
        return "" if payload.nil?
        " (#{payload["type"]})".green
    end

    # UxPayload::interactivelyMakeBreakdown()
    def self.interactivelyMakeBreakdown()
        {
            "type"  => "breakdown",
            "lines" => Operations::interactivelyGetLines()
        }
    end

    # UxPayload::payloadProgram(item)
    def self.payloadProgram(item)
        payload = nil
        if item["uxpayload-b4e4"] then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["update existing", "make new (default)"])
            if option.nil? or option == "make new (default)" then
                payload = UxPayload::makeNewOrNull(item["uuid"])
            end
            if option.nil? or option == "update existing" then
                payload = UxPayload::edit(item["uuid"], item["uxpayload-b4e4"])
            end
        else
            payload = UxPayload::makeNewOrNull(item["uuid"])
        end
        return if payload.nil?
        Items::setAttribute(item["uuid"], "uxpayload-b4e4", payload)
        ListingService::listOrRelist(item["uuid"])
    end
end
