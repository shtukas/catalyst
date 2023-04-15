
class Transmutations

    # Transmutations::targetMikuTypes()
    def self.targetMikuTypes()
        ["NxFire", "TxContext", "NxTask"]
    end

    # Transmutations::interactivelySelectMikuTypeOrNull()
    def self.interactivelySelectMikuTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("mikuType", Transmutations::targetMikuTypes())
    end

    # Transmutations::transmute(item)
    def self.transmute(item)
        targetMikuType = Transmutations::interactivelySelectMikuTypeOrNull()
        return if targetMikuType.nil?

        if item["mikuType"] == "NxFire" and targetMikuType == "NxTask" then
            puts JSON.pretty_generate(item)
            item["mikuType"] = "NxTask"
            item = NxTasks::setHyperspatialCoordinates(item)
            puts JSON.pretty_generate(item)
            N3Objects::commit(item)
            return
        end

        if item["mikuType"] == "NxFire" and targetMikuType == "TxContext" then
            puts JSON.pretty_generate(item)
            item["mikuType"] = "TxContext"
            if item["boarduuid"].nil? then
                item = BoardsAndItems::askAndMaybeAttach(item)
            end
            puts JSON.pretty_generate(item)
            N3Objects::commit(item)
            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxFire" then
            puts JSON.pretty_generate(item)
            item["mikuType"] = "NxFire"
            if item["boarduuid"].nil? then
                item = BoardsAndItems::askAndMaybeAttach(item)
            end
            puts JSON.pretty_generate(item)
            N3Objects::commit(item)
            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxTask" then
            puts JSON.pretty_generate(item)
            item["mikuType"] = "NxTask"
            item = NxTasks::setHyperspatialCoordinates(item)
            puts JSON.pretty_generate(item)
            N3Objects::commit(item)
            return
        end

        puts "I do not know how to transmute #{item["mikuType"]} to #{targetMikuType}"
        LucilleCore::pressEnterToContinue()
    end
end