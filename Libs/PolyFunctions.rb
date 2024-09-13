
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

        if item["parentuuid-0032"] then
            parent = Items::itemOrNull(item["parentuuid-0032"])
            if parent then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(parent)
            end
        end

        if item["donation-1601"] then
            target = Items::itemOrNull(item["donation-1601"])
            if target then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(target)
            end
        end

        # ------------------------------------------------
        # Types

        if item["mikuType"] == "NxTask" and item["parentuuid-0032"].nil? then
            # orphan todos feeding the parent thread
            accounts << {
                "description" => "infinity for orphan items",
                "number"      => NxThreads::infinityuuid()
            }
        end

        if item["mikuType"] == "NxBufferInItem" then
            # orphan todos feeding the parent thread
            accounts << {
                "description" => "infinity for bufferIn items",
                "number"      => NxThreads::infinityuuid()
            }
        end

        if item["mikuType"] == "NxMiniProject" then
            accounts << {
                "description" => "NxMiniProject (counter)",
                "number"      => "FEF32089-A7B8-4ADF-8565-B8224E405287"
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
        if item["mikuType"] == "Cx04" then
            return "[Cx04] #{item["description"]}"
        end
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
        if item["mikuType"] == "NxTask" then
            return NxTasks::toString(item, context)
        end
        if item["mikuType"] == "NxThread" then
            return NxThreads::toString(item, context)
        end
        if item["mikuType"] == "NxSeparator1" then
            return "✨"
        end
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item, context)
        end
        if item["mikuType"] == "NxPool" then
            return NxPools::toString(item)
        end
        if item["mikuType"] == "NxMiniProject" then
            return NxMiniProjects::toString(item)
        end
        if item["mikuType"] == "NxBufferInItem" then
            return NxBufferInItems::toString(item)
        end
        if item["mikuType"] == "PhysicalTarget" then
            return TargetNumbers::toString(item)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671d) I do not know how to PolyFunctions::toString(item): #{item}"
    end
end
