class OpenCycles

    # OpenCycles::issueReferenceAndProjectForThisLocation(location)
    def self.issueReferenceAndProjectForThisLocation(location)
        reference = SecureRandom.hex
        FileSystemReferences::issueCfsrFileAtDirectory(location, reference)

        uuid = SecureRandom.uuid

        Cubes2::itemInit(uuid, "NxTodo")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "engine-0020", nil)
        Cubes2::setAttribute(uuid, "description", "#{File.basename(location)} (auto)")
        Cubes2::setAttribute(uuid, "cfsr-20231213", reference)
    end

    # OpenCycles::sync()
    def self.sync()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/OpenCycles").each{|location|
            next if !File.directory?(location)
            next if File.basename(location).start_with?('.')
            cfsrfilepath = FileSystemReferences::locateCFSRfileInDirectoryOrNull(location)
            if cfsrfilepath.nil? then
                puts "creating a csfr file and monitor for open cycle: #{File.basename(location).green}"
                LucilleCore::pressEnterToContinue()
                OpenCycles::issueReferenceAndProjectForThisLocation(location)
            else
                reference = IO.read(cfsrfilepath).lines.first.strip
                item = Cubes2::items().select{|item| item["cfsr-20231213"] == reference }.first
                if !item then
                    puts "I found a csfr file in #{location.green}, but not the corresponding catalyst item. I am going to delete the reference, and create a new one"
                    LucilleCore::pressEnterToContinue()
                    FileUtils.rm(cfsrfilepath)
                    OpenCycles::issueReferenceAndProjectForThisLocation(location)
                end
            end
        }
    end
end