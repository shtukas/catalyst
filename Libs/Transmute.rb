
class Transmute

    # Transmute::transmuteTo(item, targetType) # updated item
    def self.transmuteTo(item, targetType)
        if item["mikuType"] == "NxOndate" and targetType == "NxTask" then
            ListingMembership::setMembership(item, NxListings::architectNx38())
            Blades::setAttribute(item["uuid"], "mikuType", "NxTask")
            return Blades::itemOrNull(item["uuid"])
        end
        if item["mikuType"] == "NxTask" and targetType == "NxActive" then
            if LucilleCore::askQuestionAnswerAsBoolean("set engine value for #{PolyFunctions::toString(item).green} ? ") then
                whours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
                Blades::setAttribute(item["uuid"], "whours-45", whours)
            end
            Blades::setAttribute(item["uuid"], "mikuType", "NxActive")
            return Blades::itemOrNull(item["uuid"])
        end
        raise "(error a7093fd4-0236) I do not know how to transmute #{item["mikuType"]} to #{targetType}"
    end

    # Transmute::transmute(item)
    def self.transmute(item)
        mapping = {
            "NxOndate" => ["NxTask"],
            "NxTask"   => ["NxActive"]
        }
        targetTypes = mapping[item["mikuType"]]
        if targetTypes.nil? or targetTypes.empty? then
            puts "I do not have transmute targets for #{item["mikuType"]}"
            LucilleCore::pressEnterToContinue()
            return
        end
        targetType = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", targetTypes)
        if targetType then
            item = PolyActions::editDescription(item)
            Transmute::transmuteTo(item, targetType)
            return
        end
    end
end
