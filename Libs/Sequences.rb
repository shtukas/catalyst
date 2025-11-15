
# encoding: UTF-8

class Sequences

    # ---------------------------------------
    # Data

    # Sequences::sequenceSize(sequenceuuid)
    def self.sequenceSize(sequenceuuid)
        Items::mikuType("NxSequenceItem")
            .select{|item| item["sequenceuuid"] == sequenceuuid }
            .size
    end

    # Sequences::firstOrdinalInSequence(sequenceuuid)
    def self.firstOrdinalInSequence(sequenceuuid)
        ordinals = Items::mikuType("NxSequenceItem")
            .select{|item| item["sequenceuuid"] == sequenceuuid }
            .map{|item| item["ordinal"] }
        (ordinals + [1]).min
    end

    # Sequences::firstItemInSequenceOrNull(sequenceuuid)
    def self.firstItemInSequenceOrNull(sequenceuuid)
        Items::mikuType("NxSequenceItem")
            .select{|item| item["sequenceuuid"] == sequenceuuid }
            .first
    end

    # Sequences::lastOrdinalInSequence(sequenceuuid)
    def self.lastOrdinalInSequence(sequenceuuid)
        ordinals = Items::mikuType("NxSequenceItem")
            .select{|item| item["sequenceuuid"] == sequenceuuid }
            .map{|item| item["ordinal"] }
        (ordinals + [1]).max
    end

    # ---------------------------------------
    # Interactive Data

    # Sequences::interativelydecideOrdinalInSequenceOrNull(sequenceuuid) # ordinal
    def self.interativelydecideOrdinalInSequenceOrNull(sequenceuuid)
        items = Items::mikuType("NxSequenceItem")
            .select{|item| item["sequenceuuid"] == sequenceuuid }
        if items.empty? then
            return 1
        end
        items = items.sort_by{|item| item["ordinal"] }
        items.first(20).each{|item|
            puts "(ordinal: #{item["ordinal"]}) #{item["description"]}"
        }
        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal (empty for next): ")
        if ordinal == "" then
            return Sequences::lastOrdinalInSequence(sequenceuuid) + 1
        end
        ordinal.to_f
    end

    # Sequences::interactivelyDecideSequenceOrNull() # sequenceuuid or null
    def self.interactivelyDecideSequenceOrNull()
        items = Items::items()
                    .select{|item| item["mikuType"] != "NxDeleted" }
                    .select{|item| UxPayload::itemIsSequenceCarrier(item) }
        item = LucilleCore::selectEntityFromListOfEntitiesOrNull("sequence", items, lambda{|item| PolyFunctions::toString(item) })
        return nil if item.nil?
        item["uxpayload-b4e4"]["sequenceuuid"]
    end

    # Sequences::interactivelyDecidePositioningOrNull_ExistingSequence()
    def self.interactivelyDecidePositioningOrNull_ExistingSequence()
        sequenceuuid = Sequences::interactivelyDecideSequenceOrNull()
        return nil if sequenceuuid.nil?
        ordinal = Sequences::interativelydecideOrdinalInSequenceOrNull(sequenceuuid)
        {
            "sequenceuuid" => sequenceuuid,
            "ordinal" => ordinal
        }
    end

    # Sequences::moveToSequence(item)
    def self.moveToSequence(item)
        if UxPayload::itemIsSequenceCarrier(item) then
            puts "You cannot move a sequence carrier"
            LucilleCore::pressEnterToContinue()
            return
        end
        positioning = Sequences::interactivelyDecidePositioningOrNull_ExistingSequence()
        return if positioning.nil?
        Items::setAttribute(item["uuid"], "sequenceuuid", positioning["sequenceuuid"])
        Items::setAttribute(item["uuid"], "ordinal", positioning["ordinal"])
        Items::setAttribute(item["uuid"], "mikuType", "NxSequenceItem")
        item = Items::itemOrNull(item["uuid"])
        puts JSON.pretty_generate(item)
    end
end
