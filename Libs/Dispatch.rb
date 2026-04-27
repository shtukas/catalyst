
class Dispatch

    # Dispatch::item_to_timespan(item)
    def self.item_to_timespan(item)
        300
    end

    # Dispatch::isImportantForToday(item)
    def self.isImportantForToday(item)
        return true if (item["mikuType"] == "NxOndate" and (item["today-absolute"] == CommonUtils::today()))
        return true if (item["engine-1437"] and (NxEngines::ratio(item) < 1))
        return true if item["mikuType"] == "NxEngineDelegate"
        false
    end

    # Dispatch::score(items)
    def self.score(items)
        cursor = Time.new.to_i

        struct1 = items.map{|item|
            cursor = cursor + Dispatch::item_to_timespan(item)
            {
                "item" => item,
                "time" => cursor
            }
        }

        extractRelevantSection = lambda {|struct1|
            return [] if struct1.empty?
            return struct1 if Dispatch::isImportantForToday(struct1.last["item"])
            struct1 = struct1.take(struct1.length - 1)
            extractRelevantSection.call(struct1)
        }

        struct1 = extractRelevantSection.call(struct1)

        return 0 if Time.at(struct1.last["time"]) != CommonUtils::today() # We are overflowing past midnight

        struct1.map{|packet| packet["item"] }.select{|item| item["mikuType"] == "Wave" }.size
    end

    # Dispatch::optimize(items)
    def self.optimize(items)
        return [] if items.empty?
        best_score = Dispatch::score(items)
        updated = false
        10.times {
            xitems = items.clone().shuffle
            score = Dispatch::score(xitems)
            if score > best_score then
                puts "improving the score from #{best_score} to #{score}"
                LucilleCore::pressEnterToContinue()
                best_score = score
                items = xitems
                updated = true
            end
        }
        if updated then
            items.each_with_index{|item, index|
                Items::setAttribute(item["uuid"], "dispatch50", index)
            }
        end
        if best_score == 0 then
            i1s, i2s = items.partition{|item| Dispatch::isImportantForToday(item) }
            items = i1s + i2s
        end
        items
    end

    # Dispatch::dispatch(items)
    def self.dispatch(items) # items -> items
        items = items.sort_by{|item| item["dispatch50"] }
        Dispatch::optimize(items)
    end
end
