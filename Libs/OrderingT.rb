
class OrderingT

    # OrderingT::getXcacheRatio(item)
    def self.getXcacheRatio(item)
        ratio = XCache::getOrNull("6209434d-a57d-42bd-ad34-44b515999db0:#{item["uuid"]}")
        if ratio then
            return ratio.to_f
        end
        ratio = rand
        XCache::set("6209434d-a57d-42bd-ad34-44b515999db0:#{item["uuid"]}", ratio)
        ratio
    end

    # OrderingT::ratio(item)
    def self.ratio(item)
        # For engined items, the ratio is the TxCores listing completion ratio
        # For waves, notably regular non interruption waves, the ratio is randomly determined 
        # (that ratio is kept in the instance's own XCache, so is varying from one
        # instance to another)

        if item["mikuType"] == "NxTodo" then
            if item["engine-0020"] then
                return TxCores::listingCompletionRatio(item["engine-0020"])
            else
                return Bank2::recoveredAverageHoursPerDay(item["uuid"]).to_f/NxTodos::basicHoursPerDayForProjectsWithoutEngine()
            end
        end

        if item["mikuType"] == "NxOrbital" then
            return TxCores::listingCompletionRatio(item["engine-0020"])
        end

        if item["mikuType"] == "NxRingworldMission" then
            return Bank2::recoveredAverageHoursPerDay("3413fd90-cfeb-4a66-af12-c1fc3eefa9ce").to_f/NxRingworldMissions::recoveryTimeControl()
        end

        if item["mikuType"] == "NxSingularNonWorkQuest" then
            return Bank2::recoveredAverageHoursPerDay("043c1f2e-3baa-4313-af1c-22c4b6fcb33b").to_f/NxSingularNonWorkQuests::recoveryTimeControl()
        end

        if item["engine-0020"] then
            return TxCores::listingCompletionRatio(item["engine-0020"])
        end

        if item["mikuType"] == "Wave" then
            return OrderingT::getXcacheRatio(item)
        end

        if item["mikuType"] == "UxCore" then
            return 0.5 + 0.5*TxCores::dayCompletionRatio(item)
        end

        raise "(error: fbffdec2-1fde-4fe4-b072-524ff49ca935): #{item}"
    end

    # OrderingT::muiItems()
    def self.muiItems()
        items1 = NxTodos::muiItems()
        items2 = NxOrbitals::muiItems()
        items3 = NxRingworldMissions::muiItems()
        items4 = Cubes2::items()
                    .select{|item| item["engine-0020"] }
                    .select{|item| item["mikuType"] != "NxTodo" }
                    .select{|item| item["mikuType"] != "NxOrbital" }
                    .select{|item| TxCores::listingCompletionRatio(item["engine-0020"]) < 1 }
        items5 = Waves::muiItems().select{|item| !item["interruption"] }
        items6 = Cubes2::mikuType("UxCore")
        items7 = NxSingularNonWorkQuests::muiItems()

        (items1 + items2 + items3 + items4 + items5 + items6 + items7).sort_by{|item| OrderingT::ratio(item) }
    end
end
