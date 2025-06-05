class TheZone

    # TheZone::recomputeFromZero()
    def self.recomputeFromZero()
        items = Listing::itemsForListing1()
        ValueCache::set("the-zone-items-a6e4-27582cbd9545", items)
        items.each{|item|
            ValueCache::destroy("item-template-string-bf21-82d828702e8a:#{item["uuid"]}")
        }
    end

    # TheZone::listingItems()
    def self.listingItems()
        items = ValueCache::getOrNull("the-zone-items-a6e4-27582cbd9545")
        if items.nil? then
            items = Listing::itemsForListing1()
            ValueCache::set("the-zone-items-a6e4-27582cbd9545", items)
        end

        items = items.map{|item|
            if item["nx0810"].nil? or item["nx0810"]["date"] != CommonUtils::today() then
                nx0810 = {
                    "date" => CommonUtils::today(),
                    "position" => rand * 10
                }
                item["nx0810"] = nx0810
                Items::setAttribute(item["uuid"], "nx0810", nx0810)
            end
            item
        }

        items = items.sort_by{|item| item["nx0810"]["position"] }
        items
    end

    # TheZone::removeItemFromTheZone(item)
    def self.removeItemFromTheZone(item)
        items = ValueCache::getOrNull("the-zone-items-a6e4-27582cbd9545")
        return if items.nil?
        items = items.reject{|i| i["uuid"] == item["uuid"] }
        ValueCache::set("the-zone-items-a6e4-27582cbd9545", items)
    end

    # TheZone::repositionItemInTheZone(itemuuid)
    def self.repositionItemInTheZone(itemuuid)
        item = Items::itemOrNull(itemuuid)
        return if item.nil?
        items = ValueCache::getOrNull("the-zone-items-a6e4-27582cbd9545")
        items = items || []
        items = items.map{|i|
            if i["uuid"] == item["uuid"] then
                item
            else
                i
            end
        }
        present = items.any?{|i| i["uuid"] == item["uuid"] }
        if !present then
            items = items.take(10) + [item] + items.drop(10)
        end
        ValueCache::set("the-zone-items-a6e4-27582cbd9545", items)
        ValueCache::destroy("item-template-string-bf21-82d828702e8a:#{item["uuid"]}")
    end

    # TheZone::toString3(item)
    def self.toString3(item)
        return nil if item.nil?
        hasChildren = PolyFunctions::hasChildren(item) ? " [children]".red : ""
        tx = ("%5.3f" % item["nx0810"]["position"]).ljust(5, "0").yellow
        line = "STORE-PREFIX (#{tx}) #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{DoNotShowUntil::suffix2(item)}#{hasChildren}"
        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end
        if NxBalls::itemIsActive(item) then
            line = line.green
        end
        line
    end

    # TheZone::itemToTemplateString(item)
    def self.itemToTemplateString(item)
        string = ValueCache::getOrNull("item-template-string-bf21-82d828702e8a:#{item["uuid"]}")
        return string if string
        string = TheZone::toString3(item)
        ValueCache::set("item-template-string-bf21-82d828702e8a:#{item["uuid"]}", string)
        string
    end

    # TheZone::itemToString(store, item)
    def self.itemToString(store, item)
        string = TheZone::itemToTemplateString(item)
        storePrefix = store ? "(#{store.prefixString()})" : "      "
        string.gsub("STORE-PREFIX", storePrefix)
    end
end
