
# encoding: UTF-8

class Stratification

    # Stratification::issue(line, bottom)
    def self.issue(line, bottom)
        description = line
        uuid = SecureRandom.uuid
        Cubes::init("NxStrat", uuid)
        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "description", description)
        Cubes::setAttribute2(uuid, "bottom", bottom)
        Cubes::itemOrNull(uuid)
    end

    # Stratification::toString(item)
    def self.toString(item)
        "✨ #{item["description"]}"
    end

    # Stratification::getParentOrNull(item)
    def self.getParentOrNull(item)
        Cubes::mikuType("NxStrat")
            .select{|i| i["bottom"] == item["uuid"] }
            .first
    end

    # Stratification::getItemStratification(item)
    # returns the item followed by the genealogy upwards
    def self.getItemStratification(item)
        stratification = [item]
        loop {
            parent = Stratification::getParentOrNull(stratification.last)
            break if parent.nil?
            stratification << parent
        }
        stratification
    end

    # Stratification::prefixWithStratification(items)
    def self.prefixWithStratification(items)
        return [] if items.empty?
        Stratification::getItemStratification(items.first).reverse + items.drop(1)
    end

    # Stratification::pile1(item, text)
    def self.pile1(item, text)
        text = text.strip
        return if text == ""
        lines = text.lines.map{|line| line.strip }
        Stratification::pile2(item, lines.reverse)
    end

    # Stratification::pile2(item, lines)
    def self.pile2(item, lines)
        return if lines.empty?
        line = lines.shift
        strat = Stratification::issue(line, item["uuid"])
        Stratification::pile2(strat, lines)
    end

    # Stratification::pile3(item)
    def self.pile3(item)
        text = CommonUtils::editTextSynchronously("")
        Stratification::pile1(item, text)
    end
end
