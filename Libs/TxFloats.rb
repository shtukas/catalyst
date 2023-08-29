
class TxFloats

    # TxFloats::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        text = CommonUtils::editTextSynchronously("")
        uuid = SecureRandom.uuid
        Cubes::init(nil, "TxFloat", uuid)
        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute2(uuid, "description", description)
        Cubes::setAttribute2(uuid, "text", text)
        Cubes::itemOrNull(uuid)
    end

    # TxFloats::toString(item)
    def self.toString(item)
        announce = item["text"].strip.size > 0 ? item["text"].strip.lines.first.strip : "(empty text)"
        "🚁 #{item["description"]} [ #{announce.green} ]"
    end

    # TxFloats::listingItems()
    def self.listingItems()
        Cubes::mikuType("TxFloat")
    end

    # TxFloats::program2(item)
    def self.program2(item)
        text = CommonUtils::editTextSynchronously(item["text"])
        Cubes::setAttribute2(item["uuid"], "text", text)
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
