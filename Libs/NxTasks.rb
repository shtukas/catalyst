

$memory1503 = nil

class NxTasks

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "payload-37", UxPayloads::makeNewPayloadOrNull())
        Items::setAttribute(item["uuid"], "parenting-13", {
            "parentuuid" => nil,
            "position"   => Orphan::lastPositionAmongOrphans() + 1
        })
        Items::setAttribute(uuid, "mikuType", "NxTask")
        item = Items::itemOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # ----------------------
    # Data

    # NxTasks::icon()
    def self.icon()
        "🔹"
    end

    # NxTasks::toString(item)
    def self.toString(item)
        ps = item["parenting-13"] ? "(#{"%7.3f" % item["parenting-13"]["position"]}) ".yellow : ""
        "#{NxTasks::icon()} #{ps}#{item["description"]}#{Parenting::suffix(item)}"
    end
end
