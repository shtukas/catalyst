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
            .select{|item| item["engine-0852"].nil? }
            .sort_by{|item| item["unixtime"] }
    end

    # Todos::timeCommitmentItems()
    def self.timeCommitmentItems()
        (Catalyst::mikuType("NxTask") + Catalyst::mikuType("NxThread"))
            .select{|item| item["engine-0852"] and item["engine-0852"]["mikuType"] == "TxE-TimeCommitment" }
            .select{|item| TxEngine::ratio(item["engine-0852"]) < 1 }
            .sort_by{|item| TxEngine::ratio(item["engine-0852"]) }
    end

    # Todos::onDateItems()
    def self.onDateItems()
        (Catalyst::mikuType("NxTask") + Catalyst::mikuType("NxThread"))
            .select{|item| item["engine-0852"] and item["engine-0852"]["mikuType"] == "TxE-OnDate" }
            .select{|item| CommonUtils::today() >= item["engine-0852"]["date"] }
            .sort_by{|item| item["engine-0852"]["date"] }
    end

    # Todos::trajectoryItems(level)
    def self.trajectoryItems(level)
        (Catalyst::mikuType("NxTask") + Catalyst::mikuType("NxThread"))
            .select{|item| item["engine-0852"] and item["engine-0852"]["mikuType"] == "TxE-Trajectory" }
            .select{|item| TxEngine::ratio(item["engine-0852"]) >= level }
            .sort_by{|item| TxEngine::ratio(item["engine-0852"]) }
            .reverse
    end

    # Todos::noEngineItems()
    def self.noEngineItems()
        (Catalyst::mikuType("NxTask") + Catalyst::mikuType("NxThread"))
            .select{|item| item["engine-0852"].nil? }
            .sort_by{|item| Bank::recoveredAverageHoursPerDayCached(item["uuid"]) }
    end
end
