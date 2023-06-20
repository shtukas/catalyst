
class Tx8s

    # Tx8s::make(uuid, position)
    def self.make(uuid, position)
        {
            "uuid"     => uuid,
            "position" => position
        }
    end

    # Tx8s::mikuTypeToEmoji(type)
    def self.mikuTypeToEmoji(type)
        return "⛵️" if type == "NxThread"
        return "☕️" if type == "NxCore"
        "🤔"
    end

    # Tx8s::parentSuffix(item)
    def self.parentSuffix(item)
        return "" if item["parent"].nil?
        parent = DarkEnergy::itemOrNull(item["parent"]["uuid"])
        return "" if parent.nil?
        suffix2 = (parent["mikuType"] == "NxThread" ? Tx8s::parentSuffix(parent) : "")
        " (#{Tx8s::mikuTypeToEmoji(parent["mikuType"])} #{parent["description"].green})#{suffix2}"
    end

    # Tx8s::childrenPositions(element)
    def self.childrenPositions(element)
        DarkEnergy::all()
            .select{|item| item["parent"] }
            .select{|item| item["parent"]["uuid"] == element["uuid"] }
            .map{|item| item["parent"]["position"] }
     end

    # Tx8s::repositionAtSameParent(item)
    def self.repositionAtSameParent(item)
        return if item["parent"].nil?
        parent = DarkEnergy::itemOrNull(item["parent"]["uuid"])
        return if parent.nil?
        if parent["mikuType"] == "NxThread" then
            position = NxThreads::interactivelyDecidePositionInThread(parent)
            item["parent"]["position"] = position
            DarkEnergy::commit(item)
            return
        end
        if parent["mikuType"] == "NxCore" then
            position = NxCores::interactivelyDecidePositionInCore(parent)
            item["parent"]["position"] = position
            DarkEnergy::commit(item)
            return
        end
        raise "I do not know how to Tx8s::repositionAtSameParent item: #{item}"
    end

    # --------------------------------------------------------------------------

    # Tx8s::interactivelyMakeNewTx8(item)
    def self.interactivelyMakeNewTx8(item)
        # This function returns a Tx8
        core = NxCores::interactivelySelectOneOrNull()

        if core then
            thread = NxThreads::interactivelySelectOneThreadAtCoreOrNull(core)
            if thread then
                position = NxThreads::interactivelyDecidePositionInThread(thread)
                return Tx8s::make(thread["uuid"], position)
            else
                position = NxCores::interactivelyDecidePositionInCore(core)
                return Tx8s::make(core["uuid"], position)
            end
        else
            thread = NxThreads::interactivelySelectOneOrphanThreadOrNull()
            if thread then
                position = NxThreads::interactivelyDecidePositionInThread(thread)
                return Tx8s::make(thread["uuid"], position)
            else
                return nil
            end
        end
    end
end
