
class PolyFunctions

    # PolyFunctions::itemToBankingAccounts(item) # Array[{description, number}]
    def self.itemToBankingAccounts(item)

        accounts = []

        accounts << {
            "description" => item["description"] || item["mikuType"],
            "number"      => item["uuid"]
        }

        if item["parent"] then
            parent = DarkEnergy::itemOrNull(item["parent"]["uuid"])
            if parent then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(parent)
            end
        end

        if item["core"] then
            core = DarkEnergy::itemOrNull(item["core"])
            if core then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(core)
            end
        end

        if item["mikuType"] == "TxCore" then
            accounts << {
                "description" => item["description"],
                "number"      => item["capsule"]
            }
        end

        if item["mikuType"] == "NxBoosterX" then
            accounts = accounts + PolyFunctions::itemToBankingAccounts(item["item"])
        end

        daily = NxBoosters::dailyForTargetItemOrNull(item)
        if daily then
            # We can't call PolyFunctions::itemToBankingAccounts on the daily because
            # this would cycle.
            accounts << {
                "description" => daily["mikuType"],
                "number"      => daily["uuid"]
            }
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
        if item["mikuType"] == "NxFloat" then
            return NxFloats::toString(item)
        end
        if item["mikuType"] == "NxFront" then
            return NxFronts::toString(item)
        end
        if item["mikuType"] == "NxLambda" then
            return item["description"]
        end
        if item["mikuType"] == "NxLine" then
            return NxLines::toString(item)
        end
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item)
        end
        if item["mikuType"] == "NxBoosterX" then
            return NxBoosters::toString(item)
        end
        if item["mikuType"] == "NxCase" then
            return NxCases::toString(item)
        end
        if item["mikuType"] == "NxPage" then
            return NxPages::toString(item)
        end
        if item["mikuType"] == "NxThread" then
            return NxThreads::toString(item)
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
        if item["mikuType"] == "TxCore" then
            return TxCores::toString(item)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c) I do not know how to PolyFunctions::toString(#{JSON.pretty_generate(item)})"
    end
end
