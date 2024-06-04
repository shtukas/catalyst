
class UxPayload

    # UxPayload::types()
    def self.types()
        [
            "text",
            "todo-text-file-by-name",
            "aion-point",
            "Dx8Unit",
            "url",
            "unique-string"
        ]
    end

    # UxPayload::interactivelySelectTypeOrNull()
    def self.interactivelySelectTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type", UxPayload::types())
    end

    # UxPayload::makeNewOrNull()
    def self.makeNewOrNull()
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
            nhash = AionCore::commitLocationReturnHash(Elizabeth.new(), location)
            return {
                "type" => "aion-point",
                "nhash" => nhash
            }
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
    end

    # UxPayload::access(itemuuid, payload)
    def self.access(itemuuid, payload)
        return if payload.nil?
        if payload["type"] == "text" then
            puts payload["text"].strip
            LucilleCore::pressEnterToContinue()
            return
        end
        if payload["type"] == "todo-text-file-by-name" then
            name1 = payload["name"]
            location = Catalyst::selectTodoTextFileLocationOrNull(name1)
            if location.nil? then
                puts "Could not resolve this todo text file: #{name1}"
                if LucilleCore::askQuestionAnswerAsBoolean("reset payload ?") then
                    Cubes1::setAttribute(itemuuid, "uxpayload-b4e4", nil)
                end
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
            if LucilleCore::askQuestionAnswerAsBoolean("destroy Dx8Unit '#{unitId}'") then
                Dx8Units::destroy(unitId)
                Cubes1::setAttribute(item["uuid"], "uxpayload-b4e4", nil)
            end
            return
        end
        if payload["type"] == "url" then
            url = payload["url"]
            CommonUtils::openUrlUsingSafari(url)
            LucilleCore::pressEnterToContinue()
            return
        end
        if payload["type"] == "unique-string" then
            uniquestring = payload["uniquestring"]
            puts "accessing unique string: #{uniquestring}"
            location = Atlas::uniqueStringToLocationOrNull(uniquestring)
            if location then
                puts "location: #{location}"
                LucilleCore::pressEnterToContinue()
            else
                puts "could not locate: #{location}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
    end

    # UxPayload::edit(itemuuid, payload)
    def self.edit(itemuuid, payload)
        return if payload.nil?
        puts "Edit of a UxPayload has not been implemented yet"
        LucilleCore::pressEnterToContinue()
    end

    # UxPayload::fsck(payload)
    def self.fsck(payload)
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
        raise "unkown payload type: #{payload["type"]} at #{payload}"
    end

    # UxPayload::suffix_string(item)
    def self.suffix_string(item)
        payload = item["uxpayload-b4e4"]
        return "" if payload.nil?
        " (#{payload["type"]})".green
    end
end
