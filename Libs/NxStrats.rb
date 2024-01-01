
class NxStrats

    # NxStrats::issue(description, bottomuuid)
    def self.issue(description, bottomuuid)
        uuid = SecureRandom.uuid
        Cubes2::itemInit(uuid, "NxStrat")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::setAttribute(uuid, "bottom", bottomuuid)
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxStrats::toString(item)
    def self.toString(item)
        "✨ #{item["description"]}"
    end

    # NxStrats::parentOrNull(cursor)
    def self.parentOrNull(cursor)
        Cubes2::mikuType("NxStrat")
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
                next if line == ""
                cursor = NxStrats::issue(line, cursor["uuid"])
                puts JSON.pretty_generate(cursor)
            }
    end

    # NxStrats::suffix(item)
    def self.suffix(item)
        NxStrats::parentOrNull(item) ? " ✨" : ""
    end
end
