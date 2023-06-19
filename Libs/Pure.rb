
class Pure

    # Pure::childrenInitInRelevantOrder(item)
    def self.childrenInitInRelevantOrder(item)
        return [] if item["mikuType"] == "NxTask"

        if item["mikuType"] == "NxCore" then
            return NxCores::children(item)
                .select{|item| DoNotShowUntil::isVisible(item) }
                .select{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) < 3600*2 }
                .first(6)
        end

        if item["mikuType"] == "NxThread" then
            return NxThreads::childrenOrderedForListing(item)
                .select{|item| DoNotShowUntil::isVisible(item) }
                .select{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) < 3600*2 }
                .first(6)
        end

        if item["mikuType"] == "NxBurner" then
            return []
        end

        raise "I don't know how to Pure::childrenInitInRelevantOrder item #{item}"
    end

    # Pure::pure()
    def self.pure()
        listing = DarkEnergy::mikuType("NxCore")
                    .select{|core| DoNotShowUntil::isVisible(core) }
                    .select{|core| NxCores::listingCompletionRatio(core) < 1 }
                    .sort_by{|core| NxCores::listingCompletionRatio(core) }
        listing = CommonUtils::putFirst(listing, lambda{|core| NxBalls::itemIsRunning(core) })

        return [] if listing.empty?

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
            threads = DarkEnergy::mikuType("NxThread")
                            .select{|thread| thread["parent"].nil? }
            items = DarkEnergy::mikuType("NxTask")
                            .select{|task| task["parent"].nil? }
                            .select{|task| task["engine"].nil? }
                            .select{|task| task["deadline"].nil? }
                            .sort_by{|item| item["unixtime"] }
            (threads + items.take(100) + items.reverse.take(100)).shuffle
        }, 86400)
            .select{|item| DarkEnergy::itemOrNull(item["uuid"]) }
            .compact
    end
end
