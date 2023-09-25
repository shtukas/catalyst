
class PolyFunctions

    # PolyFunctions::itemToBankingAccounts(item) # Array[{description, number}]
    def self.itemToBankingAccounts(item)

        accounts = []

        accounts << {
            "description" => item["description"] || item["mikuType"],
            "number"      => item["uuid"]
        }

        # Types

        if item["mikuType"] == "TxCore" then
            accounts << {
                "description" => item["description"],
                "number"      => item["capsule"]
            }
        end

        if item["mikuType"] == "NxStrat" then
            b = Catalyst::itemOrNull(item["bottom"])
            if b then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(b)
            end
        end

        # Special Features

        if item["coreX-2300"] then
            core = Catalyst::itemOrNull(item["coreX-2300"])
            if core then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(core)
            end
        end

        if item["lineage-nx128"] then
            lineage = Catalyst::itemOrNull(item["lineage-nx128"])
            if lineage then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(lineage)
            end
        end

        if item["engine-0852"] then
            accounts << {
                "description" => "#{item["description"]}'s engine",
                "number"      => item["engine-0852"]["uuid"]
            }
        end

        if blockuuid = InMemoryCache::getOrNull("block-attribution:4858-a4ce-ff9b44527809:#{item["uuid"]}") then
            accounts << {
                "description" => "block: #{blockuuid}",
                "number"      => blockuuid
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
        if item["mikuType"] == "NxBurner" then
            return NxBurners::toString(item)
        end
        if item["mikuType"] == "NxCruise" then
            return NxCruises::toString(item)
        end
        if item["mikuType"] == "NxLambda" then
            return item["description"]
        end
        if item["mikuType"] == "NxLine" then
            return NxLines::toString(item)
        end
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item)
        end
        if item["mikuType"] == "NxPool" then
            return NxPools::toString(item)
        end
        if item["mikuType"] == "NxTask" then
            return NxTasks::toString(item)
        end
        if item["mikuType"] == "NxThread" then
            return NxThreads::toString(item)
        end
        if item["mikuType"] == "PhysicalTarget" then
            return PhysicalTargets::toString(item)
        end
        if item["mikuType"] == "Scheduler1Listing" then
            return item["announce"]
        end
        if item["mikuType"] == "NxStrat" then
            return Stratification::toString(item)
        end
        if item["mikuType"] == "TxCore" then
            return TxCores::toString(item)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c) I do not know how to PolyFunctions::toString(#{JSON.pretty_generate(item)})"
    end

    # PolyFunctions::lineageSuffix(item)
    def self.lineageSuffix(item)
        return "" if item["lineage-nx128"].nil?
        parent = Catalyst::itemOrNull(item["lineage-nx128"])
        return "" if parent.nil?
        " (#{parent["description"]})"
    end
end
