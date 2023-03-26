
class NxLines

    # NxLines::items()
    def self.items()
        N3Objects::getMikuType("NxLine")
    end

    # NxLines::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxLines::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # NxLines::issue(line)
    def self.issue(line)
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxLine",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => line
        }
        puts JSON.pretty_generate(item)
        NxLines::commit(item)
        item = BoardsAndItems::askAndAttach(item)
        item
    end
end