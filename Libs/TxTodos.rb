
# Todos refer to tasks without a lineage, essentially not withing a thread and the threads

class TxTodos
    # TxTodos::listingItems()
    def self.listingItems()
        # We return the tasks without a lineage and the threads in order
        i1s = Cubes::mikuType("NxTask").select{|item| item["lineage-nx128"].nil? }
        i2s = Cubes::mikuType("NxThread")
        (i1s + i2s).sort_by{|item| item["coordinate-nx129"] || 0 }
    end
end