
class Pure

    # Pure::childrenInitInRelevantOrder(item)
    def self.childrenInitInRelevantOrder(item)
        return (NxStacks::stack(item) + [item]) if item["mikuType"] == "NxTask"

        if item["mikuType"] == "NxCore" then
            return NxCores::children(item)
                .select{|item| DoNotShowUntil::isVisible(item) }
                .select{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) < 3600*2 }
                .first(6)
        end

        if item["mikuType"] == "NxSequence" then
            return NxSequences::children_ordered(item)
                .select{|item| DoNotShowUntil::isVisible(item) }
                .select{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) < 3600*2 }
                .first(6)
        end

        raise "don't know how to children item #{item}"
    end

    # Pure::pure()
    def self.pure()
        listing = DarkEnergy::mikuType("NxCore")
                    .select{|core| DoNotShowUntil::isVisible(core) }
                    .select{|core| NxCores::listingCompletionRatio(core) < 1 }
                    .sort_by{|core| NxCores::listingCompletionRatio(core) }
        return [] if listing.empty?
        head = Pure::childrenInitInRelevantOrder(listing.first)
        listing = head + listing
        head = Pure::childrenInitInRelevantOrder(listing.first)
        listing = head + listing
        listing
    end

    # Pure::bottom()
    def self.bottom()
        Memoize::evaluate("32ab7fb3-f85c-4fdf-aafe-9465d7db2f5f", lambda{
            sequences = DarkEnergy::mikuType("NxSequence")
                            .select{|sequence| sequence["core"].nil? }
            items = DarkEnergy::mikuType("NxTask")
                            .select{|task| task["core"].nil? }
                            .select{|task| task["engine"].nil? }
                            .select{|task| task["deadline"].nil? }
                            .select{|task| task["sequence"].nil? }
                            .sort_by{|item| item["unixtime"] }
            (sequences + items.take(100) + items.reverse.take(100)).shuffle
        }, 86400)
            .select{|item| DarkEnergy::itemOrNull(item["uuid"]) }
            .compact
    end
end
