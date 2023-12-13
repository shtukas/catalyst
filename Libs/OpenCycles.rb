class OpenCycles

    # OpenCycles::issueReferenceAndMonitorForThisLocation(location)
    def self.issueReferenceAndMonitorForThisLocation(location)
        reference = SecureRandom.hex # both the reference and the uuid of the monitor
        FileSystemReferences::issueCfsrFileAtDirectory(location, reference)
        monitor = NxMonitors::issueNew(SecureRandom.uuid, File.basename(location))
        DataCenter::setAttribute(monitor["uuid"], "cfsr-20231213", reference)
    end

    # OpenCycles::sync()
    def self.sync()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/OpenCycles").each{|location|
            next if !File.directory?(location)
            next if File.basename(location).start_with?('.')
            cfsrfilepath = FileSystemReferences::locateCFSRfileInDirectory(location)
            if cfsrfilepath.nil? then
                puts "creating a csfr file and monitor for open cycle: #{File.basename(location).green}"
                LucilleCore::pressEnterToContinue()
                OpenCycles::issueReferenceAndMonitorForThisLocation(location)
            else
                reference = IO.read(cfsrfilepath).lines.first.strip
                item = DataCenter::catalystItems().select{|item| item["cfsr-20231213"] == reference }.first
                if !item then
                    puts "I found a csfr file in #{location.green}, but not the corresponding catalyst item. I am going to delete the reference, and create a new one"
                    LucilleCore::pressEnterToContinue()
                    FileUtils.rm(cfsrfilepath)
                    OpenCycles::issueReferenceAndMonitorForThisLocation(location)
                end
            end
        }
    end
end