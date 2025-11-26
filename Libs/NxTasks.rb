
class NxTasks

    # NxTasks::nextOrdinal()
    def self.nextOrdinal()
        computeAverageSeparation = lambda { |values|
            values.zip(values.drop(1)).take(values.size-1).map{|a1, a2| (a2-a1).abs }.sum.to_f/(values.size-1)
        }
        ordinals = Items::mikuType("NxTask")
                    .sort_by{|item| item["px36-ordinal"] }
                    .map{|item| item["px36-ordinal"] }
        if ordinals.size < 5 then
            return ordinals.last + 1
        end
        average_separation = computeAverageSeparation.call(ordinals)
        loop {
            if ordinals.size < 5 then
                return ordinals.last + 1
            end
            if computeAverageSeparation.call(ordinals.take(5)) > average_separation.to_f/3 then
                return ordinals[0] + rand * ( ordinals[1] - ordinals[0] )
            end
            ordinals = ordinals.drop(1)
        }
        1
    end

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "payload-uuid-1141", UxPayloads::interactivelyIssueNewGetReferenceOrNull())
        Items::setAttribute(uuid, "px36-ordinal", NxTasks::nextOrdinal())
        Items::setAttribute(uuid, "mikuType", "NxTask")
        item = Items::objectOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # NxTasks::icon()
    def self.icon()
        "🔹"
    end

    # NxTasks::toString(item)
    def self.toString(item)
        "#{NxTasks::icon()} #{item["description"]}"
    end

    # NxTasks::listingItems()
    def self.listingItems()
        Items::mikuType("NxTask")
            .sort_by{|item| item["px36-ordinal"] }
            .first(5)
    end
end
