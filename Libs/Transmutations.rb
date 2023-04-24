
class Transmutations

    # Transmutations::targetMikuTypes()
    def self.targetMikuTypes()
        ["NxFire", "NxClique", "NxTask"]
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
            board = NxBoards::interactivelySelectOneBoard()
            clique   = NxBoards::interactivelySelectOneClique(board)
            engine   = TxEngines::interactivelyMakeEngineOrDefault()
            item["cliqueuuid"] = cliqueuuid
            item["engine"]     = engine
            puts JSON.pretty_generate(item)
            N3Objects::commit(item)
            return
        end

        if item["mikuType"] == "NxFire" and targetMikuType == "NxClique" then
            puts JSON.pretty_generate(item)
            item["mikuType"] = "NxClique"
            if item["boarduuid"].nil? then
                item = PlanetsAndItems::maybeAskAndMaybeAttach(item)
            end
            puts JSON.pretty_generate(item)
            N3Objects::commit(item)
            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxFire" then
            puts JSON.pretty_generate(item)
            item["mikuType"] = "NxFire"
            if item["boarduuid"].nil? then
                item = PlanetsAndItems::maybeAskAndMaybeAttach(item)
            end
            puts JSON.pretty_generate(item)
            N3Objects::commit(item)
            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxTask" then
            puts JSON.pretty_generate(item)
            item["mikuType"] = "NxTask"
            board = NxBoards::interactivelySelectOneBoard()
            clique   = NxBoards::interactivelySelectOneClique(board)
            engine   = TxEngines::interactivelyMakeEngineOrDefault()
            item["cliqueuuid"] = cliqueuuid
            item["engine"]     = engine
            puts JSON.pretty_generate(item)
            N3Objects::commit(item)
            return
        end

        puts "I do not know how to transmute #{item["mikuType"]} to #{targetMikuType}"
        LucilleCore::pressEnterToContinue()
    end
end