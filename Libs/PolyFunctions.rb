
class PolyFunctions

    # PolyFunctions::itemsToBankingAccounts(item) # Array[{description, number}]
    def self.itemsToBankingAccounts(item)

        accounts = []

        accounts << {
            "description" => item["mikuType"],
            "number"      => item["uuid"]
        }

        if item["mikuType"] == "TxEngine" then
            accounts << {
                "description" => "TxEngine(#{item["description"]})",
                "number"      => item["uuid"]
            }
            accounts << {
                "description" => nil,
                "number"      => item["capsule"]
            }
        end

        if item["engineuuid"] then
            engine = Solingen::getItemOrNull(item["engineuuid"])
            accounts = accounts + PolyFunctions::itemsToBankingAccounts(engine)
        end

        if item["parentuuid"] then
            parent = Solingen::getItemOrNull(item["parentuuid"])
            if parent then
                accounts = accounts + PolyFunctions::itemsToBankingAccounts(parent)
            end
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
        if item["mikuType"] == "NxClique" then
            return NxCliques::toString(item)
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
        if item["mikuType"] == "NxThread" then
            return NxThreads::toString(item)
        end
        if item["mikuType"] == "PhysicalTarget" then
            return PhysicalTargets::toString(item)
        end
        if item["mikuType"] == "Scheduler1Listing" then
            return item["announce"]
        end
        if item["mikuType"] == "TxEngine" then
            return TxEngines::toString(item)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c) I do not know how to PolyFunctions::toString(#{JSON.pretty_generate(item)})"
    end
end
