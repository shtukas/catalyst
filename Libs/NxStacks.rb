
class NxStacks

    # NxStacks::interactivelyIssueNewOrNull(position)
    def self.interactivelyIssueNewOrNull(position)
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        payload = UxPayload::makeNewOrNull(uuid)
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "position-1654", position)
        Items::setAttribute(uuid, "mikuType", "NxStack")
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxStacks::toString(item)
    def self.toString(item)
        "📚 (-> #{"%7.3f" % item["position-1654"]}) #{item["description"]}"
    end

    # NxStacks::firstPosition()
    def self.firstPosition()
        ([0] + Items::mikuType("NxStack").map{|item| item["position-1654"] }).min
    end

    # NxStacks::itemsInOrder()
    def self.itemsInOrder()
        Items::mikuType("NxStack").sort_by{|item| item["position-1654"] }
    end

    # NxStacks::listingItems()
    def self.listingItems()
        Items::mikuType("NxStack")
    end

    # NxStacks::listingPosition(item)
    def self.listingPosition(item)
        0.365 + Math.atan(item["position-1654"]).to_f/100000
    end
end
