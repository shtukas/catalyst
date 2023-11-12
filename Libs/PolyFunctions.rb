
class PolyFunctions

    # PolyFunctions::itemToBankingAccounts(item) # Array[{description, number}]
    def self.itemToBankingAccounts(item)

        return [] if item["mikuType"] == "NxThePhantomMenace"

        accounts = []

        accounts << {
            "description" => item["description"] || item["mikuType"],
            "number"      => item["uuid"]
        }

        # Types

        if item["mikuType"] == "NxStrat" then
            bottom = Catalyst::itemOrNull(item["bottom"])
            if bottom then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(bottom)
            end
        end

        if item["mikuType"] == "NxLifter" then
            target = Catalyst::itemOrNull(item["targetuuid"])
            if target then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(target)
            end
        end

        # Special Features

        if item["coreX-2137"] then
            clique = Catalyst::itemOrNull(item["coreX-2137"])
            if clique then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(clique)
            end
        end

        if item["engine-0916"] then
            engine = item["engine-0916"]
            if engine["type"] == "orbital" then
                accounts << {
                    "description" => "engine: #{engine["uuid"]}",
                    "number"      => engine["uuid"]
                }
                accounts << {
                    "description" => "capsule: #{engine["capsule"]}",
                    "number"      => engine["capsule"]
                }
            end
            if engine["type"] == "booster" then
                accounts << {
                    "description" => "engine: #{engine["uuid"]}",
                    "number"      => engine["uuid"]
                }
            end
        end

        if item["donation-1605"] then
            targets = item["donation-1605"].map{|uuid| Catalyst::itemOrNull(uuid) }.compact
            targets.each{|target|
                accounts = accounts + PolyFunctions::itemToBankingAccounts(target)
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
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item)
        end
        if item["mikuType"] == "NxPool" then
            return NxPools::toString(item)
        end
        if item["mikuType"] == "NxTask" then
            return NxTasks::toString(item)
        end
        if item["mikuType"] == "NxLifter" then
            return NxLifters::toString(item)
        end
        if item["mikuType"] == "PhysicalTarget" then
            return PhysicalTargets::toString(item)
        end
        if item["mikuType"] == "Scheduler1Listing" then
            return item["announce"]
        end
        if item["mikuType"] == "TxCore" then
            return TxCores::toString(item)
        end
        if item["mikuType"] == "NxStrat" then
            return NxStrats::toString(item)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c) I do not know how to PolyFunctions::toString(#{JSON.pretty_generate(item)})"
    end
end
