
class NxFloats

    # NxFloats::issue(line)
    def self.issue(line)
        description = line
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxFloat", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxFloats::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxFloats::issue(description)
    end

    # NxFloats::interactivelyIssueNewAtParentOrNull(parent)
    def self.interactivelyIssueNewAtParentOrNull(parent)
        if parent["mikuType"] == "NxThread" then
            position = 0
        else
            position = Tx8s::interactivelyDecidePositionUnderThisParent(parent)
        end
        tx8 = Tx8s::make(parent["uuid"], position)

        float = NxFloats::interactivelyIssueNewOrNull()
        return nil if float.nil?

        DarkEnergy::patch(float["uuid"], "parent", tx8)
    end

    # NxFloats::toString(item)
    def self.toString(item)
        "🛸 #{item["description"]}"
    end

    # NxFloats::listingItemsForMainListing()
    def self.listingItemsForMainListing()
        DarkEnergy::mikuType("NxFloat")
            .select{|float| float["parent"].nil? }
    end

    # NxFloats::listingItemsForThread(thread)
    def self.listingItemsForThread(thread)
        DarkEnergy::mikuType("NxFloat")
            .select{|float| float["parent"] and float["parent"]["uuid"] == thread["uuid"] }
    end

    # NxFloats::maintenance()
    def self.maintenance()
        DarkEnergy::mikuType("NxFloat")
            .each{|float| 
                next if float["parent"].nil?
                if DarkEnergy::itemOrNull(float["parent"]["uuid"]).nil? then
                    DarkEnergy::patch(float["uuid"], "parent", nil)
                end
            }
    end

    # NxFloats::program1()
    def self.program1()
        loop {
            float = LucilleCore::selectEntityFromListOfEntitiesOrNull("float", DarkEnergy::mikuType("NxFloat"), lambda{|float| NxFloats::toString(float) })
            return if float.nil?
            PolyActions::access(float)
        }
    end
end