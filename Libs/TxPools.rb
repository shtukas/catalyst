
class TxPools

    # TxPools::issue(description)
    def self.issue(description)
        uuid = SecureRandom.uuid
        DarkEnergy::init("TxPool", uuid)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::itemOrNull(uuid)
    end

    # TxPools::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        TxPools::issue(description)
    end

    # TxPools::toString(item)
    def self.toString(item)
        "👩‍💻 #{item["description"]}"
    end
end