
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
        "💫 #{description}"
    end

    # NxOrbitals::children(orbital)
    def self.children(orbital)
        Cubes2::items()
            .select{|item| item["parentuuid-0032"] == orbital["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxOrbitals::muiItems()
    def self.muiItems()
        Cubes2::mikuType("NxOrbital").each{|orbital|
            if orbital["engine-0020"].nil? then
                puts "I need an engine for orbital '#{orbital["description"]}'"
                core = TxEngines::interactivelyMakeNewOrNull()
                Cubes2::setAttribute(orbital["uuid"], "engine-0020", core)
                return NxOrbitals::muiItems()
            end
        }

        return [] if Bank2::recoveredAverageHoursPerDay("9f891bc1-ca32-4792-8d66-d66612a4e7c6") > 1

        Cubes2::mikuType("NxOrbital")
            .sort_by{|item| TxEngines::listingCompletionRatio(item["engine-0020"]) }
            .take(1)
    end

    # NxOrbitals::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("orbital", Cubes2::mikuType("NxOrbital"), lambda{|item| PolyFunctions::toString(item) })
    end
end
