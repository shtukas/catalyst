
class PolyFunctions

    # PolyFunctions::itemToBankingAccounts(item) # Array[{description, number}]
    def self.itemToBankingAccounts(item)

        accounts = []

        accounts << {
            "description" => item["description"] || item["mikuType"],
            "number"      => item["uuid"]
        }

        # Types

        if item["mikuType"] == "NxStrat" then
            bottom = Cubes2::itemOrNull(item["bottom"])
            if bottom then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(bottom)
            end
        end

        if item["mikuType"] == "NxTodo" and item["engine-0020"] then
            core = item["engine-0020"]
            accounts << {
                "description" => "core: #{core["uuid"]}",
                "number"      => core["uuid"]
            }
        end

        if item["mikuType"] == "NxMission" then
            accounts << {
                "description" => "missions control",
                "number"      => "missions-control-4160-84b0-09a726873619"
            }
        end

        if item["mikuType"] == "NxOrbital" then
            accounts << {
                "description" => "orbital control",
                "number"      => "orbital-control-497b-bedb-0152d1d9248a"
            }
        end

        # Special Features

        if core = item["engine-0020"] then
            accounts << {
                "description" => "core: #{core["uuid"]}",
                "number"      => core["uuid"]
            }
        end

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

    # PolyFunctions::toString(item)
    def self.toString(item)
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
            return NxTodos::toString(item)
        end
        if item["mikuType"] == "NxOrbital" then
            return NxOrbitals::toString(item)
        end
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item)
        end
        if item["mikuType"] == "NxMission" then
            return NxMissions::toString(item)
        end
        if item["mikuType"] == "NxPool" then
            return NxPools::toString(item)
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
        if item["mikuType"] == "UxCore" then
            return UxCores::toString(item)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c) I do not know how to PolyFunctions::toString(item): #{item}"
    end
end
