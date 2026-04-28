
class Dispatch

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
        return "priority" if item["mikuType"] == "Wave"
        return "priority" if item["mikuType"] == "NxNotification"
        return "priority" if item["mikuType"] == "NxCounter"

        return "today" if (item["mikuType"] == "NxOndate" and (item["today-absolute"] == CommonUtils::today()))
        return "today" if (item["engine-1437"] and (NxEngines::ratio(item) < 1))
        return "today" if item["mikuType"] == "NxEngineDelegate"
        return "today" if item["mikuType"] == "NxBackup"

        return "leisure" if item["mikuType"] == "NxOndate"
        return "leisure" if item["mikuType"] == "BufferIn"
        return "leisure" if item["mikuType"] == "NxTask"

        raise "[error: a6135fae] I do not know how to itemType: #{item}"
    end

    # Dispatch::decide_scoring(items)
    def self.decide_scoring(items)

        # return:
        #   ["[today/leisure]:not-found"]
        #   ["overflowing"]
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
            return struct1 if (Dispatch::itemType(struct1.last["item"]) == "today" or Dispatch::itemType(struct1.last["item"]) == "leisure")
            struct1 = struct1.take(struct1.length - 1)
            extractUpToTheLastToday.call(struct1)
        }

        struct1 = extractUpToTheLastToday.call(struct1)

        return ["[today/leisure]:not-found"] if struct1.empty?

        return ["overflowing"] if Time.at(struct1.last["time"]).to_s[0, 10] != CommonUtils::today() # We are overflowing past midnight

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

        # Here we only have "today" or "leisure"

        scoring = Dispatch::decide_scoring(todayOrLeisureItems)

        puts JSON.generate(scoring).yellow

        if scoring[0] == "[today/leisure]:not-found" then
            puts "all good, we only have priority items".yellow
            # All good, we only have priority items
        end

        if scoring[0] == "overflowing" then
            puts "overflowing".yellow
            # We are overflowing, let's reduce the dispatch:position of every today item
            todayOrLeisureItems = todayOrLeisureItems.map{|item|
                if Dispatch::itemType(item) == "today" then
                    item["dispatch:position"] = 0.8 * item["dispatch:position"]
                    Items::setAttribute(item["uuid"], "dispatch:position", item["dispatch:position"])
                end
                item
            }
            return todayOrLeisureItems
        end

        # Here the scoring is ["score", score]

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

        lastLeisureItem["dispatch:position"] = 0.5 * lastLeisureItem["dispatch:position"]
        modifiedTodayOrLeisureItemsInOrder = (todayitems + leisureItemsWithoutTheSelectedOne + [lastLeisureItem]).sort_by{|item| item["dispatch:position"] }

        modifiedScoring = Dispatch::decide_scoring(modifiedTodayOrLeisureItemsInOrder)

        if modifiedScoring[0] == "score" and modifiedScoring[1] > score then
            puts "improved scoring from #{score} to #{modifiedScoring[1]}".yellow
            puts "the dispatch:position of #{PolyFunctions::toString(lastLeisureItem)} is now #{lastLeisureItem["dispatch:position"]}"
            # We commit the modification that improved the score
            Items::setAttribute(lastLeisureItem["uuid"], "dispatch:position", lastLeisureItem["dispatch:position"])
            return modifiedTodayOrLeisureItemsInOrder
        end

        # otherwise we return todayOrLeisureItems
        puts "no improvment in the scoring".yellow
        todayOrLeisureItems
    end
end
