
class NxMonitors

    # NxMonitors::toString(item)
    def self.toString(item)
        "🪄 #{"(#{"%5.3f" % NxMonitors::ratio(item)})".green} #{item["description"]}"
    end

    # NxMonitors::listingItems()
    def self.listingItems()
        items = []
        if LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/Buffer-In").size > 0 then
            items << {
                "uuid"        => "b9dc200c-c8ec-4917-b93b-e78da7fea84e",
                "mikuType"    => "NxMonitor",
                "description" => "Process DataHub/Buffer-In"
            }
        end
        items
    end

    # NxMonitors::ratio(item)
    def self.ratio(item)
        Bank1::recoveredAverageHoursPerDay(item["uuid"])
    end
end
