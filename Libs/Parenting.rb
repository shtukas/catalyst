
class Parenting

    # Parenting::setParentChild(parentuuid, childuuid, position)
    def self.setParentChild(parentuuid, childuuid, position)
        parent = DarkEnergy::itemOrNull(parentuuid)
        child = DarkEnergy::itemOrNull(childuuid)
        return if parent.nil?
        return if child.nil?
        DarkEnergy::patch(childuuid, "parent", {
            "uuid"     => parentuuid,
            "position" => position
        })
    end

    # Parenting::children(item)
    def self.children(item)
        DarkEnergy::all()
            .select{|i| i["parent"] }
            .select{|i| i["parent"]["uuid"] == item["uuid"] }
    end

    # Parenting::childrenInPositionOrder(item)
    def self.childrenInPositionOrder(item)
        Parenting::children(item)
            .sort_by{|child| Parenting::getPositionOrNull(item, child) || 0 }
    end

    # Parenting::childrenInRecoveryTimeOrder(item)
    def self.childrenInRecoveryTimeOrder(item)
        Parenting::children(item)
            .sort_by{|child| Bank::recoveredAverageHoursPerDay(child["uuid"]) }
    end

    # Parenting::childrenInRelevantOrder(item)
    def self.childrenInRelevantOrder(item)
        if item["mikuType"] == "NxCore" then
            return Parenting::children(item)
                    .sort_by{|child| Parenting::getPositionOrNull(item, child) || 0 }
        end
        if item["mikuType"] == "NxTask" then
            return []
        end
        if item["mikuType"] == "TxPools" then
            return Parenting::children(item)
                    .sort_by{|child| Bank::recoveredAverageHoursPerDay(child["uuid"]) }
        end
        if item["mikuType"] == "TxStack" then
            return Parenting::children(item)
                    .sort_by{|child| Parenting::getPositionOrNull(item, child) || 0 }
        end
        raise "(error: 2e1dfe12-ae93-491e-aa1a-b8656101471e) item: #{item}"
    end

    # Parenting::getPositionOrNull(parent, child)
    def self.getPositionOrNull(parent, child)
        return nil if child["parent"].nil?
        return nil if (parent["uuid"] != child["parent"]["uuid"])
        child["parent"]["position"]
    end

    # Parenting::getParentOrNull(item)
    def self.getParentOrNull(item)
        return nil if item["parent"].nil?
        DarkEnergy::itemOrNull(item["parent"]["uuid"])
    end

    # Parenting::childrenPositions(item)
    def self.childrenPositions(item)
        Parenting::children(item).map{|child| child["parent"]["position"] }
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

        position = Parenting::interactivelyDecideRelevantPositionAtCollection(parent)
        
        item["parent"] = {
            "uuid"     => parent["uuid"],
            "position" => position
        }
        DarkEnergy::commit(item)
    end

    # Parenting::askAndThenSetParentAttempt(item)
    def self.askAndThenSetParentAttempt(item)
        if LucilleCore::askQuestionAnswerAsBoolean("set parent ? ", false) then
            Parenting::interactivelySetParentAttempt(item)
        end
    end

    # Parenting::positionSuffix(item)
    def self.positionSuffix(item)
        parent = Parenting::getParentOrNull(item)
        return "" if parent.nil?
        position = Parenting::getPositionOrNull(parent, item)
        if position and position != 0 then
            " (#{"%5.2f" % position})"
        else
            ""
        end
    end

    # Parenting::parentSuffix(item)
    def self.parentSuffix(item)
        parent = Parenting::getParentOrNull(item)
        return "" if parent.nil?
        " (parent: #{parent["description"]})".green
    end

    # Parenting::interactivelyResetPositionAtSameParent(item)
    def self.interactivelyResetPositionAtSameParent(item)
        if item["parent"].nil? then
            puts "this item doesn't seem to have a parent"
            LucilleCore::pressEnterToContinue()
            return
        end
        position = LucilleCore::askQuestionAnswerAsString("> position: ").to_f
        item["parent"]["position"] = position
        DarkEnergy::commit(item)
    end
end
