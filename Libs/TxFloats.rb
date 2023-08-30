
class TxFloats

    # TxFloats::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Cubes::init(nil, "TxFloat", uuid)
        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute2(uuid, "description", description)
        Cubes::itemOrNull(uuid)
    end

    # TxFloats::toString(item)
    def self.toString(item)
        "🔹 #{item["description"]}"
    end

    # TxFloats::listingItems1()
    def self.listingItems1()
        Cubes::mikuType("TxFloat")
            .select{|item| item["acknowledgement"] == CommonUtils::today() }
            .sort_by{|item| item["unixtime"] }
    end

    # TxFloats::listingItems2()
    def self.listingItems2()
        Cubes::mikuType("TxFloat")
            .select{|item| item["acknowledgement"] != CommonUtils::today() }
            .sort_by{|item| item["unixtime"] }
    end

    # TxFloats::program2(item)
    def self.program2(item)
        options = ["destroy", "ack for today", "edit + ack"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        return if option.nil?
        if option == "destroy" then
            Cubes::destroy(item["uuid"])
        end
        if option == "ack for today" then
            Cubes::setAttribute2(item["uuid"], "acknowledgement", CommonUtils::today())
        end
        if option == "edit + ack" then
            description = CommonUtils::editTextSynchronously(item["description"])
            Cubes::setAttribute2(item["uuid"], "description", description)
            Cubes::setAttribute2(item["uuid"], "acknowledgement", CommonUtils::today())
        end
    end

    # TxFloats::program1()
    def self.program1()
        loop {
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", Cubes::mikuType("TxFloat"), lambda{|item| TxFloats::toString(item) })
            return if item.nil?
            TxFloats::program2(item)
        }
    end
end
