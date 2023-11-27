
class TxBehaviours

    # ----------------------------------
    # Makings

    # TxBehaviours::interactivelyMakeNewOnNull()
    def self.interactivelyMakeNewOnNull()
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["ondate", "ship"])
        return nil if option.nil?
        if option == "ondate" then
            datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
            return {
                "uuid"     => "c2ca6c8f-20d0-49af-84f4-4817fd1aca8a",
                "mikuType" => "TxBehaviour",
                "type"     => "ondate",
                "datetime" => datetime
            }
        end
        if option == "ship" then
            return {
                "uuid"     => "c2ca6c8f-20d0-49af-84f4-4817fd1aca8a",
                "mikuType" => "TxBehaviour",
                "type"     => "ship",
                "engine"   => [TxCores::interactivelyMakeNewOrNull()].compact
            }
        end
        raise "(error: 5CDB2A89-6449-42C4-B3A2-79F8A697A44F) option: #{option}"
    end

    # ----------------------------------
    # Data

    # TxBehaviours::toIcon(behaviour)
    def self.toIcon(behaviour)
        return "🗓️ " if behaviour["type"] == "ondate"
        return "⛵️" if behaviour["type"] == "ship"
        raise "(error: d797c408-8682-48b9-92d5-b194c6a431be) behaviour: #{behaviour}"
    end

    # TxBehaviours::toString(behaviour)
    def self.toString(behaviour)
        if behaviour["type"] == "ondate" then
            return "(ondate: #{behaviour["datetime"][0, 10]})"
        end
        if behaviour["type"] == "ship" then
            return TxCores::string1(behaviour["engine"])
        end
        raise "(error: 7efeb635-21ba-4b9f-bacb-95f747c18eb2) behaviour: #{behaviour}"
    end

    # TxBehaviours::shouldDisplayInListing(behaviour)
    def self.shouldDisplayInListing(behaviour)
        if behaviour["type"] == "ondate" then
            return behaviour["datetime"][0, 10] <= CommonUtils::today()
        end
        if behaviour["type"] == "ship" then
            return TxCores::engineDayCompletionRatio3(behaviour["engine"]) < 1
        end
        raise "(error 2572D629-5E28-4E44-86EC-37D608C8DCDA) behaviour: #{behaviour}"
    end

    # ----------------------------------
    # Ops


end
