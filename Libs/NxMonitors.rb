
class NxMonitors

    # NxMonitors::toString(item)
    def self.toString(item)
        "🪄 #{"(#{"%5.3f" % NxMonitors::ratio(item)})".green} #{item["description"]}"
    end

    # NxMonitors::activeItems()
    def self.activeItems()
        items = []

        item = Items::itemOrNull("b9dc200c-c8ec-4917-b93b-e78da7fea84e")
        if NxMonitors::ratio(item) < 1 and LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/Buffer-In").size > 0 then
            items << item
        end

        items
    end

    # NxMonitors::listingItems()
    def self.listingItems()
        NxMonitors::activeItems()
    end

    # NxMonitors::ratio(item)
    def self.ratio(item)
        Bank1::recoveredAverageHoursPerDay(item["uuid"])
    end
end
