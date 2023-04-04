
class NxTimeTargets

    # NxTimeTargets::items()
    def self.items()
        N3Objects::getMikuType("NxTimeTarget")
    end

    # NxTimeTargets::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxTimeTargets::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # NxTimeTargets::issue(description, timeInHours)
    def self.issue(description, timeInHours)
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTimeTarget",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "timeInHours" => timeInHours
        }
        puts JSON.pretty_generate(item)
        NxTimeTargets::commit(item)
        item = BoardsAndItems::askAndMaybeAttach(item)
        item
    end

    # NxTimeTargets::listingItems()
    def self.listingItems()
        NxTimeTargets::items()
            .map{|item|
                if !NxBalls::itemIsRunning(item) and BankCore::getValue(item["uuid"]) > item["timeInHours"]*3600 then
                    NxTimeTargets::destroy(item["uuid"])
                    nil
                else
                    item
                end
            }
            .compact
    end

    # NxTimeTargets::toString(item)
    def self.toString(item)
        doneInHours = BankCore::getValue(item["uuid"]).to_f/3600 + NxBalls::runningTime(item).to_f/3600
        "(time target) #{item["description"]} (done: #{doneInHours.round(2)}, remaining: #{(item["timeInHours"] - doneInHours).round(2)})"
    end
end