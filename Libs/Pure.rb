
class Pure

    # Pure::childrenInitInRelevantOrder(item)
    def self.childrenInitInRelevantOrder(item)
        Tx8s::childrenInOrder(item)
            .reduce([]){|selected, item|
                if selected.size >= 6 then
                    selected
                else
                    b1 = DoNotShowUntil::isVisible(item) and (Bank::recoveredAverageHoursPerDay(item["uuid"]) < 3600*2)
                    b2 = NxBalls::itemIsRunning(item)
                    if b1 or b2 then
                        selected + [item]
                    else
                        selected
                    end
                end
            }
            .select{|item| DoNotShowUntil::isVisible(item) }
            .select{|item| NxBalls::itemIsRunning(item) or (Bank::recoveredAverageHoursPerDay(item["uuid"]) < 3600*2) }
            .first(6)
    end

    # Pure::pureFromItem(item)
    def self.pureFromItem(item)
        listing = [item]
        loop {
            head = listing.first
            tail = listing.drop(1)
            children = Pure::childrenInitInRelevantOrder(head)
            return [head] + tail if children.empty?
            listing = children + [head] + tail
        }
    end

    # Pure::energy()
    def self.energy()
        listing = DarkEnergy::mikuType("TxCore")
                    .select{|core| DoNotShowUntil::isVisible(core) }
                    .sort_by{|core| TxCores::dayCompletionRatio(core) }

        return [] if listing.empty?

        loop {
            head = listing.first
            tail = listing.drop(1)
            children = Pure::childrenInitInRelevantOrder(head)
            return [head] + tail if children.empty?
            listing = children + [head] + tail
        }
    end
end
