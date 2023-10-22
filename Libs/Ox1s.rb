
class Ox1s

    # Ox1s::make(ordinal)
    def self.make(ordinal)
        {
            "ordinal" => ordinal,
            "date"    => CommonUtils::today()
        }
    end

    # Ox1s::mark(uuid, ordinal)
    def self.mark(uuid, ordinal)
        ox1 = Ox1s::make(ordinal)
        Updates::itemAttributeUpdate(uuid, "ordinal-1051", ox1)
    end

    # Ox1s::getFirstPosition()
    def self.getFirstPosition()
        Catalyst::catalystItems()
            .reduce(0){|position, item|
                if item["ordinal-1051"] then
                    position = [position, item["ordinal-1051"]["ordinal"]].min
                end
                position
            }
    end

    # Ox1s::markAtTop(uuid)
    def self.markAtTop(uuid)
        Ox1s::mark(uuid, Ox1s::getFirstPosition()-1)
    end

    # Ox1s::itemIsOx1(item)
    def self.itemIsOx1(item)
        return false if item["ordinal-1051"].nil?
        return false if item["ordinal-1051"]["date"] != CommonUtils::today()
    end

    # Ox1s::organiseListing(items)
    def self.organiseListing(items)
        i0 = (lambda{
                thread = Catalyst::itemOrNull("f495d79f-b023-4903-b7cb-a84873c48c83")
                if TxEngines::listingCompletionRatio(thread["engine-0916"]) < 1 then
                    [thread]
                else
                    []
                end
            }).call()
        i1, i2 = items.partition{|item| Ox1s::itemIsOx1(item) }
        i0 + i1.sort_by{|item| item["ordinal-1051"]["ordinal"] } + i2
    end
end
