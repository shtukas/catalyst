
class PolyFunctions

    # PolyFunctions::itemToBankingAccounts(item) # Array[{description, number}]
    def self.itemToBankingAccounts(item)

        accounts = []

        accounts << {
            "description" => item["description"] || item["mikuType"],
            "number"      => item["uuid"]
        }

        if (parent = PolyFunctions::parentOrNull(item)) then
            accounts = accounts + PolyFunctions::itemToBankingAccounts(parent)
        end

        # ------------------------------------------------
        # Special Features

        if item["donation-1205"] then
            target = Items::itemOrNull(item["donation-1205"])
            if target then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(target)
            end
        end

        if item["mikuType"] == "NxTask" and item["parentuuid-0014"].nil? then
            if Bank1::getValue(item["uuid"]) == 0 then
                accounts << {
                    "description" => "Infinity Zero",
                    "number"      => "054ec562-1166-4d7b-a646-b5695298c032" # Infinity Zero
                }
            else
                accounts << {
                    "description" => "Infinity One",
                    "number"      => "1df84f80-8546-476f-9ed9-84fa84d30a5e" # Infinity One
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
        if item["mikuType"] == "NxStrat" then
            return NxStrats::toString(item)
        end
        if item["mikuType"] == "NxCore" then
            return NxCores::toString(item)
        end
        if item["mikuType"] == "NxTimeCapsule" then
            return NxTimeCapsules::toString(item)
        end
        if item["mikuType"] == "NxDated" then
            return NxDateds::toString(item)
        end
        if item["mikuType"] == "NxLongTask" then
            return NxLongTasks::toString(item)
        end
        if item["mikuType"] == "NxTask" then
            return NxTasks::toString(item)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671d) I do not know how to PolyFunctions::toString(item): #{item}"
    end

    # PolyFunctions::children(item)
    def self.children(item)
        if item["uuid"] == "427bbceb-923e-4feb-8232-05883553bb28" then # Infinity Core
            return NxTasks::listingItems()
        end
        if item["mikuType"] == "NxTimeCapsule" and item["targetuuid"] then
            return [Items::itemOrNull(item["targetuuid"])].compact
        end
        if item["mikuType"] == "NxStrat" then
            return [NxStrats::topOrNull(item["uuid"])].compact
        end
        Items::items()
            .select{|i| i["parentuuid-0014"] == item["uuid"] }
    end

    # PolyFunctions::parentOrNull(item)
    def self.parentOrNull(item)
        if item["parentuuid-0014"] then
            return Items::itemOrNull(item["parentuuid-0014"])
        end
        if item["mikuType"] == "NxStrat" then
            return [Items::itemOrNull(item["bottomuuid"])].compact
        end
        if (parent = NxTimeCapsules::getFirstCapsuleForTargetOrNull(item["uuid"])) then
            return parent
        end
        if item["mikuType"] == "NxTask" then
            # we have an NxTask withhout a parent
            # The parent is the Infinity Core
            return Items::itemOrNull("427bbceb-923e-4feb-8232-05883553bb28")
        end
        nil
    end
end
