
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
            bottom = DataCenter::itemOrNull(item["bottom"])
            if bottom then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(bottom)
            end
        end

        if item["mikuType"] == "NxCruiser" then
            core = item["engine-0020"][0]
            accounts << {
                "description" => "core: #{core["uuid"]}",
                "number"      => core["uuid"]
            }
        end

        if item["mikuType"] == "NxTask" then
            if NxTasks::isOrphan(item) then
                accounts << {
                    "description" => "ship: orphaned tasks (automatic)",
                    "number"      => "60949c4f-4e1f-45d3-acb4-3b6c718ac1ed"
                }
            end
        end

        if item["mikuType"] == "Wave" then
            if !item["interruption"] then
                accounts << {
                    "description" => "ship: waves !interruption (automatic)",
                    "number"      => "1c699298-c26c-47d9-806b-e19f84fd5d75"
                }
            end
        end

        if item["mikuType"] == "Backup" then
            if !item["interruption"] then
                accounts << {
                    "description" => "ship: backups (automatic)",
                    "number"      => "eadf9717-58a1-449b-8b99-97c85a154fbc"
                }
            end
        end

        # Special Features

        if core = TxCores::extractActiveCoreOrNull(item) then
            accounts << {
                "description" => "core: #{core["uuid"]}",
                "number"      => core["uuid"]
            }
        end

        if item["stackuuid"] then
            parent = DataCenter::itemOrNull(item["stackuuid"])
            if parent then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(parent)
            end
        end

        if item["donation-1752"] then
            item["donation-1752"].each {|targetuuid|
                target = DataCenter::itemOrNull(targetuuid)
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
        if item["mikuType"] == "Backup" then
            return Backups::toString(item)
        end
        if item["mikuType"] == "NxLambda" then
            return item["description"]
        end
        if item["mikuType"] == "NxCruiser" then
            return NxCruisers::toString(item)
        end
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item)
        end
        if item["mikuType"] == "NxSticky" then
            return NxStickies::toString(item)
        end
        if item["mikuType"] == "NxPool" then
            return NxPools::toString(item)
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
        if item["mikuType"] == "NxStrat" then
            return NxStrats::toString(item)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c) I do not know how to PolyFunctions::toString(item): #{item}"
    end
end
