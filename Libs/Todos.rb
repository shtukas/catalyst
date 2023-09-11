# Todos refer to threads and tasks seen together

class Todos

    # Todos::mainListingItems()
    def self.mainListingItems()
        coreuuids = Cubes::mikuType("TxCore").map{|i| i["uuid"] }
        x1 = Cubes::mikuType("NxThread").select{|item| coreuuids.include?(item["lineage-nx128"]) }
        x2 = Cubes::mikuType("NxTask").select{|item| coreuuids.include?(item["lineage-nx128"]) }
        (x1 + x2)
            .sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
            .map{|item| 
                item["prefix-override"] = "(#{"%5.3f" % Bank::recoveredAverageHoursPerDay(item["uuid"])})"
                item
            }
    end

    # Todos::topItemsForPoolBuilding()
    def self.topItemsForPoolBuilding()
        coreuuids = Cubes::mikuType("TxCore").map{|i| i["uuid"] }
        x1 = Cubes::mikuType("NxThread").select{|item| coreuuids.include?(item["lineage-nx128"]) }
        x2 = Cubes::mikuType("NxTask").select{|item| coreuuids.include?(item["lineage-nx128"]) }
        (x1 + x2).sort_by{|item| item["coordinate-nx129"] || 0 }
    end

    # Todos::children(parent)
    def self.children(parent)
        x1 = Cubes::mikuType("NxThread").select{|item| item["lineage-nx128"] == parent["uuid"] }
        x2 = Cubes::mikuType("NxTask").select{|item| item["lineage-nx128"] == parent["uuid"] }
        (x1 + x2)
    end

    # Todos::bufferInItems()
    def self.bufferInItems()
        Cubes::mikuType("NxTask")
            .select{|item| item["lineage-nx128"].nil? }
            .select{|item| item["description"].include?("(buffer-in)") }
            .sort_by{|item| item["unixtime"] }
    end
end
