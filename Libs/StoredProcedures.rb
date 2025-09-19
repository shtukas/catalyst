
# encoding: UTF-8

class StoredProcedures

    # StoredProcedures::run(ticket)
    def self.run(ticket)
        if ticket == "89522763-8047-4a44-af8b-a2dac7d62435" then
            Operations::morning()
            return
        end
    end
end
