
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

    # Pure::energy()
    def self.energy()
        listing1 = DarkEnergy::mikuType("TxCore")
                    .select{|core| DoNotShowUntil::isVisible(core) }
                    .sort_by{|core| TxCores::dayCompletionRatio(core) }

        listing2 = DarkEnergy::mikuType("NxBox")
                    .sort_by{|thread| Bank::recoveredAverageHoursPerDay(thread["uuid"]) }

        listing = listing1 + listing2

        return [] if listing.empty?

        listing = CommonUtils::putFirst(listing, lambda{|thread| NxBalls::itemIsRunning(thread) })

        loop {
            head = listing.first
            tail = listing.drop(1)
            children = Pure::childrenInitInRelevantOrder(head)
            return [head] + tail if children.empty?
            listing = children + [head] + tail
        }
    end
end
