
# encoding: UTF-8

class Ox1

    # Ox1::activePositionOrNull(item)
    def self.activePositionOrNull(item)
        return nil if item["ox1-0656"].nil?
        return nil if item["ox1-0656"]["date"] != CommonUtils::today()
        item["ox1-0656"]["position"]
    end

    # Ox1::suffix(item)
    def self.suffix(item)
        position = Ox1::activePositionOrNull(item)
        return "" if position.nil?
        return " [stack]"
    end

    # Ox1::getTopPostion()
    def self.getTopPostion()
        Cubes2::items().reduce(0) {|position, item|
            if (pos = Ox1::activePositionOrNull(item)) then
                [position, pos].min
            else
                position
            end
        }
    end

    # Ox1::putAtPosition(item, position)
    def self.putAtPosition(item, position)
        ox1 = {
            "date"     => CommonUtils::today(),
            "position" => position
        }
        Cubes2::setAttribute(item["uuid"], "ox1-0656", ox1)
    end

    # Ox1::putAtTop(item)
    def self.putAtTop(item)
        Ox1::putAtPosition(item, Ox1::getTopPostion() - 1)
    end

    # Ox1::organiseListing(items)
    def self.organiseListing(items)
        i1, i2 = items.partition{|item| Ox1::activePositionOrNull(item) }
        i1 = i1.sort_by{|item| Ox1::activePositionOrNull(item) }
        i1 + i2
    end

    # Ox1::detach(item)
    def self.detach(item)
        return if Ox1::activePositionOrNull(item).nil?
        Cubes2::setAttribute(item["uuid"], "ox1-0656", nil)
    end

    # Ox1::items()
    def self.items()
        Cubes2::items().select{|item| Ox1::activePositionOrNull(item) }
    end
end
