
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
        if item["mikuType"] == "NxCore" then
            return NxCores::toString(item)
        end
        if item["mikuType"] == "NxDated" then
            return NxDateds::toString(item)
        end
        if item["mikuType"] == "NxCore" then
            return NxCores::toString(item)
        end
        if item["mikuType"] == "NxTask" then
            return NxTasks::toString(item)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        if item["mikuType"] == "NxProject" then
            return NxProjects::toString(item)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671d) I do not know how to PolyFunctions::toString(item): #{item}"
    end

    # PolyFunctions::parentOrNull(item)
    def self.parentOrNull(item)
        if item["mikuType"] == "NxTask" and item["parentuuid-0014"].nil? then
            # we have an NxTask without a parent
            # The parent is the Infinity Core
            parent = Items::itemOrNull(NxCores::infinityuuid()) # The Infinity Core
            return nil if parent.nil?
            return parent
        end
        if item["parentuuid-0014"] then
            parent = Items::itemOrNull(item["parentuuid-0014"])
            return nil if parent.nil?
            return parent
        end
        nil
    end

    # PolyFunctions::naturalChildren(item)
    def self.naturalChildren(item)
        Items::items()
            .select{|i| i["parentuuid-0014"] == item["uuid"] }
    end

    # PolyFunctions::computedChildren(item)
    def self.computedChildren(item)
        if item["uuid"] == NxCores::infinityuuid() then # Infinity Core
            return Items::mikuType("NxTask")
        end
        if item["uuid"] == "5bb75e03-eb92-4f10-b816-63f231c4d548" then # NxProjects (0)
            return NxProjects::itemsPerLevel(0)
        end
        if item["uuid"] == "26bb2eb2-6ba4-4182-a286-e4afafa75098" then # NxProjects (1)
            return NxProjects::itemsPerLevel(1)
        end
        if item["uuid"] == "5c4cfd8f-6f69-4575-9d1b-bb461a601c4b" then # NxProjects (2)
            return NxProjects::itemsPerLevel(2)
        end
        if item["uuid"] == "e8116c6d-558e-4e35-818e-419bffe623c9" then # NxProjects (3)
            return NxProjects::itemsPerLevel(3)
        end
        if item["uuid"] == "090446d4-9372-4dce-b59d-b4fc02813b3c" then # NxProjects (4)
            return NxProjects::itemsPerLevel(4)
        end
        []
    end

    # PolyFunctions::childrenForPrefix(item)
    def self.childrenForPrefix(item)
        if item["uuid"] == NxCores::infinityuuid() then # Infinity Core
            return Items::mikuType("NxTask")
                        .select{|item| item["parentuuid-0014"].nil? }
                        .first(3)
                        .sort_by{|item| Bank1::recoveredAverageHoursPerDay(item["uuid"]) }
        end
        Items::items().select{|i| i["parentuuid-0014"] == item["uuid"] }
    end

    # PolyFunctions::firstPositionInParent(parent)
    def self.firstPositionInParent(parent)
        elements = PolyFunctions::naturalChildren(parent)
        ([0] + elements.map{|item| item["global-positioning"] || 0 }).min
    end

    # PolyFunctions::lastPositionInParent(parent)
    def self.lastPositionInParent(parent)
        elements = PolyFunctions::naturalChildren(parent)
        ([0] + elements.map{|item| item["global-positioning"] || 0 }).max
    end
end
