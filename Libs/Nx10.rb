class Nx10
    # Nx10::itemsForListing2()
    def self.itemsForListing2()
        items = Listing::itemsForListing1()
        items = Prefix::addPrefix(items)
        items = items.take(10) + NxBalls::activeItems() + items.drop(10)
        items = items
            .reduce([]){|selected, item|
                if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }
        items = items.take(CommonUtils::screenHeight()-5)
        items
    end

    # Nx10::removeItemFromCache(uuid)
    def self.removeItemFromCache(uuid)
        data = JSON.parse(XCache::getOrDefaultValue("a703683f-764f-47fb-ba9c-bf1f154490e3", "[]"))
        data = data.reject{|packet| packet["item"]["uuid"] == uuid }
        XCache::set("a703683f-764f-47fb-ba9c-bf1f154490e3", JSON.generate(data))
    end

    # Nx10::refreshItemInCache(uuid)
    def self.refreshItemInCache(uuid)
        data = JSON.parse(XCache::getOrDefaultValue("a703683f-764f-47fb-ba9c-bf1f154490e3", "[]"))
        data = data.map{|packet|
            if packet["item"]["uuid"] == uuid then
                item = Items::itemOrNull(uuid)
                if item then
                    packet["item"] = item
                    packet
                else
                    nil
                end
            else
                packet
            end
        }
        .compact
        XCache::set("a703683f-764f-47fb-ba9c-bf1f154490e3", JSON.generate(data))
    end

    # Nx10::makeAndPublishNx10()
    def self.makeAndPublishNx10()
        store = ItemStore.new()
        items = Nx10::itemsForListing2()
        data = items
                .map{|item|
                    store.register(item, Listing::canBeDefault(item))
                    line = Listing::toString2(store, item)
                    {
                        "item" => item,
                        "line" => line
                    }
                }
        XCache::set("a703683f-764f-47fb-ba9c-bf1f154490e3", JSON.generate(data))
    end

    # Nx10::getNx10FromCache()
    def self.getNx10FromCache()
        JSON.parse(XCache::getOrDefaultValue("a703683f-764f-47fb-ba9c-bf1f154490e3", "[]"))
    end
end
