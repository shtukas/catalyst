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
            .select{|item| item["traj-2349"].nil? }
            .sort_by{|item| item["unixtime"] }
    end

    # Todos::engineItems()
    def self.engineItems()
        (Catalyst::mikuType("NxTask") + Catalyst::mikuType("NxThread"))
            .select{|item| item["drive-nx1"]}
            .select{|item| TxEngine::ratio(item["drive-nx1"]) < 1 }
            .sort_by{|item| TxEngine::ratio(item["drive-nx1"]) }
    end

    # Todos::trajectoryItems(level)
    def self.trajectoryItems(level)
        (Catalyst::mikuType("NxTask") + Catalyst::mikuType("NxThread"))
            .select{|item| item["traj-2349"]}
            .select{|item| TxTrajectory::ratio(item["traj-2349"]) >= level }
            .sort_by{|item| TxTrajectory::ratio(item["traj-2349"]) }
            .reverse
    end

    # Todos::driverLessItems()
    def self.driverLessItems()
        (Catalyst::mikuType("NxTask") + Catalyst::mikuType("NxThread"))
            .select{|item| item["drive-nx1"].nil? }
            .select{|item| item["traj-2349"].nil? }
            .sort_by{|item| Bank::recoveredAverageHoursPerDayCached(item["uuid"]) }
    end
end
