
class OrderingT

    # OrderingT::ratio(item)
    def self.ratio(item)
        # For engined items, the ratio is the TxEngines listing completion ratio
        # For waves, notably regular non interruption waves, the ratio is randomly determined 
        # (that ratio is kept in the instance's own XCache, so is varying from one
        # instance to another)

        if item["mikuType"] == "NxTodo" then
            if item["engine-0020"] then
                return TxEngines::listingCompletionRatio(item["engine-0020"])
            else
                return Bank2::recoveredAverageHoursPerDay(item["uuid"]).to_f/NxTodos::basicHoursPerDayForProjectsWithoutEngine()
            end
        end

        if item["mikuType"] == "NxOrbital" then
            return TxEngines::listingCompletionRatio(item["engine-0020"])
        end

        if item["mikuType"] == "NxRingworldMission" then
            return Bank2::recoveredAverageHoursPerDay("3413fd90-cfeb-4a66-af12-c1fc3eefa9ce").to_f/NxRingworldMissions::recoveryTimeControl()
        end

        if item["mikuType"] == "NxSingularNonWorkQuest" then
            return Bank2::recoveredAverageHoursPerDay("043c1f2e-3baa-4313-af1c-22c4b6fcb33b").to_f/NxSingularNonWorkQuests::recoveryTimeControl()
        end

        if item["engine-0020"] then
            return TxEngines::listingCompletionRatio(item["engine-0020"])
        end

        if item["mikuType"] == "TxTimeCore" then
            return 0.5 + 0.5*TxEngines::dayCompletionRatio(item)
        end

        raise "(error: fbffdec2-1fde-4fe4-b072-524ff49ca935): #{item}"
    end

    # OrderingT::apply(items)
    def self.apply(items)
        items.sort_by{|item| OrderingT::ratio(item) }
    end
end
