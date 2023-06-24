
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

    # Pure::pure()
    def self.pure()
        listing = DarkEnergy::mikuType("NxEngine")
                    .select{|engine| DoNotShowUntil::isVisible(engine) }
                    .select{|engine| NxEngines::listingCompletionRatio(engine) < 1 }
                    .sort_by{|engine| NxEngines::listingCompletionRatio(engine) }
        listing = CommonUtils::putFirst(listing, lambda{|engine| NxBalls::itemIsRunning(engine) })

        return [] if listing.empty?

        loop {
            head = listing.first
            tail = listing.drop(1)
            children = Pure::childrenInitInRelevantOrder(head)
            return [head] + tail if children.empty?
            listing = children + [head] + tail
        }
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

    # Pure::bottom()
    def self.bottom()
        Memoize::evaluate("32ab7fb3-f85c-4fdf-aafe-9465d7db2f5f", lambda{
            puts "Computing Pure::bottom() ..."
            items = DarkEnergy::mikuType("NxTask")
                            .select{|task| task["parent"].nil? }
                            .select{|task| task["engine"].nil? }
                            .select{|task| task["deadline"].nil? }
                            .sort_by{|item| item["unixtime"] }
            (items.take(100) + items.reverse.take(100)).shuffle
        }, 86400)
            .select{|item| DarkEnergy::itemOrNull(item["uuid"]) }
            .compact
    end
end
