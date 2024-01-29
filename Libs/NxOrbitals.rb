
class NxOrbitals

    # ------------------
    # Data

    # NxOrbitals::bufferInCardinal()
    def self.bufferInCardinal()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/Buffer-In")
            .select{|location| !File.basename(location).start_with?(".") }
            .size
    end

    # NxOrbitals::toString(item, context = nil)
    def self.toString(item, context = nil)
        description = item["description"]
        if item["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks
            if NxOrbitals::bufferInCardinal() > 0 then
                description = "block; special circumstances: DataHub/Buffer-In"
            end
        end
        "🔅 #{description}"
    end

    # NxOrbitals::children(listing)
    def self.children(listing)
        Cubes2::items()
            .select{|item| item["parentuuid-0032"] == listing["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxOrbitals::muiItems()
    def self.muiItems()
        Cubes2::mikuType("NxOrbital").each{|orbital|
            if orbital["engine-0020"].nil? then
                puts "I need an engine for orbital '#{orbital["description"]}'"
                core = TxCores::interactivelyMakeNewOrNull()
                Cubes2::setAttribute(orbital["uuid"], "engine-0020", core)
                return NxOrbitals::muiItems()
            end
        }

        return [] if Bank2::recoveredAverageHoursPerDay("orbital-control-497b-bedb-0152d1d9248a") > 1

        Cubes2::mikuType("NxOrbital")
            .sort_by{|item| TxCores::listingCompletionRatio(item["engine-0020"]) }
            .take(1)
    end
end
