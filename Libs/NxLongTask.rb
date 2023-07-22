
class NxLongTasks

    # NxLongTasks::issue(line)
    def self.issue(line)
        description = line
        uuid = SecureRandom.uuid
        BladesGI::init("NxLongTask", uuid)
        BladesGI::setAttribute2(uuid, "unixtime", Time.new.to_i)
        BladesGI::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        BladesGI::setAttribute2(uuid, "description", description)
        BladesGI::itemOrNull(uuid)
    end

    # NxLongTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxLongTasks::issue(description)
    end

    # NxLongTasks::interactivelyIssueNewAtParentOrNull(parent)
    def self.interactivelyIssueNewAtParentOrNull(parent)
        position = nil
        if parent["mikuType"] == "NxThread" then
            position = 0
        end
        if parent["mikuType"] == "TxCore" then
            position = 0
        end
        if position.nil? then
            position = Tx8s::interactivelyDecidePositionUnderThisParent(parent)
        end
        tx8 = Tx8s::make(parent["uuid"], position)
        delegate = NxLongTasks::interactivelyIssueNewOrNull()
        return nil if delegate.nil?

        BladesGI::setAttribute2(delegate["uuid"], "parent", tx8)
    end

    # NxLongTasks::toString(item)
    def self.toString(item)
        "⛵️ #{item["description"]}"
    end

    # NxLongTasks::listingItemsForMainListing()
    def self.listingItemsForMainListing()
        BladesItemised::mikuType("NxLongTask")
            .select{|delegate| delegate["parent"].nil? }
    end

    # NxLongTasks::listingItemsForThread(thread)
    def self.listingItemsForThread(thread)
        BladesItemised::mikuType("NxLongTask")
            .select{|delegate| delegate["parent"] and delegate["parent"]["uuid"] == thread["uuid"] }
    end

    # NxLongTasks::maintenance()
    def self.maintenance()
        BladesItemised::mikuType("NxLongTask")
            .each{|delegate| 
                next if delegate["parent"].nil?
                if BladesGI::itemOrNull(delegate["parent"]["uuid"]).nil? then
                    BladesGI::setAttribute2(delegate["uuid"], "parent", nil)
                end
            }
    end

    # NxLongTasks::program1()
    def self.program1()
        loop {
            delegate = LucilleCore::selectEntityFromListOfEntitiesOrNull("delegate", BladesItemised::mikuType("NxLongTask"), lambda{|delegate| NxLongTasks::toString(delegate) })
            return if delegate.nil?
            PolyActions::access(delegate)
        }
    end

    # NxLongTasks::fsck()
    def self.fsck()
        BladesItemised::mikuType("NxLongTask").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end
end
