
class NxPolymorphs

    # NxPolymorphs::issueNew(description, behavior, null | payload)
    def self.issueNew(description, behavior, payload)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "behaviours", [behavior])
        Items::setAttribute(uuid, "payload-1310", payload)
        Items::setAttribute(uuid, "mikuType", "NxPolymorph")
        Items::itemOrNull(uuid)
    end

    # NxPolymorphs::toString(item)
    def self.toString(item)
        "[polymorth] #{item["description"]}"
    end
end
