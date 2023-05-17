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

        if item["boarduuid"] then
            board = NxBoards::getItemOfNull(item["boarduuid"])
            if board then
                accounts = accounts + PolyFunctions::itemsToBankingAccounts(board)
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

        if item["mikuType"] == "NxFifo" then
            payload = Solingen::getItemOrNull(item["payload"]["uuid"])
            if payload then
                accounts = accounts + PolyFunctions::itemsToBankingAccounts(item["payload"])
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
        if item["mikuType"] == "NxBoard" then
            return NxBoards::toString(item)
        end
        if item["mikuType"] == "NxClique" then
            return NxCliques::toString(item)
        end
        if item["mikuType"] == "NxFire" then
            return NxFires::toString(item)
        end
        if item["mikuType"] == "NxFifo" then
            return NxFifos::toString(item)
        end
        if item["mikuType"] == "NxFloat" then
            return NxFloats::toString(item)
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

    # PolyFunctions::firstItemsForMainListing(monitor)
    def self.firstItemsForMainListing(monitor)
        if monitor["mikuType"] == "NxBoard" then
            return NxBoards::firstItemsForMainListing(monitor)
                    .first(6)
        end
        if monitor["mikuType"] == "NxMonitorLongs" then
            return Solingen::mikuTypeItems("NxLong")
                    .select{|item| item["active"] }
                    .sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
                    .first(6)
        end
        if monitor["mikuType"] == "NxMonitorTasksBoardless" then
            items = NxTasks::boardlessItems().sort_by{|item| item["position"] }
            i1s = items.take(3).sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
            i2s = items.drop(3).take(3)
            return i1s + i2s
        end
        raise "(error: 580b9d54-07a5-479b-aeef-cd5e2c1c6e35) I do not know how to PolyFunctions::firstItemsForMainListing((#{JSON.pretty_generate(monitor)})"
    end

    # PolyFunctions::completionRatio(monitor)
    def self.completionRatio(monitor)
        if monitor["mikuType"] == "NxBoard" then
            return TxEngines::completionRatio(monitor["engine"])
        end
        if monitor["mikuType"] == "NxMonitorLongs" then
            return TxEngines::completionRatio(monitor["engine"])
        end
        if monitor["mikuType"] == "NxMonitorTasksBoardless" then
            return TxEngines::completionRatio(monitor["engine"])
        end
        raise "(error: b31c7245-31cd-4546-8eac-1803ef843801) could not compute generic completion ratio for monitor: #{monitor}"
    end
end
