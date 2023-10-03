

class Catalyst

    # Catalyst::listingCompletionRatio(item)
    def self.listingCompletionRatio(item)
        if item["mikuType"] == "NxTask" then
            return Bank::recoveredAverageHoursPerDay(item["uuid"])
        end
        if item["mikuType"] == "TxCore" then
            hours = item["hours"]
            return Bank::recoveredAverageHoursPerDay(item["uuid"]).to_f/(hours.to_f/6)
        end
        if item["mikuType"] == "NxClique" then
            return TxEngine::ratio(item["engine-2251"])
        end
        raise "(error: 3b1e3b09-1472-48ef-bcbb-d98c8d170056) with item: #{item}"
    end

    # Catalyst::editItem(item)
    def self.editItem(item)
        item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
        item.to_a.each{|key, value|
            Events::publishItemAttributeUpdate(item["uuid"], key, value)
        }
    end

    # Catalyst::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        EventTimelineDatasets::catalystItems()[uuid].clone
    end

    # Catalyst::mikuType(mikuType)
    def self.mikuType(mikuType)
        EventTimelineDatasets::catalystItems().values.select{|item| item["mikuType"] == mikuType }
    end

    # Catalyst::destroy(uuid)
    def self.destroy(uuid)
        Events::publishItemDestroy(uuid)
    end

    # Catalyst::catalystItems()
    def self.catalystItems()
        EventTimelineDatasets::catalystItems().values
    end

    # Catalyst::newGlobalFirstPosition()
    def self.newGlobalFirstPosition()
        t = Catalyst::catalystItems()
                .select{|item| item["global-position"] }
                .map{|item| item["global-position"] }
                .reduce(0){|number, x| [number, x].min}
        t - 1
    end

    # Catalyst::newGlobalLastPosition()
    def self.newGlobalLastPosition()
        t = Catalyst::catalystItems()
                .select{|item| item["global-position"] }
                .map{|item| item["global-position"] }
                .reduce(0){|number, x| [number, x].max }
        t + 1
    end

    # Catalyst::engined()
    def self.engined()
        (Catalyst::mikuType("NxTask") + Catalyst::mikuType("NxClique"))
            .select{|item| item["engine-2251"] }
    end
end
