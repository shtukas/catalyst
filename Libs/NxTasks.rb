
class NxTasks

    # NxTasks::nextPosition()
    def self.nextPosition()
        computeAverageSeparation = lambda { |values|
            values.zip(values.drop(1)).take(values.size-1).map{|a1, a2| (a2-a1).abs }.sum.to_f/(values.size-1)
        }
        positions = Items::mikuType("NxTask")
                    .sort_by{|item| item["px36"] }
                    .map{|item| item["px36"] }
        if positions.size < 5 then
            return positions.last + 1
        end
        average_separation = computeAverageSeparation.call(positions)
        loop {
            if positions.size < 5 then
                return positions.last + 1
            end
            if computeAverageSeparation.call(positions.take(5)) > average_separation.to_f/3 then
                return positions[0] + rand * ( positions[1] - positions[0] )
            end
            positions = positions.drop(1)
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
        Items::setAttribute(uuid, "px36", NxTasks::nextPosition())
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
            .sort_by{|item| item["px36"] }
            .first(5)
    end

    # NxTasks::listingPosition(item)
    def self.listingPosition(item)
        0.2 + Math.atan(item["px36"]).to_f/1000 + 0.8 * BankDerivedData::recoveredAverageHoursPerDay("tasks-8e7fa41a").to_f/2
    end
end
