
class NxPolymorphs

    # NxPolymorphs::issueNew(description, behaviour, null | payload)
    def self.issueNew(description, behaviour, payload)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "behaviours", [behaviour])
        Items::setAttribute(uuid, "payload-1310", payload)
        Items::setAttribute(uuid, "mikuType", "NxPolymorph")
        Items::itemOrNull(uuid)
    end

    # NxPolymorphs::toString(item)
    def self.toString(item)
        behaviour = item["behaviours"].first
        icon = TxBehaviour::behaviourToIcon(behaviour)
        "#{icon} #{item["description"]}"
    end
end
