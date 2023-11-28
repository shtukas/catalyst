
class TxBehaviours

    # ----------------------------------
    # Makings

    # TxBehaviours::interactivelyMakeNewOnNull()
    def self.interactivelyMakeNewOnNull()
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["ondate", "ship", "sticky"])
        return nil if option.nil?
        if option == "ondate" then
            datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "TxBehaviour",
                "type"     => "ondate",
                "datetime" => datetime
            }
        end
        if option == "ship" then
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "TxBehaviour",
                "type"     => "ship",
                "engine"   => TxCores::interactivelyMakeNew()
            }
        end
        if option == "sticky" then
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "TxBehaviour",
                "type"     => "sticky"
            }
        end
        raise "(error: d720eb47-056f-447f-9276-2e8b5b367d45) option: #{option}"
    end

    # ----------------------------------
    # Data

    # TxBehaviours::toIcon(behaviour)
    def self.toIcon(behaviour)
        return "🗓️ " if behaviour["type"] == "ondate"
        return "⛵️" if behaviour["type"] == "ship"
        return "☀️ " if behaviour["type"] == "sticky"
        raise "(error: d797c408-8682-48b9-92d5-b194c6a431be) behaviour: #{behaviour}"
    end

    # TxBehaviours::toString1(behaviour)
    def self.toString1(behaviour)
        if behaviour["type"] == "ondate" then
            return "(ondate: #{behaviour["datetime"][0, 10]})"
        end
        if behaviour["type"] == "ship" then
            return TxCores::string1(behaviour["engine"])
        end
        if behaviour["type"] == "sticky" then
            return "(sticky)"
        end
        raise "(error: 7efeb635-21ba-4b9f-bacb-95f747c18eb2) behaviour: #{behaviour}"
    end

    # TxBehaviours::toString2(behaviour)
    def self.toString2(behaviour)
        if behaviour["type"] == "ondate" then
            return ""
        end
        if behaviour["type"] == "ship" then
            return " #{TxCores::string2(behaviour["engine"])}".yellow
        end
        if behaviour["type"] == "sticky" then
            return ""
        end
        raise "(error: d518ac2f-1df1-4d82-89b4-6d615a87b102) behaviour: #{behaviour}"
    end

    # TxBehaviours::shouldDisplayInListing(behaviour)
    def self.shouldDisplayInListing(behaviour)
        if behaviour["type"] == "ondate" then
            return behaviour["datetime"][0, 10] <= CommonUtils::today()
        end
        if behaviour["type"] == "ship" then
            return true
        end
        if behaviour["type"] == "sticky" then
            return true
        end
        raise "(error 456d4952-f1fa-4f28-9f0d-2d80b32d2827) behaviour: #{behaviour}"
    end
end
