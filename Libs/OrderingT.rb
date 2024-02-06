
class OrderingT

    # OrderingT::ratio(item)
    def self.ratio(item)
        # For engined items, the ratio is the TxEngines listing completion ratio
        # For waves, notably regular non interruption waves, the ratio is randomly determined 
        # (that ratio is kept in the instance's own XCache, so is varying from one
        # instance to another)

        if item["mikuType"] == "NxOrbital" then
            return TxEngines::listingCompletionRatio(item["engine-0020"])
        end

        if item["mikuType"] == "NxRingworldMission" then
            return NxRingworldMissions::ratio()
        end

        if item["mikuType"] == "NxSingularNonWorkQuest" then
            return NxSingularNonWorkQuests::ratio()
        end

        raise "(error: fbffdec2-1fde-4fe4-b072-524ff49ca935): #{item}"
    end

    # OrderingT::apply(items)
    def self.apply(items)
        items.sort_by{|item| OrderingT::ratio(item) }
    end
end
