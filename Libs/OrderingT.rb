
class OrderingT

    # OrderingT::getXcacheRatioOrNull(item)
    def self.getXcacheRatioOrNull(item)
        ratio = XCache::getOrNull("6209434d-a57d-42bd-ad34-44b515999db0:#{CommonUtils::today()}:#{item["uuid"]}")
        return nil if ratio.nil?
        ratio.to_f
    end

    # OrderingT::getXcacheRatio(item)
    def self.getXcacheRatio(item)
        ratio = OrderingT::getXcacheRatioOrNull(item)
        return ratio if ratio
        ratio = rand
        XCache::set("6209434d-a57d-42bd-ad34-44b515999db0:#{CommonUtils::today()}:#{item["uuid"]}", ratio)
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

    # OrderingT::getWaves()
    def self.getWaves()

        getI2 = lambda { |collection|
            i1s = []
            collection.each_with_index{|item, indx|
                if item["ratio"].nil? then
                    i1s << indx
                end
            }
            i1s[i1s.size/2] # getting one in the middle
        }

        getI1 = lambda { |collection, i2|
            i1 = i2 - 1
            loop {
                return i1 if collection[i1]["ratio"]
                i1 = i1 - 1
            }
        }

        getI3 = lambda { |collection, i2|
            i3 = i2 + 1
            loop {
                return i3 if collection[i3]["ratio"]
                i3 = i3 + 1
            }
        }

        waves = Waves::muiItems().select{|item| !item["interruption"] }
        # waves are coming in last done datetime, we can attribute random ratios,
        # but they need to maintain that ordering and they need to also be as
        # distributed as possible.
        # wavesxp { wave, ratio | null }

        collection = waves.map{|wave| {"wave" => wave, "ratio" => OrderingT::getXcacheRatioOrNull(wave)} }
        collection = [{"wave" => nil, "ratio" => 0}] + collection + [{"wave" => nil, "ratio" => 1}]
        loop {
            if collection.all?{|xp| xp["ratio"] } then
                return collection.map{|xp| xp["wave"] }.compact
            end
            i2 = getI2.call(collection)
            i1 = getI1.call(collection, i2)
            i3 = getI3.call(collection, i2)
            ratio = 0.5*(collection[i1]["ratio"]+collection[i3]["ratio"])
            wave = collection[i2]["wave"]
            XCache::set("6209434d-a57d-42bd-ad34-44b515999db0:#{CommonUtils::today()}:#{wave["uuid"]}", ratio)
            collection[i2]["ratio"] = ratio
        }
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
        items5 = OrderingT::getWaves()
        items6 = Cubes2::mikuType("UxCore")
        items7 = NxSingularNonWorkQuests::muiItems()

        (items1 + items2 + items3 + items4 + items5 + items6 + items7).sort_by{|item| OrderingT::ratio(item) }
    end
end
