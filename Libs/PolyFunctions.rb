
class PolyFunctions

    # PolyFunctions::itemToBankingAccounts(item) # Array[{description, number}]
    def self.itemToBankingAccounts(item)

        accounts = []

        accounts << {
            "description" => item["mikuType"],
            "number"      => item["uuid"]
        }

        if item["mikuType"] == "NxCore" then
            accounts << {
                "description" => "NxCore capsule",
                "number"      => item["capsule"]
            }
        end

        parent = Parenting::getParentOrNull(item)

        if parent then
            accounts = accounts + PolyFunctions::itemToBankingAccounts(parent)
        end

        if item["mikuType"] == "NxTask" and NxCores::item_belongs_to_grid1(item) then
            accounts = accounts + PolyFunctions::itemToBankingAccounts(NxCores::grid1())
        end

        if item["mikuType"] == "NxTask" and NxCores::item_belongs_to_grid2(item) then
            accounts = accounts + PolyFunctions::itemToBankingAccounts(NxCores::grid2())
        end

        accounts.reduce([]){|as, account|
            if as.map{|a| a["number"] }.include?(account["number"]) then
                as
            else
                as + [account]
            end
        }
    end

    # PolyFunctions::toString(item, positionDisplayStyle)
    def self.toString(item, positionDisplayStyle = "stack")
        if item["mikuType"] == "DesktopTx1" then
            return item["announce"]
        end
        if item["mikuType"] == "DeviceBackup" then
            return item["announce"]
        end
        if item["mikuType"] == "NxAnniversary" then
            return Anniversaries::toString(item)
        end
        if item["mikuType"] == "NxBackup" then
            return NxBackups::toString(item)
        end
        if item["mikuType"] == "NxCore" then
            return NxCores::toString(item)
        end
        if item["mikuType"] == "NxDrop" then
            return NxDrops::toString(item)
        end
        if item["mikuType"] == "NxFire" then
            return NxFires::toString(item)
        end
        if item["mikuType"] == "NxBurner" then
            return NxBurners::toString(item)
        end
        if item["mikuType"] == "NxLambda" then
            return item["description"]
        end
        if item["mikuType"] == "NxLine" then
            return NxLines::toString(item)
        end
        if item["mikuType"] == "NxLong" then
            return NxLongs::toString(item)
        end
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item)
        end
        if item["mikuType"] == "NxTask" then
            return NxTasks::toString(item, positionDisplayStyle)
        end
        if item["mikuType"] == "NxTime" then
            return NxTimes::toString(item)
        end
        if item["mikuType"] == "PhysicalTarget" then
            return PhysicalTargets::toString(item)
        end
        if item["mikuType"] == "Scheduler1Listing" then
            return item["announce"]
        end
        if item["mikuType"] == "TxPool" then
            return TxPools::toString(item, positionDisplayStyle)
        end
        if item["mikuType"] == "TxStack" then
            return TxStacks::toString(item, positionDisplayStyle)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c) I do not know how to PolyFunctions::toString(#{JSON.pretty_generate(item)})"
    end

    # PolyFunctions::pure2(item)
    def self.pure2(item)
        children = Parenting::children(item)
        if item["mikuType"] == "NxTask" then
            return item
        end
        if item["mikuType"] == "NxCore" then
            return Parenting::childrenInPositionOrder(item)
                .map{|child| PolyFunctions::pure2(child) }
                .flatten
        end
        if item["mikuType"] == "TxStack" then
            return Parenting::childrenInPositionOrder(item)
                .map{|child| PolyFunctions::pure2(child) }
                .flatten
        end
        if item["mikuType"] == "TxPool" then
            return Parenting::childrenInRecoveryTimeOrder(item)
                .map{|child| PolyFunctions::pure2(child) }
                .flatten
        end
    end

    # PolyFunctions::pure1()
    def self.pure1()
        DarkEnergy::mikuType("NxCore")
            .select{|core| NxCores::listingCompletionRatio(core) < 1 }
            .sort_by{|core| NxCores::listingCompletionRatio(core) }
            .map{|core| PolyFunctions::pure2(core) }
            .flatten
    end
end
