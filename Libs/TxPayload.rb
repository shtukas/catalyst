

class TxPayload

    # TxPayload::mapping()
    def self.mapping()
        {
            "note-1531"          => "text of a note",
            "todotextfile-1312"  => "name or name fragment of a text file",
            "cfsr-20231213"      => "file system reference (see FileSystemReferences)",
            "aion-point-7c758c"  => "aion point root hash",
            "dx8UnitId-00286e29" => "Dx8UnitId reference",
            "url-e88a"           => "URL",
            "unique-string-c3e5" => "string",
        }
    end

    # TxPayload::keysToFriendly(key)
    def self.keysToFriendly(key)
        TxPayload::mapping()[key]
    end

    # TxPayload::keysToShort(key)
    def self.keysToShort(key)
        ({
            "note-1531"          => "(note)",
            "todotextfile-1312"  => "(named textfile)",
            "cfsr-20231213"      => "(file system ref)",
            "aion-point-7c758c"  => "(aion point)",
            "dx8UnitId-00286e29" => "(Dx8Unit)",
            "url-e88a"           => "(url)",
            "unique-string-c3e5" => "(unique-string)",
        })[key]
    end

    # TxPayload::friendlyToKey(friendly)
    def self.friendlyToKey(friendly)
        TxPayload::mapping().each{|key, value|
            if value == friendly then
                return key
            end
        }
    end

    # TxPayload::interactivelyMakeNew(uuid)
    def self.interactivelyMakeNew(uuid)
        payload = {}
        options = TxPayload::mapping().keys.map{|key| TxPayload::keysToFriendly(key) } + ["new open cycle"]
        loop {
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            return payload if option.nil?
            if TxPayload::friendlyToKey(option) == "note-1531" then
                note = payload["note-1531"] || ""
                note = CommonUtils::editTextSynchronously(note).strip
                note = note.size > 0 ? note : nil
                payload["note-1531"] = note
                next
            end
            if TxPayload::friendlyToKey(option) == "todotextfile-1312" then
                todotextfile = LucilleCore::askQuestionAnswerAsString("name or fragment: ")
                if todotextfile != "" then
                    payload["todotextfile-1312"] = todotextfile
                end
                next
            end
            if TxPayload::friendlyToKey(option) == "cfsr-20231213" then
                reference = FileSystemReferences::interactivelyIssueFileSystemReferenceOrNull()
                if reference then
                    payload["cfsr-20231213"] = reference
                end
                next
            end
            if TxPayload::friendlyToKey(option) == "aion-point-7c758c" then
                location = CommonUtils::interactivelySelectDesktopLocationOrNull()
                next if location.nil?
                nhash = AionCore::commitLocationReturnHash(Elizabeth.new(item["uuid"]), location)
                payload["aion-point-7c758c"] = nhash
                next
            end
            if TxPayload::friendlyToKey(option) == "dx8UnitId-00286e29" then
                unitId = LucilleCore::askQuestionAnswerAsString("Dx8Unit Id: ")
                next if unitId == ""
                payload["dx8UnitId-00286e29"] = unitId
                next
            end
            if TxPayload::friendlyToKey(option) == "url-e88a" then
                url = LucilleCore::askQuestionAnswerAsString("url: ")
                next if url == ""
                payload["url-e88a"] = url
                next
            end
            if TxPayload::friendlyToKey(option) == "unique-string-c3e5" then
                uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (if needed use Nx01-#{SecureRandom.hex[0, 12]}): ")
                payload["unique-string-c3e5"] = uniquestring
                next
            end
            if option == "new open cycle" then
                description = LucilleCore::askQuestionAnswerAsString("description without date: ")
                next if description == ""
                foldername = "#{CommonUtils::today()} #{description}"
                folderpath = "#{Config::pathToGalaxy()}/OpenCycles/#{foldername}"
                FileUtils.mkdir(folderpath)
                reference = SecureRandom.hex
                FileSystemReferences::issueCfsrFileAtDirectory(folderpath, reference)
                payload["cfsr-20231213"] = reference
                next
            end
        }
    end

    # TxPayload::suffix_string(item)
    def self.suffix_string(item)
        str = TxPayload::mapping()
                .keys
                .map{|key| item[key] ? TxPayload::keysToShort(key) : nil }
                .compact
                .join(' ').green
        return "" if str == ""
        " #{str}".green
    end

    # TxPayload::itemHasPayload(item)
    def self.itemHasPayload(item)
        TxPayload::mapping().keys.map{|key| item[key] }.compact.size > 0
    end

    # TxPayload::access(item)
    def self.access(item)
        loop {
            puts "payload:#{TxPayload::suffix_string(item)}".green
            options = TxPayload::mapping().keys.map{|key| item[key] ? key : nil }.compact
            return if options.size == 0
            if options.size == 1 then
                option = options.first
            else
                option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
                return if option.nil?
            end
            if option == "note-1531" then
                note = item["note-1531"] || ""
                note = CommonUtils::editTextSynchronously(note).strip
                note = note.size > 0 ? note : nil
                item["note-1531"] = note
                Cubes2::setAttribute(item["uuid"], "note-1531", note)
            end
            if option == "todotextfile-1312" then
                todotextfile = item["todotextfile-1312"]
                location = Catalyst::selectTodoTextFileLocationOrNull(todotextfile)
                if location.nil? then
                    puts "Could not resolve this todotextfile: #{todotextfile}"
                    if LucilleCore::askQuestionAnswerAsBoolean("remove reference from item ?") then
                        Cubes2::setAttribute(item["uuid"], "todotextfile-1312", nil)
                    end
                    next
                end
                puts "found: #{location}"
                system("open '#{location}'")
            end
            if option == "cfsr-20231213" then
                reference = item["cfsr-20231213"]
                FileSystemReferences::accessReference(reference)
            end
            if option == "aion-point-7c758c" then
                nhash = item["aion-point-7c758c"]
                puts "accessing aion point: #{nhash}"
                exportId = SecureRandom.hex(4)
                exportFoldername = "aion-point-#{exportId}"
                exportFolder = "#{ENV['HOME']}/x-space/xcache-v1-days/#{Time.new.to_s[0, 10]}/#{exportFoldername}"
                FileUtils.mkpath(exportFolder)
                AionCore::exportHashAtFolder(Elizabeth.new(item["uuid"]), nhash, exportFolder)
                system("open '#{exportFolder}'")
                LucilleCore::pressEnterToContinue()
            end
            if option == "dx8UnitId-00286e29" then
                unitId = item["dx8UnitId-00286e29"]
                Dx8Units::access(unitId)
            end
            if option == "url-e88a" then
                url = item["url-e88a"]
                CommonUtils::openUrlUsingSafari(url)
                LucilleCore::pressEnterToContinue()
            end
            if option == "unique-string-c3e5" then
                uniquestring = item["unique-string-c3e5"]
                puts "accessing unique string: #{uniquestring}"
                location = Atlas::uniqueStringToLocationOrNull(uniquestring)
                if location then
                    puts "location: #{location}"
                    LucilleCore::pressEnterToContinue()
                end
            end
            if options.size == 1 then
                break
            end
        }
    end

    # TxPayload::edit(item)
    def self.edit(item)
        options = TxPayload::mapping().keys.map{|key| TxPayload::keysToFriendly(key) } + ["new open cycle"]
        loop {
            puts "payload:#{TxPayload::suffix_string(item)}".green
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            return if option.nil?
            if TxPayload::friendlyToKey(option) == "note-1531" then
                note = item["note-1531"] || ""
                note = CommonUtils::editTextSynchronously(note).strip
                note = note.size > 0 ? note : nil
                item["note-1531"] = note
                Cubes2::setAttribute(item["uuid"], "note-1531", note)
            end
            if TxPayload::friendlyToKey(option) == "todotextfile-1312" then
                todotextfile = LucilleCore::askQuestionAnswerAsString("name or fragment: ")
                if todotextfile != "" then
                    item["todotextfile-1312"] = todotextfile
                    Cubes2::setAttribute(item["uuid"], "todotextfile-1312", todotextfile)
                end
            end
            if TxPayload::friendlyToKey(option) == "cfsr-20231213" then
                reference = FileSystemReferences::interactivelyIssueFileSystemReferenceOrNull()
                if reference then
                    item["cfsr-20231213"] = reference
                    Cubes2::setAttribute(item["uuid"], "cfsr-20231213", reference)
                end
            end
            if TxPayload::friendlyToKey(option) == "aion-point-7c758c" then
                location = CommonUtils::interactivelySelectDesktopLocationOrNull()
                next if location.nil?
                nhash = AionCore::commitLocationReturnHash(Elizabeth.new(item["uuid"]), location)
                Cubes2::setAttribute(item["uuid"], "aion-point-7c758c", nhash)
            end
            if TxPayload::friendlyToKey(option) == "dx8UnitId-00286e29" then
                unitId = LucilleCore::askQuestionAnswerAsString("Dx8Unit Id: ")
                next if unitId == ""
                Cubes2::setAttribute(item["uuid"], "dx8UnitId-00286e29", unitId)
            end
            if TxPayload::friendlyToKey(option) == "url-e88a" then
                url = LucilleCore::askQuestionAnswerAsString("url: ")
                next if url == ""
                Cubes2::setAttribute(item["uuid"], "url-e88a", url)
            end
            if TxPayload::friendlyToKey(option) == "unique-string-c3e5" then
                uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (if needed use Nx01-#{SecureRandom.hex[0, 12]}): ")
                Cubes2::setAttribute(item["uuid"], "unique-string-c3e5", uniquestring)
            end
            if option == "new open cycle" then
                description = LucilleCore::askQuestionAnswerAsString("description without date: ")
                next if description == ""
                foldername = "#{CommonUtils::today()} #{description}"
                folderpath = "#{Config::pathToGalaxy()}/OpenCycles/#{foldername}"
                FileUtils.mkdir(folderpath)
                reference = SecureRandom.hex
                FileSystemReferences::issueCfsrFileAtDirectory(folderpath, reference)
                Cubes2::setAttribute(item["uuid"], "cfsr-20231213", reference)
                next
            end
        }
    end
end
