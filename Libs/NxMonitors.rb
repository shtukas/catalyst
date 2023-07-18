
class NxMonitors

    # NxMonitors::issue(line)
    def self.issue(line)
        description = line
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxMonitor", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxMonitors::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxMonitors::issue(description)
    end

    # NxMonitors::interactivelyIssueNewAtParentOrNull(parent)
    def self.interactivelyIssueNewAtParentOrNull(parent)
        if parent["mikuType"] == "NxThread" then
            position = 0
        else
            position = Tx8s::interactivelyDecidePositionUnderThisParent(parent)
        end
        tx8 = Tx8s::make(parent["uuid"], position)

        float = NxMonitors::interactivelyIssueNewOrNull()
        return nil if float.nil?

        DarkEnergy::patch(float["uuid"], "parent", tx8)
    end

    # NxMonitors::toString(item)
    def self.toString(item)
        "📡 #{item["description"]}"
    end

    # NxMonitors::listingItemsForMainListing()
    def self.listingItemsForMainListing()
        DarkEnergy::mikuType("NxMonitor")
            .select{|float| float["parent"].nil? }
    end

    # NxMonitors::listingItemsForThread(thread)
    def self.listingItemsForThread(thread)
        DarkEnergy::mikuType("NxMonitor")
            .select{|float| float["parent"] and float["parent"]["uuid"] == thread["uuid"] }
    end

    # NxMonitors::maintenance()
    def self.maintenance()
        DarkEnergy::mikuType("NxMonitor")
            .each{|float| 
                next if float["parent"].nil?
                if DarkEnergy::itemOrNull(float["parent"]["uuid"]).nil? then
                    DarkEnergy::patch(float["uuid"], "parent", nil)
                end
            }
    end

    # NxMonitors::program1()
    def self.program1()
        loop {
            float = LucilleCore::selectEntityFromListOfEntitiesOrNull("float", DarkEnergy::mikuType("NxMonitor"), lambda{|float| NxMonitors::toString(float) })
            return if float.nil?
            PolyActions::access(float)
        }
    end
end