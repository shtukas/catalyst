
class Parenting

    # Parenting::set_uuids(parentuuid, childuuid, position)
    def self.set_uuids(parentuuid, childuuid, position)
        parent = DarkEnergy::itemOrNull(parentuuid)
        child = DarkEnergy::itemOrNull(childuuid)
        return if parent.nil?
        return if child.nil?
        Parenting::set_objects(parent, child, position)
    end

    # Parenting::set_objects(parent, child, position)
    def self.set_objects(parent, child, position)
        if parent["children"].nil? then
            parent["children"] = []
        end
        parent["children"] = parent["children"].select{|tx8| tx8["childuuid"] != child["uuid"] }
        parent["children"] << {
            "childuuid" => child["uuid"],
            "position"  => position
        }
        child["parent"] = parent["uuid"]
        DarkEnergy::commit(parent)
        DarkEnergy::commit(child)
    end

    # Parenting::children(parent)
    def self.children(parent)
        return [] if parent["children"].nil?
        parent["children"]
            .map{|tx8| DarkEnergy::itemOrNull(tx8["childuuid"]) }
            .compact
    end

    # Parenting::childrenInPositionOrder(parent)
    def self.childrenInPositionOrder(parent)
        return [] if parent["children"].nil?
        parent["children"]
            .sort_by{|tx8| tx8["position"] }
            .map{|tx8| DarkEnergy::itemOrNull(tx8["childuuid"]) }
            .compact
    end

    # Parenting::childrenInRecoveryTimeOrder(parent)
    def self.childrenInRecoveryTimeOrder(parent)
        parent["children"]
            .map{|tx8| DarkEnergy::itemOrNull(tx8["childuuid"]) }
            .compact
            .sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
    end

    # Parenting::getPositionOrNull(parent, child)
    def self.getPositionOrNull(parent, child)
        return nil if parent["children"].nil?
        tx8 = parent["children"]
                    .select{|tx8| tx8["childuuid"] == child["uuid"] }
                    .first
        return nil if tx8.nil?
        tx8["position"]
    end

    # Parenting::isParentChild(px, cx)
    def self.isParentChild(px, cx)
        return false if px["children"].nil?
        px["children"].any?{|tx8| tx8["childuuid"] == cx["uuid"] }
    end

    # Parenting::getParentOrNull(item)
    def self.getParentOrNull(item)
        return nil if item["parent"].nil?
        DarkEnergy::itemOrNull(item["parent"])
    end

    # Parenting::childrenPositions(parent)
    def self.childrenPositions(parent)
        return [] if parent["children"].nil?
        parent["children"].map{|tx8| tx8["position"] }
    end

    # Parenting::positionSuffixOrNull(item)
    def self.positionSuffix(item)
        parent = Parenting::getParentOrNull(item)
        return nil if parent.nil?
        position = Parenting::getPositionOrNull(parent, item)
        if position and position != 0 then
            " (#{"%5.2f" % position})"
        else
            ""
        end
    end

    # Parenting::interactivelyDecideRelevantPositionAtCollection(item)
    def self.interactivelyDecideRelevantPositionAtCollection(item)
        if item["mikuType"] == "NxCore" then
            return NxCores::interactivelySelectPosition(item)
        end
        if item["mikuType"] == "TxPool" then
            return 0
        end
        if item["mikuType"] == "TxStack" then
            return TxStacks::interactivelySelectPosition(item)
        end
        raise "(error: 1d91191d-be7e-42a9-bb9e-0894d545f60f - unsupported mikuType) #{item["mikuType"]} (item: #{item})"
    end

    # Parenting::interactivelySetParentAttempt(item)
    def self.interactivelySetParentAttempt(item)
        puts "> select parent type:"
        if item["mikuType"] == "NxTask" then
            parentMikuType = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["NxCore", "TxStack", "TxPool"])
            return if parentMikuType.nil?
        end

        if item["mikuType"] == "TxStack" then
            parentMikuType = "NxCore"
        end

        if item["mikuType"] == "TxPool" then
            parentMikuType = "NxCore"
        end

        if parentMikuType.nil? then
            raise "(error: b20e0624-5764-4575-ba69-df89b11b37b0) I don't know how to Parenting::interactivelySetParentAttemp with item #{item}"
        end

        parent = nil

        if parentMikuType == "NxCore" then
            parent = NxCores::interactivelySelectOneOrNull()
        end

        if parentMikuType == "TxStack" then
            parent = TxStacks::interactivelySelectOneOrNull()
        end
        
        if parentMikuType == "TxPool" then
            parent = TxPools::interactivelySelectOneOrNull()
        end

        return if parent.nil?

        position = Parenting::interactivelyDecideRelevantPositionAtCollection(item)
        Parenting::set_objects(parent, item, position)
    end

    # Parenting::askAndThenSetParentAttempt(item)
    def self.askAndThenSetParentAttempt(item)
        if LucilleCore::askQuestionAnswerAsBoolean("set parent ? ", false) then
            Parenting::interactivelySetParentAttempt(item)
        end
    end
end
