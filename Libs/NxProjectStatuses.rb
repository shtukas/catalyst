
class NxProjectStatuses

    # NxProjectStatuses::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        text = CommonUtils::editTextSynchronously("")
        uuid = SecureRandom.uuid
        BladesGI::init("NxProjectStatus", uuid)
        BladesGI::setAttribute2(uuid, "unixtime", Time.new.to_i)
        BladesGI::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        BladesGI::setAttribute2(uuid, "description", description)
        BladesGI::setAttribute2(uuid, "text", text)
        BladesGI::itemOrNull(uuid)
    end

    # NxProjectStatuses::toString(item)
    def self.toString(item)
        announce = item["text"].strip.size > 0 ? item["text"].strip.lines.first.strip : "(empty text)"
        "🚁 #{item["description"]} [#{announce.green}]"
    end

    # NxProjectStatuses::listingItems(parents)
    def self.listingItems(parents)
        parentsuuids = parents.map{|px| px["uuid"]}
        BladesGI::mikuType("NxProjectStatus")
            .select{|item| item["parent"].nil? or parentsuuids.include?(item["parent"]["uuid"])}
    end

    # NxProjectStatuses::program2(item)
    def self.program2(item)
        text = CommonUtils::editTextSynchronously(item["text"])
        BladesGI::setAttribute2(item["uuid"], "text", text)
    end

    # NxProjectStatuses::program1()
    def self.program1()
        loop {
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", BladesGI::mikuType("NxProjectStatus"), lambda{|item| NxProjectStatuses::toString(item) })
            return if item.nil?
            NxProjectStatuses::program2(item)
        }
    end
end
