
# encoding: UTF-8

class NxSequenceItem

    # ---------------------------------------
    # Maker

    # NxSequenceItem::interactivelyIssueNewOrNull(sequenceuuid, ordinal)
    def self.interactivelyIssueNewOrNull(sequenceuuid, ordinal)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Items::init(uuid)
        payload = UxPayload::makeNewOrNull(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "sequenceuuid", sequenceuuid)
        Items::setAttribute(uuid, "ordinal", ordinal)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "mikuType", "NxSequenceItem")
        item = Items::itemOrNull(uuid)
        Fsck::fsckOrError(item)
        item
    end

    # ---------------------------------------
    # Data

    # NxSequenceItem::sequenceSize(sequenceuuid)
    def self.sequenceSize(sequenceuuid)
        Items::mikuType("NxSequenceItem")
            .select{|item| item["sequenceuuid"] == sequenceuuid }
            .size
    end

    # NxSequenceItem::firstOrdinalInSequence(sequenceuuid)
    def self.firstOrdinalInSequence(sequenceuuid)
        ordinals = Items::mikuType("NxSequenceItem")
            .select{|item| item["sequenceuuid"] == sequenceuuid }
            .map{|item| item["ordinal"] }
        (ordinals + [1]).min
    end

    # NxSequenceItem::firstItemInSequenceOrNull(sequenceuuid)
    def self.firstItemInSequenceOrNull(sequenceuuid)
        Items::mikuType("NxSequenceItem")
            .select{|item| item["sequenceuuid"] == sequenceuuid }
            .first
    end

    # NxSequenceItem::lastOrdinalInSequence(sequenceuuid)
    def self.lastOrdinalInSequence(sequenceuuid)
        ordinals = Items::mikuType("NxSequenceItem")
            .select{|item| item["sequenceuuid"] == sequenceuuid }
            .map{|item| item["ordinal"] }
        (ordinals + [1]).max
    end

    # NxSequenceItem::toString(item)
    def self.toString(item)
        "(sequence item) #{item["description"]}#{UxPayload::suffixString(item)}"
    end

    # ---------------------------------------
    # Interactive Data

    # NxSequenceItem::interativelydecideOrdinalInSequenceOrNull(sequenceuuid) # ordinal
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
            return NxSequenceItem::lastOrdinalInSequence(sequenceuuid) + 1
        end
        ordinal.to_f
    end

    # NxSequenceItem::interactivelyDecideSequenceOrNull() # sequenceuuid or null
    def self.interactivelyDecideSequenceOrNull()
        items = Items::items()
                    .select{|item| UxPayload::itemIsSequenceCarrier(item) }
        item = LucilleCore::selectEntityFromListOfEntitiesOrNull("sequence", items, lambda{|item| PolyFunctions::toString(item) })
        return nil if item.nil?
        item["uxpayload-b4e4"]["sequenceuuid"]
    end

    # NxSequenceItem::interactivelyDecidePositioningOrNull_ExistingSequence()
    def self.interactivelyDecidePositioningOrNull_ExistingSequence()
        sequenceuuid = NxSequenceItem::interactivelyDecideSequenceOrNull()
        return nil if sequenceuuid.nil?
        ordinal = NxSequenceItem::interativelydecideOrdinalInSequenceOrNull(sequenceuuid)
        {
            "sequenceuuid" => sequenceuuid,
            "ordinal" => ordinal
        }
    end
end
