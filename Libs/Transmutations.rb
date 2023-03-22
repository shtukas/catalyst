
class Transmutations

    # Transmutations::targetMikuTypes()
    def self.targetMikuTypes()
        ["NxProject", "NxTask"]
    end

    # Transmutations::interactivelySelectMikuTypeOrNull()
    def self.interactivelySelectMikuTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("mikuType", Transmutations::targetMikuTypes())
    end

    # Transmutations::transmute(item)
    def self.transmute(item)
        targetMikuType = Transmutations::interactivelySelectMikuTypeOrNull()
        return if targetMikuType.nil?

        if item["mikuType"] == "NxFire" and targetMikuType == "NxProject" then
            puts JSON.pretty_generate(item)
            item["hours"] = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
            item["lastResetTime"] = 0 
            item["capsule"] = SecureRandom.hex
            item["mikuType"] = "NxProject"
            if item["boarduuid"].nil? then
                item = BoardsAndItems::interactivelyOffersToAttach(item)
            end
            puts JSON.pretty_generate(item)
            N3Objects::commit(item)
        end

        if item["mikuType"] == "NxFire" and targetMikuType == "NxTask" then
            puts JSON.pretty_generate(item)
            item["position"] = NxTasks::nextPosition()
            item["mikuType"] = "NxTask"
            if item["boarduuid"].nil? then
                item = BoardsAndItems::interactivelyOffersToAttach(item)
            end
            puts JSON.pretty_generate(item)
            N3Objects::commit(item)
        end
    end
end