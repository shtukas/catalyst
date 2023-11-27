
class TxBehaviours

    # ----------------------------------
    # Makings

    # TxBehaviours::interactivelyMakeNewOnNull()
    def self.interactivelyMakeNewOnNull()
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["ondate"])
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
        raise "(error: 5CDB2A89-6449-42C4-B3A2-79F8A697A44F) option: #{option}"
    end

    # TxBehaviours::makeOnDateToday()
    def self.makeOnDateToday()
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "TxBehaviour",
            "type"     => "ondate",
            "datetime" => CommonUtils::nowDatetimeIso8601()
        }
    end

    # TxBehaviours::makeOnDateTomorrow()
    def self.makeOnDateTomorrow()
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "TxBehaviour",
            "type"     => "ondate",
            "datetime" => CommonUtils::nowPlusOneDayDatetimeIso8601()
        }
    end

    # ----------------------------------
    # Data

    # TxBehaviours::toIcon(behaviour)
    def self.toIcon(behaviour)
        return "🗓️ " if behaviour["type"] == "ondate"
        raise "(error: d797c408-8682-48b9-92d5-b194c6a431be) behaviour: #{behaviour}"
    end

    # TxBehaviours::toString(behaviour)
    def self.toString(behaviour)
        if behaviour["type"] == "ondate" then
            return "(ondate: #{behaviour["datetime"][0, 10]})"
        end
        raise "(error: 7efeb635-21ba-4b9f-bacb-95f747c18eb2) behaviour: #{behaviour}"
    end

    # TxBehaviours::shouldDisplayInListing(behaviour)
    def self.shouldDisplayInListing(behaviour)
        if behaviour["type"] == "ondate" then
            return behaviour["datetime"][0, 10] <= CommonUtils::today()
        end
        raise "(error 2572D629-5E28-4E44-86EC-37D608C8DCDA) behaviour: #{behaviour}"
    end

    # ----------------------------------
    # Ops


end
