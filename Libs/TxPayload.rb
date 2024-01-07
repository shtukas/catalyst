

class TxPayload

    # TxPayload::interactivelyMakeNewOr(uuid)
    def self.interactivelyMakeNewOr(uuid)
        payload = {
            "field11"           => nil,
            "todotextfile-1312" => nil,
            "note-1531"         => nil,
            "cfsr-20231213"     => nil
        }
        loop {
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["coredata", "note", "textfile", "file system reference"])
            return payload if option.nil?
            if option == "coredata" then
                coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
                if coredataref then
                    payload["field11"] = coredataref
                end
                next
            end
            if option == "note" then
                note = payload["note-1531"] || ""
                note = CommonUtils::editTextSynchronously(note).strip
                note = note.size > 0 ? note : nil
                payload["note-1531"] = note
                next
            end
            if option == "textfile" then
                todotextfile = LucilleCore::askQuestionAnswerAsString("name or fragment: ")
                if todotextfile != "" then
                    payload["todotextfile-1312"] = todotextfile
                end
                next
            end
            if option == "file system reference" then
                reference = FileSystemReferences::interactivelyIssueFileSystemReferenceOrNull()
                if reference then
                    payload["cfsr-20231213"] = reference
                end
                next
            end
        }
    end

    # TxPayload::suffix_string(item)
    def self.suffix_string(item)
        str = [
            CoreDataRefStrings::referenceToStringOrNull(item["field11"]),
            item["note-1531"] ? "(note)" : nil,
            item["todotextfile-1312"] ? "(textfile: #{item["todotextfile-1312"]})" : nil,
            item["cfsr-20231213"] ? "(cfsr)" : nil
        ]
            .compact
            .join(' ').green

        return "" if str == ""
        " #{str}".green
    end

    # TxPayload::edit(item)
    def self.edit(item)
        return if item["mikuType"] == "NxBlock"
        loop {
            puts "payload:#{TxPayload::suffix_string(item)}".green
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["coredata", "note", "textfile", "file system reference"])
            return if option.nil?
            if option == "coredata" then
                coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(item["uuid"])
                if coredataref then
                    item["field11"] = coredataref
                    Cubes2::setAttribute(item["uuid"], "field11", coredataref)
                end
            end
            if option == "note" then
                note = item["note-1531"] || ""
                note = CommonUtils::editTextSynchronously(note).strip
                note = note.size > 0 ? note : nil
                item["note-1531"] = note
                Cubes2::setAttribute(item["uuid"], "note-1531", note)
            end
            if option == "textfile" then
                todotextfile = LucilleCore::askQuestionAnswerAsString("name or fragment: ")
                if todotextfile != "" then
                    item["todotextfile-1312"] = todotextfile
                    Cubes2::setAttribute(item["uuid"], "todotextfile-1312", todotextfile)
                end
            end
            if option == "file system reference" then
                reference = FileSystemReferences::interactivelyIssueFileSystemReferenceOrNull()
                if reference then
                    item["cfsr-20231213"] = reference
                    Cubes2::setAttribute(item["uuid"], "cfsr-20231213", reference)
                end
            end
        }
    end

    # TxPayload::access(item)
    def self.access(item)
        return if item["mikuType"] == "NxBlock"
        loop {
            puts "payload:#{TxPayload::suffix_string(item)}".green
            options = [
                CoreDataRefStrings::referenceToStringOrNull(item["field11"]),
                item["note-1531"] ? "(note)" : nil,
                item["todotextfile-1312"] ? "(textfile: #{item["todotextfile-1312"]})" : nil,
                item["cfsr-20231213"] ? "(cfsr)" : nil
            ]
            .compact
            option = nil
            return if options.size == 0
            if options.size == 1 then
                option = options.first
            end
            if options.size > 1 then
                option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
                return if option.nil?
            end
            if option == CoreDataRefStrings::referenceToStringOrNull(item["field11"]) then
                CoreDataRefStrings::accessAndMaybeEdit(item["uuid"], item["field11"])
            end
            if option == "note" then
                note = item["note-1531"] || ""
                note = CommonUtils::editTextSynchronously(note).strip
                note = note.size > 0 ? note : nil
                item["note-1531"] = note
                Cubes2::setAttribute(item["uuid"], "note-1531", note)
            end
            if option == "textfile" then
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
            if option == "file system reference" then
                reference = item["cfsr-20231213"]
                FileSystemReferences::accessReference(reference)
            end
            if options.size == 1 then
                break
            end
        }
    end
end
