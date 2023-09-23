# Todos refer to threads and tasks seen together

class Todos

    # Todos::children(parent)
    def self.children(parent)
        x1 = Catalyst::mikuType("NxThread").select{|item| item["lineage-nx128"] == parent["uuid"] }
        x2 = Catalyst::mikuType("NxTask").select{|item| item["lineage-nx128"] == parent["uuid"] }
        x3 = Catalyst::mikuType("NxCruise").select{|item| item["lineage-nx128"] == parent["uuid"] }
        (x1 + x2 + x3)
    end

    # Todos::bufferInItems()
    def self.bufferInItems()
        Catalyst::mikuType("NxTask")
            .select{|item| item["lineage-nx128"].nil? }
            .select{|item| item["description"].include?("(buffer-in)") }
            .sort_by{|item| item["unixtime"] }
    end

    # Todos::engineItems()
    def self.engineItems()
        (Catalyst::mikuType("NxTask") + Catalyst::mikuType("NxThread"))
            .select{|item| item["drive-nx1"]}
            .select{|item| TxEngine::ratio(item["drive-nx1"]) < 1 }
            .sort_by{|item| TxEngine::ratio(item["drive-nx1"]) }
    end

    # Todos::engineLessItems()
    def self.engineLessItems()
        (Catalyst::mikuType("NxTask") + Catalyst::mikuType("NxThread"))
            .select{|item| item["drive-nx1"].nil? }
            .sort_by{|item| Bank::recoveredAverageHoursPerDayCached(item["uuid"]) }
    end
end
