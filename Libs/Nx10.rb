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
                    packet = {
                        "item" => item,
                        "line" => Nx10::toString3(item)
                    }
                    puts JSON.pretty_generate(packet)
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
        items = Nx10::itemsForListing2()
        data = items
                .map{|item|
                    {
                        "item" => item,
                        "line" => Nx10::toString3(item)
                    }
                }
        XCache::set("a703683f-764f-47fb-ba9c-bf1f154490e3", JSON.generate(data))
    end

    # Nx10::getNx10FromCache()
    def self.getNx10FromCache()
        JSON.parse(XCache::getOrDefaultValue("a703683f-764f-47fb-ba9c-bf1f154490e3", "[]"))
    end

    # Regular main listing
    # Nx10::toString3(item)
    def self.toString3(item)
        return nil if item.nil?
        line = "STORE-PREFIX #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{DoNotShowUntil::suffix2(item)}"
        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end
        if NxBalls::itemIsActive(item) then
            line = line.green
        end
        line
    end

    # Nx10::run_display(store, printer)
    def self.run_display(store, printer)
        NxDateds::processPastItems()
        printer.call("")
        data = Nx10::getNx10FromCache()
        data
            .each{|packet|
                item = packet["item"]
                line = packet["line"]
                store.register(item, Listing::canBeDefault(item))
                line = line.gsub("STORE-PREFIX", "(#{store.prefixString()})")
                printer.call(line)
            }
        if data.empty? then
            puts "moon 🚀 : #{IO.read("#{Config::pathToCatalystDataRepository()}/moon.txt")}"
        end
        store
    end
end
