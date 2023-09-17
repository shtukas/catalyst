# Todos refer to threads and tasks seen together

class Todos

    # Todos::children(parent)
    def self.children(parent)
        x1 = Catalyst::mikuType("NxThread").select{|item| item["lineage-nx128"] == parent["uuid"] }
        x2 = Catalyst::mikuType("NxTask").select{|item| item["lineage-nx128"] == parent["uuid"] }
        (x1 + x2)
    end

    # Todos::bufferInItems()
    def self.bufferInItems()
        Catalyst::mikuType("NxTask")
            .select{|item| item["lineage-nx128"].nil? }
            .select{|item| item["description"].include?("(buffer-in)") }
            .sort_by{|item| item["unixtime"] }
    end

    # Todos::drivenItems()
    def self.drivenItems()
        (Catalyst::mikuType("NxTask") + Catalyst::mikuType("NxThread"))
            .select{|item| item["drive-nx1"]}
            .sort_by{|item| TxEngine::ratio(item["drive-nx1"]) }
    end

    # Todos::priorityItems()
    def self.priorityItems()
        (Catalyst::mikuType("NxTask") + Catalyst::mikuType("NxThread"))
            .select{|item| item["isPriorityTodo-8"]}
            .sort_by{|item| item["unixtime"] }
    end

    # Todos::otherItems()
    def self.otherItems()
        (Catalyst::mikuType("NxTask") + Catalyst::mikuType("NxThread"))
            .select{|item| item["drive-nx1"].nil? }
            .sort_by{|item| Bank::recoveredAverageHoursPerDayCached(item["uuid"]) }
    end

    # Todos::prioritySuffix(item)
    def self.prioritySuffix(item)
        return "" if !item["isPriorityTodo-8"]
        " (priority)".green
    end

end
