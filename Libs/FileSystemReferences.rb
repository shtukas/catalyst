
class FileSystemReferences

    # FileSystemReferences::issueCfsrFileAtDirectory(dirlocation, id)
    def self.issueCfsrFileAtDirectory(dirlocation, id)
        lines = [
            id,
            "This is a Catalyst file system reference (a .cfsr-20231213 file)",
            "The reference is the first line of this file" 
        ]
        contents = lines.join("\n")
        filename = ".catalyst-file-system-reference-#{SecureRandom::hex(4)}.cfsr-20231213"
        filepath = "#{dirlocation}/#{filename}"
        File.open(filepath, "w"){|f| f.puts(contents) }
    end

    # FileSystemReferences::issueOrReadOpenCycleDirectoryReferenceOrNull()
    def self.issueOrReadOpenCycleDirectoryReferenceOrNull()
        locations = LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/OpenCycles")
            .select{|location| !File.basename(location).start_with?('.') }
            .select{|location| File.directory?(location) }
        location = LucilleCore::selectEntityFromListOfEntitiesOrNull("directory", locations, lambda{|l| File.basename(l) })
        return nil if location.nil?
        filepath = FileSystemReferences::locateCFSRfileInDirectoryOrNull(location)
        if filepath then
            return IO.read(filepath).lines.first.strip
        end
        id = SecureRandom::hex
        FileSystemReferences::issueCfsrFileAtDirectory(location, id)
        id
    end

    # FileSystemReferences::interactivelyIssueFileSystemReferenceOrNull()
    def self.interactivelyIssueFileSystemReferenceOrNull()
        options = ["enter string", "build from location's name", "generate file in directory", "reference for an open cycle"]
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
            FileSystemReferences::issueCfsrFileAtDirectory(location, id)
            return id
        end
        if option == "reference for an open cycle" then
            return FileSystemReferences::issueOrReadOpenCycleDirectoryReferenceOrNull()
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

    # FileSystemReferences::locateCFSRfileInDirectoryOrNull(location)
    def self.locateCFSRfileInDirectoryOrNull(location)
        raise "error: a57f4952" if !File.directory?(location)
        LucilleCore::locationsAtFolder(location)
            .select{|loc| loc[-14, 14] == ".cfsr-20231213" }
            .first
    end

    # FileSystemReferences::suffix(item)
    def self.suffix(item)
        return "" if item["cfsr-20231213"].nil?
        " (cfsr)".green
    end

end
