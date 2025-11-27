
# encoding: UTF-8

class Sequences

    # ---------------------------------------
    # Data

    # Sequences::sequenceElements(parentuuid)
    def self.sequenceElements(parentuuid)
        Items::mikuType("NxTask") # sequences are limited to NxTasks
            .select{|item| item["cx17"] }
            .select{|item| item["cx17"]["parentuuid"] == parentuuid }
    end

    # Sequences::sequenceSize(parentuuid)
    def self.sequenceSize(parentuuid)
        Sequences::sequenceElements(parentuuid).size
    end

    # Sequences::firstOrdinalInSequence(parentuuid)
    def self.firstOrdinalInSequence(parentuuid)
        positions = Sequences::sequenceElements(parentuuid)
            .map{|item| item["cx17"]["position"] }
        (positions + [1]).min
    end

    # Sequences::firstItemInSequenceOrNull(parentuuid)
    def self.firstItemInSequenceOrNull(parentuuid)
        Sequences::sequenceElements(parentuuid).sort_by{|item| item["cx17"]["position"] }.first
    end

    # Sequences::lastOrdinalInSequence(parentuuid)
    def self.lastOrdinalInSequence(parentuuid)
        positions = Sequences::sequenceElements(parentuuid)
            .map{|item| item["cx17"]["position"] }
        (positions + [1]).max
    end

    # ---------------------------------------
    # Interactive

    # Sequences::interativelydecideOrdinalInSequenceOrNull(parentuuid) # position
    def self.interativelydecideOrdinalInSequenceOrNull(parentuuid)
        elements = Sequences::sequenceElements(parentuuid).sort_by{|item| item["cx17"]["position"] }
        if elements.empty? then
            return 1
        end
        elements.first(20).each{|item|
            puts "(position: #{item["cx17"]["position"]}) #{item["description"]}"
        }
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        if position == "" then
            return Sequences::lastOrdinalInSequence(parentuuid) + 1
        end
        position.to_f
    end

    # Sequences::interactivelyMakeCx17OrNull() # {"parentuuid", "position"}
    def self.interactivelyMakeCx17OrNull()
        parent = NxProjects::interactivelySelectProjectOrNull()
        return nil if parent.nil?
        position = Sequences::interativelydecideOrdinalInSequenceOrNull(parent["uuid"])
        return nil if position.nil?
        {
            "parentuuid" => parentuuid,
            "position" => position
        }
    end

    # Sequences::moveToSequence(item)
    def self.moveToSequence(item)
        cx17 = Sequences::interactivelyMakeCx17OrNull()
        return if cx17.nil?
        Items::setAttribute(item["uuid"], "cx17", cx17)
    end
end
