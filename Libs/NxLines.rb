
class NxLines

    # NxLines::issue(description, position)
    def self.issue(description, position)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "nx41", {
            "type"     => "override",
            "position" => position
        })
        Items::setAttribute(uuid, "mikuType", "NxLine")
        item = Items::objectOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # NxLines::icon()
    def self.icon()
        "🖋️ "
    end

    # NxLines::toString(item)
    def self.toString(item)
        "#{NxLines::icon()} #{item["description"]}"
    end
end
