
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

        if item["mikuType"] == "NxBlock" then
            core = item["engine-0020"]
            accounts << {
                "description" => "core: #{core["uuid"]}",
                "number"      => core["uuid"]
            }
        end

        if item["mikuType"] == "NxMisson" then
            block = Cubes2::itemOrNull("ba25c5c4-4a7c-47f3-ab9f-8ca04793bd34") # block: missions (automatic)
            accounts = accounts + PolyFunctions::itemToBankingAccounts(block)
        end

        if item["mikuType"] == "NxTask" then
            if NxTasks::isOrphan(item) then
                block = Cubes2::itemOrNull("06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3") # orphaned tasks (automatic)
                accounts = accounts + PolyFunctions::itemToBankingAccounts(block)
            end
        end

        if item["mikuType"] == "Wave" then
            if !item["interruption"] then
                block = Cubes2::itemOrNull("1c699298-c26c-47d9-806b-e19f84fd5d75") # waves !interruption (automatic)
                accounts = accounts + PolyFunctions::itemToBankingAccounts(block)
            end
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
        if item["mikuType"] == "NxBlock" then
            return NxBlocks::toString(item, context)
        end
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item)
        end
        if item["mikuType"] == "NxMonitor" then
            return NxMonitors::toString(item)
        end
        if item["mikuType"] == "NxMission" then
            return NxMissions::toString(item)
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
