
class PolyFunctions

    # PolyFunctions::itemToBankingAccounts(item) # Array[{description, number}]
    def self.itemToBankingAccounts(item)

        accounts = []

        accounts << {
            "description" => item["description"] || item["mikuType"],
            "number"      => item["uuid"]
        }

        # ------------------------------------------------
        # Special Features

        if item["donation-1205"] then
            target = Items::itemOrNull(item["donation-1205"])
            if target then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(target)
            end
        end

        # ------------------------------------------------
        # MikuType Features

        if item["mikuType"] == "Wave" and !item["interruption"] then
            accounts << {
                "description" => "Wave NotInterruption (General)",
                "number"      => "Waves:NotInterruption:7514-469a98"
            }
        end

        if item["mikuType"] == "NxTask" then
            if Bank1::getValue(item["uuid"]) == 0 then
                # Never done, so it goes to the Zero collection
                accounts << {
                    "description" => "NxTask (General, Zero)",
                    "number"      => "Tasks:0:81be93ef-0cdd-49db-9fb8-b83d6b57f606"
                }
            else
                # Already worked on, so it goes to the One collection
                accounts << {
                    "description" => "NxTask (General, One)",
                    "number"      => "Tasks:1:fdf0cb3b-58bd-4c83-af46-9479c361c9c7"
                }
            end
        end

        # ------------------------------------------------

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
        if item["mikuType"] == "NxFloat" then
            return NxFloats::toString(item)
        end
        if item["mikuType"] == "NxTask" then
            return NxTasks::toString(item, context)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671d) I do not know how to PolyFunctions::toString(item): #{item}"
    end
end
