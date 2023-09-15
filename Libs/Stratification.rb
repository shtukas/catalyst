
# encoding: UTF-8

class Stratification

    # Stratification::issue(line, bottom)
    def self.issue(line, bottom)
        description = line
        uuid = SecureRandom.uuid
        Events::publishItemInit("NxStrat", uuid)
        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "bottom", bottom)
        Catalyst::itemOrNull(uuid)
    end

    # Stratification::toString(item)
    def self.toString(item)
        "✨ #{item["description"]}"
    end

    # Stratification::getDirectTopOrNull(item)
    def self.getDirectTopOrNull(item)
        Catalyst::mikuType("NxStrat")
            .select{|i| i["bottom"] == item["uuid"] }
            .sort_by{|i| i["unixtime"] }
            .last
    end

    # Stratification::getItemStratification(item)
    # returns the genealogy upwards
    def self.getItemStratification(item)
        stratification = [item]
        loop {
            top = Stratification::getDirectTopOrNull(stratification.last)
            break if top.nil?
            stratification << top
        }
        stratification.drop(1)
    end

    # Stratification::pile1(item, text)
    def self.pile1(item, text)
        text = text.strip
        return if text == ""
        lines = text.lines.map{|line| line.strip }.select{|line| line.size > 0 }
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
