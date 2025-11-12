
class NxPolymorphs

    # --------------------------------------
    # Issue

    # NxPolymorphs::issueNew(uuid, description, behaviour, payload or null)
    def self.issueNew(uuid, description, behaviour, payload)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "bx42", behaviour)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "mikuType", "NxPolymorph")
        item = Items::itemOrNull(uuid)
        Fsck::fsckOrError(item)
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

    # NxPolymorphs::doNotShowUntil(item, unixtime)
    def self.doNotShowUntil(item, unixtime)
        Items::setAttribute(item["uuid"], "do-not-show-until-51", Time.at(unixtime).utc.iso8601)
    end

    # NxPolymorphs::stop(item)
    def self.stop(item)
        Nx41::delist(item)
        Items::itemOrNull(item["uuid"])
    end

    # NxPolymorphs::done(item)
    def self.done(item)
        packet = TxBehaviour::done(item["bx42"]) # null or { "behaviour" => behaviour, "do-not-show-until" => unixtime }
        if packet then
            Nx41::delist(item)
            Items::setAttribute(item["uuid"], "do-not-show-until-51", Time.at(packet["do-not-show-until"]).utc.iso8601)
            Items::setAttribute(item["uuid"], "bx42", packet["behaviour"])
        else
            if LucilleCore::askQuestionAnswerAsBoolean("confirm destroy '#{PolyFunctions::toString(item).green}': ") then
                Items::deleteItem(item["uuid"])
            end
        end
    end
end
