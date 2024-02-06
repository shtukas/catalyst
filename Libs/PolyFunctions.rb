
class PolyFunctions

    # PolyFunctions::itemToBankingAccounts(item) # Array[{description, number}]
    def self.itemToBankingAccounts(item)

        accounts = []

        accounts << {
            "description" => item["description"] || item["mikuType"],
            "number"      => item["uuid"]
        }

        # Types

        if item["mikuType"] == "NxShip" then
            target = Cubes2::itemOrNull(item["targetuuid"])
            if target then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(target)
            end
        end

        if item["mikuType"] == "NxStrat" then
            bottom = Cubes2::itemOrNull(item["bottom"])
            if bottom then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(bottom)
            end
        end

        if item["mikuType"] == "NxRingworldMission" then
            accounts << {
                "description" => "ringworld missions control",
                "number"      => "3413fd90-cfeb-4a66-af12-c1fc3eefa9ce"
            }
        end

        if item["mikuType"] == "NxSingularNonWorkQuest" then
            accounts << {
                "description" => "singular non work quests control",
                "number"      => "043c1f2e-3baa-4313-af1c-22c4b6fcb33b"
            }
        end

        if item["mikuType"] == "NxOrbital" then
            accounts << {
                "description" => "engine: #{item["engine-0020"]["uuid"]}",
                "number"      => item["engine-0020"]["uuid"]
            }
            accounts << {
                "description" => "orbital control",
                "number"      => "9f891bc1-ca32-4792-8d66-d66612a4e7c6"
            }
        end

        if item["mikuType"] == "Wave" then
            accounts << {
                "description" => "wave control",
                "number"      => "67df9561-a0bf-4eb6-b963-a8e6f83f65b6"
            }
        end

        # Special Features

        if item["parentuuid-0032"] then
            parent = Cubes2::itemOrNull(item["parentuuid-0032"])
            if parent then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(parent)
            end
        end

        if item["donation-1752"] then
            item["donation-1752"].each {|targetuuid|
                target = Cubes2::itemOrNull(targetuuid)
                if target then
                    accounts = accounts + PolyFunctions::itemToBankingAccounts(target)
                end
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

    # PolyFunctions::toString(item, context = nil)
    def self.toString(item, context = nil)
        if item["mikuType"] == "DesktopTx1" then
            return item["announce"]
        end
        if item["mikuType"] == "DropBox" then
            return item["description"]
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
        if item["mikuType"] == "NxLambda" then
            return item["description"]
        end
        if item["mikuType"] == "NxTodo" then
            return NxTodos::toString(item, context)
        end
        if item["mikuType"] == "NxOrbital" then
            return NxOrbitals::toString(item)
        end
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item)
        end
        if item["mikuType"] == "NxRingworldMission" then
            return NxRingworldMissions::toString(item)
        end
        if item["mikuType"] == "NxSingularNonWorkQuest" then
            return NxSingularNonWorkQuests::toString(item)
        end
        if item["mikuType"] == "NxPool" then
            return NxPools::toString(item)
        end
        if item["mikuType"] == "NxShip" then
            return NxShips::toString(item)
        end
        if item["mikuType"] == "PhysicalTarget" then
            return PhysicalTargets::toString(item)
        end
        if item["mikuType"] == "Scheduler1Listing" then
            return item["announce"]
        end
        if item["mikuType"] == "NxStrat" then
            return NxStrats::toString(item)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        if item["mikuType"] == "TxTimeCore" then
            return TxTimeCores::toString(item, context)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671d) I do not know how to PolyFunctions::toString(item): #{item}"
    end
end
