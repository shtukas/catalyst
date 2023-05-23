
class PolyFunctions

    # PolyFunctions::itemsToBankingAccounts(item) # Array[{description, number}]
    def self.itemsToBankingAccounts(item)

        accounts = []

        accounts << {
            "description" => "self: #{item["mikuType"]}",
            "number"      => item["uuid"]
        }

        if item["engine"] then
            accounts << {
                "description" => "self's engine",
                "number"      => item["engine"]["uuid"]
            }
            accounts << {
                "description" => "self's engine capsule",
                "number"      => item["engine"]["capsule"]
            }
        end

        if item["parentuuid"] then
            parent = NxPrincipals::getItemOfNull(item["parentuuid"])
            if parent then
                accounts = accounts + PolyFunctions::itemsToBankingAccounts(parent)
            end
        end

        if item["mikuType"] == "NxLong" then
            monitor =  Solingen::mikuTypeItems("NxMonitorLongs").first # NxLongs Monitor
            accounts = accounts + PolyFunctions::itemsToBankingAccounts(monitor)
        end

        if NxTasks::itemIsBoardless(item) then
            monitor = Solingen::getItem("bea0e9c7-f609-47e7-beea-70e433e0c82e") # NxTasksBoardless Monitor
            accounts = accounts + PolyFunctions::itemsToBankingAccounts(monitor)
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
        if item["mikuType"] == "NxPrincipal" then
            return NxPrincipals::toString(item)
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
        if item["mikuType"] == "NxMonitorLongs" then
            return NxLongs::monitorToString(item)
        end
        if item["mikuType"] == "NxMonitorTasksBoardless" then
            return NxTasks::boardlessMonitorToString(item)
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
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c) I do not know how to PolyFunctions::toString(#{JSON.pretty_generate(item)})"
    end
end
