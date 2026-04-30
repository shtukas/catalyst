
class Dispatch

    # Dispatch::deadline()
    def self.deadline()

        if Time.new.hour < 12 then
            return DateTime.parse("#{CommonUtils::today()}T12:00:00Z").to_time.to_i
        end

        if Time.new.hour < 18 then
            return DateTime.parse("#{CommonUtils::today()}T18:00:00Z").to_time.to_i
        end

        DateTime.parse("#{CommonUtils::today()}T21:00:00Z").to_time.to_i

    end

    # Dispatch::item_to_timespan(item)
    def self.item_to_timespan(item)

        if item["engine-1437"] then
            return NxEngines::missing_timespan_for_today(item)
        end

        if item["mikuType"] == "NxEngineDelegate" then
            return item["capacity"] - Bank::getValue(item["uuid"])
        end

        if item["dispatch:timespan"] then
            return item["dispatch:timespan"]
        end

        lastTimeAsked = XCache::getOrDefaultValue("fd15039e-0c31-4ef6-b558-a8b0e72cde47", "0").to_i
        if (Time.new.to_i - lastTimeAsked) < 60 then
            return 300
        end

        timespan = LucilleCore::askQuestionAnswerAsString("dispatch timespan for #{PolyFunctions::toString(item)} in minutes ? ").to_f
        timespan = timespan * 60
        Items::setAttribute(item["uuid"], "dispatch:timespan", timespan)

        XCache::set("fd15039e-0c31-4ef6-b558-a8b0e72cde47", Time.new.to_i)

        timespan
    end

    # Dispatch::itemType(item)
    def self.itemType(item)
        # This function takes an item and return one of the following types
        # "priority"
        # "today"
        # "leisure"
        # The priority elements are always displayed first
        # We display as many leisure elements we can as long as it doesn't push the last 
        # today element after 18:00

        return "priority" if item["mikuType"] == "DesktopTx1"
        return "priority" if item["mikuType"] == "Anniversary"
        return "priority" if (item["mikuType"] == "Wave" and item["priority"])
        return "priority" if item["mikuType"] == "NxNotification"
        return "priority" if item["mikuType"] == "NxCounter"

        return "today" if (item["mikuType"] == "NxOndate" and (item["today-absolute"] == CommonUtils::today()))
        return "today" if (item["engine-1437"] and (NxEngines::ratio(item) < 1))
        return "today" if item["mikuType"] == "NxEngineDelegate"
        return "today" if item["mikuType"] == "NxBackup"

        return "leisure" if item["mikuType"] == "NxOndate"
        return "leisure" if item["mikuType"] == "BufferIn"
        return "leisure" if item["mikuType"] == "NxTask"
        return "leisure" if item["mikuType"] == "Wave"

        raise "[error: a6135fae] I do not know how to itemType: #{item}"
    end

    # Dispatch::decide_scoring(items)
    def self.decide_scoring(items)

        # return:
        #   ["[today/leisure]:not-found"]
        #   ["overflowing", <datetime>]
        #   ["score", <score>]

        cursor = Time.new.to_i

        struct1 = items.map{|item|
            cursor = cursor + Dispatch::item_to_timespan(item)
            {
                "item" => item,
                "time" => cursor
            }
        }

        extractUpToTheLastToday = lambda {|struct1|
            return [] if struct1.empty?
            return struct1 if (Dispatch::itemType(struct1.last["item"]) == "today")
            struct1 = struct1.take(struct1.length - 1)
            extractUpToTheLastToday.call(struct1)
        }

        struct1 = extractUpToTheLastToday.call(struct1)

        return ["[today/leisure]:not-found"] if struct1.empty?

        return ["overflowing", Time.at(struct1.last["time"]).to_s] if Time.at(struct1.last["time"]).to_i > Dispatch::deadline()

        score = struct1.map{|packet| packet["item"] }.select{|item| Dispatch::itemType(item) == "leisure" }.size

        ["score", score]
    end

    # Dispatch::dispatch(items)
    def self.dispatch(items) # items -> items

        # ----------------------------------------------------------
        # First we ensure that all items have a dispatch:position attribute
        items = items.map.with_index{|item, index|
            if item["dispatch:position"].nil? then
                item["dispatch:position"] = rand
                Items::setAttribute(item["uuid"], "dispatch:position", item["dispatch:position"])
            end
            item
        }

        # We sort them by that attribute
        items = items.sort_by{|item| item["dispatch:position"] }

        priorityItems, todayOrLeisureItems = items.partition{|item| Dispatch::itemType(item) == "priority" }

        # Then we optimize todayOrLeisureItems
        priorityItems + Dispatch::optimize(todayOrLeisureItems)
    end

    # Dispatch::optimize(todayOrLeisureItems)
    def self.optimize(todayOrLeisureItems)

        if !Config::isPrimaryInstance() then
            return todayOrLeisureItems
        end

        getMinDispatchPosition = lambda {|items| (items.map{|item| item["dispatch:position"] } + [0]).min }

        getMaxDispatchPosition = lambda {|items| (items.map{|item| item["dispatch:position"] } + [1]).max }

        getNewDispatchPositionInFirstQuarter = lambda {|items|
            a = getMinDispatchPosition.call(items)
            b = getMaxDispatchPosition.call(items)
            a + rand * 0.25*(b-a)
        }

        # Here we only have "today" or "leisure"

        scoring = Dispatch::decide_scoring(todayOrLeisureItems)

        puts JSON.generate(scoring).yellow

        if scoring[0] == "[today/leisure]:not-found" then
            puts "all good, we only have priority items".yellow
            # All good, we only have priority items
            return todayOrLeisureItems
        end

        if scoring[0] == "overflowing" then
            # We are overflowing, let's reduce the dispatch:position of every today item
            todayitems, leisureItems = todayOrLeisureItems.partition{|item| Dispatch::itemType(item) == "today" }
            return leisureItems if todayitems.empty?
            lastTodayItem = todayitems.last
            todayItemsMinusSelected = todayitems.select{|item| item["uuid"] != lastTodayItem["uuid"] }
            puts "repositioning '#{PolyFunctions::toString(lastTodayItem)}' to #{lastTodayItem["dispatch:position"]}".yellow
            lastTodayItem["dispatch:position"] = getNewDispatchPositionInFirstQuarter.call(todayOrLeisureItems)
            Items::setAttribute(lastTodayItem["uuid"], "dispatch:position", lastTodayItem["dispatch:position"])
            return (todayItemsMinusSelected + [lastTodayItem] + leisureItems).sort_by{|item| item["dispatch:position"] }
        end

        if scoring[0] == "score" then
            score = scoring[1]

            # We select a leisure item (we could take the last one)
            # We give it a random dispatch:position, and check the score again
            # If the score has increased we keep the change (we commit the new value)
            # If the score has not increased we return the items as we found them

            todayitems, leisureItems = todayOrLeisureItems.partition{|item| Dispatch::itemType(item) == "today" }
            return todayitems if leisureItems.empty?
            lastLeisureItem = leisureItems.last
            leisureItemsWithoutTheSelectedOne = leisureItems.select{|item| item["uuid"] != lastLeisureItem["uuid"] }

            # We have the item, and the list without it.
            # Now, we mark the item and make a new list

            lastLeisureItem["dispatch:position"] = getNewDispatchPositionInFirstQuarter.call(todayOrLeisureItems)
            modifiedTodayOrLeisureItemsInOrder = (todayitems + leisureItemsWithoutTheSelectedOne + [lastLeisureItem]).sort_by{|item| item["dispatch:position"] }

            modifiedScoring = Dispatch::decide_scoring(modifiedTodayOrLeisureItemsInOrder)

            if modifiedScoring[0] == "score" and modifiedScoring[1] > score then
                puts "improved scoring from #{score} to #{modifiedScoring[1]}".yellow
                puts "repositioning '#{PolyFunctions::toString(lastLeisureItem)}' to #{lastLeisureItem["dispatch:position"]}".yellow
                Items::setAttribute(lastLeisureItem["uuid"], "dispatch:position", lastLeisureItem["dispatch:position"])
                return modifiedTodayOrLeisureItemsInOrder
            end

            # otherwise we return todayOrLeisureItems
            puts "no improvment in the scoring".yellow
            return todayOrLeisureItems.sort_by{|item| item["dispatch:position"] }
        end

        raise "[2821ee87] how did this happen ? 🤔"
    end
end
