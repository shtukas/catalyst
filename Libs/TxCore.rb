
class TxCores

    # -----------------------------------------------
    # Build

    # TxCores::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        engine = TxEngines::interactivelyMakeNewOrNull()

        uuid = SecureRandom.uuid
        Updates::itemInit(uuid, "TxCore")

        Updates::itemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Updates::itemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Updates::itemAttributeUpdate(uuid, "description", description)
        Updates::itemAttributeUpdate(uuid, "engine-0916", engine)

        Catalyst::itemOrNull(uuid)
    end

    # -----------------------------------------------
    # Data

    # TxCores::toString(item)
    def self.toString(item)
        padding = XCache::getOrDefaultValue("b1bd5d84-@051-030a-03d0-02efe1bf6457", "0").to_i
        "🎇 #{TxEngines::prefix2(item)}#{item["description"].ljust(padding)} (#{TxEngines::toString(item["engine-0916"]).green})"
    end

    # TxCores::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("item", Catalyst::mikuType("TxCore"), lambda{|item| TxCores::toString(item) })
    end

    # TxCores::listingItems()
    def self.listingItems()
        Catalyst::mikuType("TxCore")
            .sort_by{|item| TxEngines::listingCompletionRatio(item["engine-0916"]) }
    end

    # TxCores::suffix(item)
    def self.suffix(item)
        return "" if item["core-1919"].nil?
        core = Catalyst::itemOrNull(item["core-1919"])
        return "" if core.nil?
        " (#{core["description"]})".green
    end

    # -----------------------------------------------
    # Ops

    # TxCores::maintenance3()
    def self.maintenance3()
        padding = (Catalyst::mikuType("TxCore").map{|item| item["description"].size } + [0]).max
        XCache::set("b1bd5d84-@051-030a-03d0-02efe1bf6457", padding)
    end
end
