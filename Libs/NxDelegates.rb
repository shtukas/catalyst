
class NxDelegates

    # NxDelegates::issue(line)
    def self.issue(line)
        description = line
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxDelegate", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxDelegates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxDelegates::issue(description)
    end

    # NxDelegates::interactivelyIssueNewAtParentOrNull(parent)
    def self.interactivelyIssueNewAtParentOrNull(parent)
        if parent["mikuType"] == "NxThread" then
            position = 0
        else
            position = Tx8s::interactivelyDecidePositionUnderThisParent(parent)
        end
        tx8 = Tx8s::make(parent["uuid"], position)

        float = NxDelegates::interactivelyIssueNewOrNull()
        return nil if float.nil?

        DarkEnergy::patch(float["uuid"], "parent", tx8)
    end

    # NxDelegates::toString(item)
    def self.toString(item)
        "📡 #{item["description"]}"
    end

    # NxDelegates::listingItemsForMainListing()
    def self.listingItemsForMainListing()
        DarkEnergy::mikuType("NxDelegate")
            .select{|float| float["parent"].nil? }
    end

    # NxDelegates::listingItemsForThread(thread)
    def self.listingItemsForThread(thread)
        DarkEnergy::mikuType("NxDelegate")
            .select{|float| float["parent"] and float["parent"]["uuid"] == thread["uuid"] }
    end

    # NxDelegates::maintenance()
    def self.maintenance()
        DarkEnergy::mikuType("NxDelegate")
            .each{|float| 
                next if float["parent"].nil?
                if DarkEnergy::itemOrNull(float["parent"]["uuid"]).nil? then
                    DarkEnergy::patch(float["uuid"], "parent", nil)
                end
            }
    end

    # NxDelegates::program1()
    def self.program1()
        loop {
            float = LucilleCore::selectEntityFromListOfEntitiesOrNull("float", DarkEnergy::mikuType("NxDelegate"), lambda{|float| NxDelegates::toString(float) })
            return if float.nil?
            PolyActions::access(float)
        }
    end
end