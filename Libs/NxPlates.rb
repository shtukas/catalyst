
class NxPlates

    # NxPlates::issue(description, childuuid)
    def self.issue(description, childuuid)
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxPlate", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "childuuid", childuuid)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxPlates::toString(item)
    def self.toString(item)
        "(🥞) #{item["description"]}#{CoreData::itemToSuffixString(item)}"
    end

    # NxPlates::plateOrNull(item)
    def self.plateOrNull(item)
        DarkEnergy::mikuType("NxPlate")
            .select{|plate| plate["childuuid"] == item["uuid"] }
            .sort_by{|plate| plate["unixtime"] }
            .last

        # The reason why we have a ordering by unixtime, is that technically two plates 
        # can have the same child. By in that case, we move up using the newest parent.
        # This is a convention that allows us to redefined the plate(s) above an item
        # without destroying the previous stack; more exactly the latest stack will
        # display first in Pure
    end

    # NxPlates::plate(item)
    def self.plate(item)
        # We create a plate and insert it
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        NxPlates::issue(description, item["uuid"])
    end

    # NxPlates::plates(item)
    def self.plates(item)
        # We creates a set of plates.
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        lines = text.lines.to_a.reverse
        cursor = item
        lines.each{|line|
            cursor = NxPlates::issue(line, cursor["uuid"])
        }
    end
end
