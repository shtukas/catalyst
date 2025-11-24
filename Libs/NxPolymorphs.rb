
class NxPolymorphs

    # --------------------------------------
    # Issue

    # NxPolymorphs::issueNew(uuid, description, behaviour, payload or null)
    def self.issueNew(uuid, description, behaviour, payload)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "bx42", behaviour)
        Items::setAttribute(uuid, "payload-uuid-1141", payload ? payload["uuid"] : nil)
        Items::setAttribute(uuid, "mikuType", "NxPolymorph")
        item = Items::itemOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # --------------------------------------
    # Data

    # NxPolymorphs::toString(item)
    def self.toString(item)
        icon = TxBehaviour::behaviourToIcon(item["bx42"])
        runningTimespan = (lambda{
            nxball = NxBalls::getNxBallOrNull(item)
            return 0 if nxball.nil?
            NxBalls::ballRunningTime(nxball)
        }).call()
        "#{icon} #{TxBehaviour::behaviourToDescriptionLeft(item["bx42"])}#{item["description"]}#{TxBehaviour::behaviourToDescriptionRight(item["bx42"], runningTimespan)}"
    end

    # --------------------------------------
    # Ops

    # NxPolymorphs::stop(item)
    def self.stop(item)
        Items::setAttribute(item["uuid"], "nx41", nil)
        Items::itemOrNull(item["uuid"])
    end

    # NxPolymorphs::done(item)
    def self.done(item)
        packet = TxBehaviour::done(item["bx42"]) # null or { "behaviour" => behaviour, "do-not-show-until" => unixtime }
        if packet then
            Items::setAttribute(item["uuid"], "nx41", nil)
            Items::setAttribute(item["uuid"], "do-not-show-until-51", Time.at(packet["do-not-show-until"]).utc.iso8601)
            Items::setAttribute(item["uuid"], "bx42", packet["behaviour"])
        else
            if LucilleCore::askQuestionAnswerAsBoolean("confirm destroy '#{PolyFunctions::toString(item).green}': ") then
                Items::deleteObject(item["uuid"])
            end
        end
    end
end
