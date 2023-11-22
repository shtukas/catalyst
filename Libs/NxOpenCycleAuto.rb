

class NxOpenCycleAutos

    # --------------------------------------------------
    # Makers

    # NxOpenCycleAutos::getItemByUuidOrNull(marker)
    def self.getItemByUuidOrNull(marker)
        # Although called "marker" in the signature of this function, it's actually the 
        # uuid of the corresponding NxOpenCycleAuto. We call it marker because it's 
        # written in a file in the directory

        Catalist::itemOrNull(marker)
    end

    # NxOpenCycleAutos::getDirectoryPathByMarkerOrNull(uuid)
    def self.getDirectoryPathByMarkerOrNull(uuid)
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/OpenCycles").each{|folderpath|
            markerfile = "#{folderpath}/.marker-709b82a0903b"
            next if !File.exist?(markerfile)
            return folderpath if IO.read(markerfile).strip == uuid
        }
        nil
    end

    # NxOpenCycleAutos::interactivelyIssueNew(uuid, description)
    def self.interactivelyIssueNew(uuid, description)
        engine = TxEngines::interactivelyMakeNewOrNull()
        DataCenter::itemInit(uuid, "NxOpenCycleAuto")
        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::setAttribute(uuid, "engine-0916", engine)
        item = DataCenter::itemOrNull(uuid)
        TxCores::interactivelySelectAndPutInCore(item)
        item
    end

    # NxOpenCycleAutos::sync()
    def self.sync()
        DataCenter::mikuType("NxOpenCycleAuto").each{|item|
            uuid = item["uuid"]
            if NxOpenCycleAutos::getDirectoryPathByMarkerOrNull(uuid).nil? then
                NxBalls::stop(item)
                DataCenter::destroy(item["uuid"])
            end
        }
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/OpenCycles").each{|location|
            next if !File.directory?(location)
            next if File.basename(location).start_with?('.')
            markerfile = "#{location}/.marker-709b82a0903b"
            if !File.exist?(markerfile) then
                uuid = SecureRandom.uuid
                File.open(markerfile, "w"){|f| f.puts(uuid) }
                puts "Generating #{"NxOpenCycleAuto".green} for '#{File.basename(location).green}'"
                LucilleCore::pressEnterToContinue()
                NxOpenCycleAutos::interactivelyIssueNew(uuid, File.basename(location))
            end
        }
    end

    # --------------------------------------------------
    # Data

    # NxOpenCycleAutos::toString(item)
    def self.toString(item)
        "📂#{TxEngines::string1(item)} #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item)}"
    end

    # NxOpenCycleAutos::listingItems()
    def self.listingItems()
        DataCenter::mikuType("NxOpenCycleAuto")
            .select{|item| TxEngines::shouldShowInListing(item) }
            .sort_by{|item| item["unixtime"] }
    end

    # --------------------------------------------------
    # Operations

end
