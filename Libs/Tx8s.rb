
class Tx8s

    # Tx8s::make(uuid, position)
    def self.make(uuid, position)
        {
            "uuid"     => uuid,
            "position" => position
        }
    end

    # Tx8s::mikuTypeToEmoji(type)
    def self.mikuTypeToEmoji(type)
        return "⛵️" if type == "NxThread"
        return "☕️" if type == "NxCore"
        "🤔"
    end

    # Tx8s::parentSuffix(item)
    def self.parentSuffix(item)
        return "" if item["parent"].nil?
        parent = DarkEnergy::itemOrNull(item["parent"]["uuid"])
        return "" if parent.nil?
        suffix2 = (parent["mikuType"] == "NxThread" ? Tx8s::parentSuffix(parent) : "")
        " (#{Tx8s::mikuTypeToEmoji(parent["mikuType"])} #{parent["description"].green})#{suffix2}"
    end
end
