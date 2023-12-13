
class FileSystemReferences

    # FileSystemReferences::interactivelyIssueFileSystemReferenceOrNull()
    def self.interactivelyIssueFileSystemReferenceOrNull()
        options = ["enter string", "build from location's name", "generate file in directory"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        return nil if option.nil?
        if option == "enter string" then
            string = LucilleCore::askQuestionAnswerAsString("string: ")
            return string
        end
        if option == "build from location's name" then
            location = LucilleCore::askQuestionAnswerAsString("location: ")
            return File.basename(location)
        end
        if option == "generate file in directory" then
            location = LucilleCore::askQuestionAnswerAsString("location: ")
            if !File.directory?(location) then
                puts "location '#{location.green}' is not a directory"
                if LucilleCore::askQuestionAnswerAsBoolean("Would you like to try again ? ") then
                    return FileSystemReferences::interactivelyIssueFileSystemReferenceOrNull()
                end
                return nil
            end
            id = SecureRandom::uuid
            lines = [
                id,
                "This is a Catalyst file system reference (a .cfsr-20231213 file)",
                "The reference is the first line of this file" 
            ]
            contents = lines.join("\n")
            filename = ".catalyst-file-system-reference-#{SecureRandom::hex(4)}.cfsr-20231213"
            filepath = "#{location}/#{filename}"
            File.open(filepath, "w"){|f| f.puts(contents) }
            return id
        end
    end

    # FileSystemReferences::determineReferenceLocationOrNull(reference)
    def self.determineReferenceLocationOrNull(reference)
        puts "FileSystemReferences::determineReferenceLocationOrNull(reference) has not been implemented yet, but registering the request to access reference: #{reference}"
        LucilleCore::pressEnterToContinue()
        nil
    end

    # FileSystemReferences::accessReference(reference)
    def self.accessReference(reference)
        location = FileSystemReferences::determineReferenceLocationOrNull(reference)
        puts "FileSystemReferences::accessReference(reference) has not been implemented yet, but registering the request to access reference: #{reference}"
        LucilleCore::pressEnterToContinue()
    end

    # FileSystemReferences::suffix(item)
    def self.suffix(item)
        return "" if item["cfsr-20231213"].nil?
        " (cfsr)".red
    end

end
