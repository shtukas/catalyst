

$memory1503 = nil

class NxTasks

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Blades::init(uuid)
        BladesFront::setAttribute(uuid, "unixtime", Time.new.to_i)
        BladesFront::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        BladesFront::setAttribute(uuid, "description", description)
        BladesFront::setAttribute(uuid, "payload-37", UxPayloads::makeNewPayloadOrNull(uuid))
        BladesFront::setAttribute(uuid, "parenting-13", {
            "parentuuid" => nil,
            "position"   => Orphans::lastPositionAmongOrphans() + 1
        })
        BladesFront::setAttribute(uuid, "mikuType", "NxTask")
        item = Blades::itemOrNull(uuid)
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
