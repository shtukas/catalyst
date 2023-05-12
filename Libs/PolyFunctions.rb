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
            monitor =  Solingen::getItem("347fe760-3c19-4618-8bf3-9854129b5009") # NxLongs Monitor
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
        if item["mikuType"] == "NxBoard" then
            return NxBoards::toString(item)
        end
        if item["mikuType"] == "NxClique" then
            return NxCliques::toString(item)
        end
        if item["mikuType"] == "NxFire" then
            return NxFires::toString(item)
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
        puts "I do not know how to PolyFunctions::toString(#{JSON.pretty_generate(item)})"
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c)"
    end

    # PolyFunctions::topItemOfCollectionOrNull(generatoruuid)
    def self.topItemOfCollectionOrNull(generatoruuid)
        generator = Solingen::getItemOrNull(generatoruuid)
        return nil if generator.nil?
        if generator["mikuType"] == "NxBoard" then
            board = generator
            return NxBoards::topItemOrNull(board)
        end
        if generator["mikuType"] == "NxMonitorLongs" then
            return Solingen::mikuTypeItems("NxLong")
                .select{|item| item["active"] }
                .sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
                .each{|item|
                    next if !DoNotShowUntil::isVisible(item)
                    return item
                }
        end
        if generator["mikuType"] == "NxMonitorTasksBoardless" then
            return NxTasks::boardlessItems()
                .sort_by{|item| item["position"] }
                .each{|item|
                    next if !DoNotShowUntil::isVisible(item)
                    next if NxTasks::completionRatio(item) >= 1
                    return item
                }
        end
        nil
    end

    # PolyFunctions::completionRatio(item)
    def self.completionRatio(item)
        if item["mikuType"] == "NxBoard" then
            return TxEngines::completionRatio(item["engine"])
        end
        if item["mikuType"] == "NxMonitorLongs" then
            return TxEngines::completionRatio(item["engine"])
        end
        if item["mikuType"] == "NxMonitorTasksBoardless" then
            return TxEngines::completionRatio(item["engine"])
        end
        raise "(error: b31c7245-31cd-4546-8eac-1803ef843801) could not compute generic completion ratio for item: #{item}"
    end
end
