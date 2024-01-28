

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
        options = TxPayload::mapping().keys.map{|key| TxPayload::keysToFriendly(key) }
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
                raise "be5eeeb4-2333-40e8-b264-23ac2f73b964"
                next
            end
            if TxPayload::friendlyToKey(option) == "dx8UnitId-00286e29" then
                raise "be5eeeb4-2433-40e8-b264-23ac2f73b964"
                next
            end
            if TxPayload::friendlyToKey(option) == "url-e88a" then
                raise "be5eeeb4-2343-40e8-b264-23ac2f73b964"
                next
            end
            if TxPayload::friendlyToKey(option) == "unique-string-c3e5" then
                raise "be5eeeb4-2334-40e8-b264-23ac2f73b964"
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
                AionCore::exportHashAtFolder(Elizabeth.new(uuid), nhash, exportFolder)
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
        options = TxPayload::mapping().keys.map{|key| TxPayload::keysToFriendly(key) }
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
                raise "be1eeeb4-2334-40e8-b264-24ac2f73b964"
            end
            if TxPayload::friendlyToKey(option) == "dx8UnitId-00286e29" then
                raise "be2eeeb4-234-40e8-b264-24ac2f73b964"
            end
            if TxPayload::friendlyToKey(option) == "url-e88a" then
                raise "be3eeeb4-2334-40b264-24ac2f73b964"
            end
            if TxPayload::friendlyToKey(option) == "unique-string-c3e5" then
                raise "be4eeeb4-234-40e8-b264-24a3b964"
            end
        }
    end
end
