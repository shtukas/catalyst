
class PolyFunctions

    # PolyFunctions::itemToBankingAccounts(item) # Array[{description, number}]
    def self.itemToBankingAccounts(item)

        accounts = []

        accounts << {
            "description" => item["mikuType"],
            "number"      => item["uuid"]
        }

        if item["deadline"] then
            deadline = DarkEnergy::itemOrNull(item["deadline"])
            if deadline then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(deadline)
            end
        end

        if item["engine"] then
            engine = DarkEnergy::itemOrNull(item["engine"])
            if engine then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(engine)
            end
        end

        if item["core"] then
            core = DarkEnergy::itemOrNull(item["core"])
            if core then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(core)
            end
        end

        if item["core"] then
            core = DarkEnergy::itemOrNull(item["core"])
            if core then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(core)
            end
        end

        if item["mikuType"] == "NxCore" then
            accounts << {
                "description" => "NxCore capsule",
                "number"      => item["capsule"]
            }
        end

        if item["mikuType"] == "NxDeadline" then
            core = item["deadlineCore"]
            accounts << {
                "description" => "deadline",
                "number"      => core["uuid"]
            }
        end

        if item["mikuType"] == "NxEngine" then
            accounts << {
                "description" => "NxEngine capsule",
                "number"      => item["capsule"]
            }
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

    # PolyFunctions::toString(item)
    def self.toString(item)
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
        if item["mikuType"] == "NxDeadline" then
            return NxDeadlines::toString(item)
        end
        if item["mikuType"] == "NxDrop" then
            return NxDrops::toString(item)
        end
        if item["mikuType"] == "NxEngine" then
            return NxEngines::toString(item)
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
            return NxTasks::toString(item)
        end
        if item["mikuType"] == "NxTime" then
            return NxTimes::toString(item)
        end
        if item["mikuType"] == "NxSequence" then
            return NxSequences::toString(item)
        end
        if item["mikuType"] == "PhysicalTarget" then
            return PhysicalTargets::toString(item)
        end
        if item["mikuType"] == "Scheduler1Listing" then
            return item["announce"]
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c) I do not know how to PolyFunctions::toString(#{JSON.pretty_generate(item)})"
    end
end
