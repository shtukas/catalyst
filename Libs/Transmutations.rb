
class Transmutations

    # Transmutations::transmute(item)
    def self.transmute(item)
        if item["mikuType"] == "NxEffect" and item["behaviour"]["type"] == "ondate" then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("mikuType", ["sticky" ,"task"])
            return if option.nil?
            if option == "sticky" then
                behaviour = {
                    "uuid"     => SecureRandom.uuid,
                    "mikuType" => "TxBehaviour",
                    "type"     => "sticky"
                }
                DataCenter::setAttribute(item["uuid"], "behaviour", behaviour)
                item = DataCenter::itemOrNull(item["uuid"])
                puts JSON.pretty_generate(item)
            end
            if option == "task" then
                DataCenter::setAttribute(item["uuid"], "mikuType", "NxTask")
                item = DataCenter::itemOrNull(item["uuid"])
                puts JSON.pretty_generate(item)
                NxEffects::interactivelySelectShipAndAddTo(item)
            end
            return
        end
        raise "I do not know how to transmute: #{JSON.pretty_generate(item)}"
    end
end