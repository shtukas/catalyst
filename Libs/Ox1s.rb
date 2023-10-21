
class Ox1s

    # Ox1s::make(ordinal)
    def self.make(ordinal)
        {
            "ordinal" => ordinal
        }
    end

    # Ox1s::mark(uuid, ordinal)
    def self.mark(uuid, ordinal)
        ox1 = Ox1s::make(ordinal)
        Updates::itemAttributeUpdate(uuid, "ordinal-1050", ox1)
    end

    # Ox1s::getFirstPosition()
    def self.getFirstPosition()
        Catalyst::catalystItems()
            .reduce(0){|position, item|
                if item["ordinal-1050"] then
                    position = [position, item["ordinal-1050"]["ordinal"]].min
                end
                position
            }
    end

    # Ox1s::markAtTop(uuid)
    def self.markAtTop(uuid)
        Ox1s::mark(uuid, Ox1s::getFirstPosition()-1)
    end

    # Ox1s::organiseListing(items)
    def self.organiseListing(items)
        i1, i2 = items.partition{|item| item["ordinal-1050"] }
        i1.sort_by{|item| item["ordinal-1050"]["ordinal"] } + i2
    end
end
