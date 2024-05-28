
class PolyFunctions

    # PolyFunctions::itemToBankingAccounts(datatrace, item) # Array[{description, number}]
    def self.itemToBankingAccounts(datatrace, item)

        accounts = []

        accounts << {
            "description" => item["description"] || item["mikuType"],
            "number"      => item["uuid"]
        }

        # Types

        # Special Features

        if item["parentuuid-0032"] then
            parent = Cubes1::itemOrNull(datatrace, item["parentuuid-0032"])
            if parent then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(datatrace, parent)
            end
        end

        if item["donation-1601"] then
            target = Cubes1::itemOrNull(datatrace, item["donation-1601"])
            if target then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(datatrace, target)
            end
        end

        if item["mikuType"] == "NxTodo" and item["parentuuid-0032"].nil? then
            # orphan todos feeding the parent thread
            accounts << {
                "description" => "parent thread for orphan todos",
                "number"      => "b83d12b6-9607-482f-8e89-239c1db49160"
            }
        end

        if item["mikuType"] == "Wave" and !item["interruption"] then
            # non interruption waves feeding the parent thread
            accounts << {
                "description" => "parent thread for waves non interruption",
                "number"      => "6dd9910e-49d8-4a6f-86fb-e9b3ba0c5900"
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
        if item["mikuType"] == "NxFloat" then
            return NxFloats::toString(item)
        end
        if item["mikuType"] == "NxLambda" then
            return item["description"]
        end
        if item["mikuType"] == "NxTodo" then
            return NxTodos::toString(item)
        end
        if item["mikuType"] == "NxThread" then
            return NxThreads::toString(item)
        end
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item)
        end
        if item["mikuType"] == "NxPool" then
            return NxPools::toString(item)
        end
        if item["mikuType"] == "NxBufferInMonitor" then
            return NxBufferInMonitors::toString(item)
        end
        if item["mikuType"] == "PhysicalTarget" then
            return PhysicalTargets::toString(item)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671d) I do not know how to PolyFunctions::toString(item): #{item}"
    end
end
