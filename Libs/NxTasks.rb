
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
        suffix = item["cx18"] ? " (#{item["cx18"]["name"]})".yellow : ""
        "#{NxTasks::icon()} #{item["description"]}#{suffix}"
    end

    # NxTasks::listingItems()
    def self.listingItems()
        i1 = Items::mikuType("NxTask")
            .select{|item| item["cx18"].nil? } # not a sequence item
            .sort_by{|item| item["px36"] }
            .first(5)
        i2 = Items::mikuType("NxTask")
            .select{|item| item["cx18"] }
        i1 + i2
    end

    # NxTasks::listingPosition(item)
    def self.listingPosition(item)
        # (copy of listing position table)
        # projects      : 1.400 -> 1.500 (over 3.0 hours), then  1.8 -> 1.9  (over 3 hours)
        # items         : 1.500 -> 1.600 (over 2.0 hours), then  1.8 -> 1.9  (over 3 hours)
        if item["cx18"] then
            rt = BankDerivedData::recoveredAverageHoursPerDay("cliques-85331fa6")
            if rt < 3.0 then
                return 1.400 + 0.6 * BankDerivedData::recoveredAverageHoursPerDay(item["cx18"]["uuid"]).to_f/3 + Math.atan(item["px36"]).to_f/1000
            else
                return 1.800 + 0.6 * BankDerivedData::recoveredAverageHoursPerDay(item["cx18"]["uuid"]).to_f/3 + Math.atan(item["px36"]).to_f/1000
            end
        end
        rt = BankDerivedData::recoveredAverageHoursPerDay("tasks-8e7fa41a")
        if rt < 3.0 then
            return 1.500 + Math.atan(item["px36"]).to_f/1000 + 0.6 * rt.to_f/3
        else
            return 1.800 + Math.atan(item["px36"]).to_f/1000 + 0.6 * rt.to_f/3
        end
    end
end
