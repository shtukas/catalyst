=begin

Listing: Array[Nx45]

Nx45:
    - trace: string
    - item : item

=end

class Listing

    # Listing::get()
    def self.get()
        JSON.parse(XCache::getOrDefaultValue("2dea29de-dd57-4630-937e-4e3fd1af8cb5", "[]"))
    end

    # Listing::store(listing)
    def self.store(listing)
        XCache::set("2dea29de-dd57-4630-937e-4e3fd1af8cb5", JSON.generate(listing))
    end

    # Listing::trace(item)
    def self.trace(item)
        if item["mikuType"] == "NxRingworldMission" then
            return "#{item["uuid"]}:#{Bank2::getValue(item["uuid"])}"
        end
        if item["mikuType"] == "NxSingularNonWorkQuest" then
            return "#{item["uuid"]}:#{Bank2::getValue(item["uuid"])}"
        end
        if item["mikuType"] == "NxBufferInMonitor" then
            return "#{item["uuid"]}:#{Bank2::getValue(item["uuid"])}"
        end
        if item["mikuType"] == "NxTodo" then
            return "#{item["uuid"]}:#{Bank2::getValue(item["uuid"])}"
        end
        if item["mikuType"] == "NxOndate" then
            return "#{item["uuid"]}:#{Bank2::getValue(item["uuid"])}"
        end
        item["uuid"]
    end

    # Listing::insertionRatio(item)
    def self.insertionRatio(item)
        if item["mikuType"] == "NxAnniversary" then
            return 0.1
        end
        if item["mikuType"] == "Wave" and item["interruption"] then
            return 0.1
        end
        if item["mikuType"] == "Wave" and !item["interruption"] then
            return 1
        end
        if item["mikuType"] == "NxOndate" then
            return 0.2
        end
        if item["mikuType"] == "PhysicalTarget" then
            return 0.2
        end
        if item["mikuType"] == "NxBackup" then
            return 1
        end
        if item["mikuType"] == "NxFloat" then
            return 1
        end
        if item["mikuType"] == "NxRingworldMission" then
            return NxRingworldMissions::ratio()
        end
        if item["mikuType"] == "NxSingularNonWorkQuest" then
            return NxSingularNonWorkQuests::ratio()
        end
        if item["mikuType"] == "NxBufferInMonitor" then
            return NxBufferInMonitors::ratio()
        end
        if item["mikuType"] == "NxTodo" then
            return NxTodos::listingRatio(item)
        end
        raise "(error: d255e0e1) could not determine Listing::insertionRatio for #{item}"
    end

    # Listing::insert(listing, item, trace, iratio)
    def self.insert(listing, item, trace, iratio)
        cut = listing.size * iratio
        nx45 = {
            "trace" => trace,
            "item"  => item
        }
        listing.take(cut) + [nx45] + listing.drop(cut)
    end

    # Listing::apply(items)
    def self.apply(items)
        listing = Listing::get()
        listing = listing.map{|nx45|
            nx45["item"] = nil
            nx45
        }
        items.each{|item|
            trace = Listing::trace(item)
            hasBeenPositioned = false
            listing = listing.map{|nx45|
                if nx45["trace"] == trace then
                    nx45["item"] = item
                    hasBeenPositioned = true
                end
                nx45
            }
            if !hasBeenPositioned then
                iratio = Listing::insertionRatio(item)
                listing = Listing::insert(listing, item, trace, iratio)
            end
        }
        listing = listing.select{|nx45|
            nx45["item"]
        }
        Listing::store(listing)
        listing.map{|nx45| nx45["item"] }.compact
    end

    # Listing::rotate()
    def self.rotate()
        listing = Listing::get()
        listing = listing.drop(1) + listing.take(1)
        Listing::store(listing)
    end

end
