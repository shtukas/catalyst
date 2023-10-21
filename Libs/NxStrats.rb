
class NxStrats

    # NxStrats::issue(description, bottomuuid)
    def self.issue(description, bottomuuid)
        uuid = SecureRandom.uuid
        Updates::itemInit(uuid, "NxStrat")
        Updates::itemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Updates::itemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Updates::itemAttributeUpdate(uuid, "description", description)
        Updates::itemAttributeUpdate(uuid, "bottom", bottomuuid)
        Broadcasts::publishItem(uuid)
        Catalyst::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxStrats::toString(item)
    def self.toString(item)
        "✨ #{item["description"]}"
    end

    # NxStrats::parentOrNull(cursor)
    def self.parentOrNull(cursor)
        Catalyst::mikuType("NxStrat")
            .select{|item| item["bottom"] == cursor["uuid"] }
            .sort_by{|item| item["unixtime"] }
            .last
    end

    # NxStrats::stratification(array)
    def self.stratification(array)
        return [] if array.empty?
        parent = NxStrats::parentOrNull(array[0])
        if parent then
            return NxStrats::stratification([parent] + array)
        else
            return array
        end
    end

    # ------------------
    # Ops

    # NxStrats::interactivelyPile(cursor)
    def self.interactivelyPile(cursor)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text
            .lines
            .map{|line| line.strip }
            .reverse
            .each{|line|
                cursor = NxStrats::issue(line, cursor["uuid"])
                puts JSON.pretty_generate(cursor)
            }
    end
end
