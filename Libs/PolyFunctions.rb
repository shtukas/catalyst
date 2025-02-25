
class PolyFunctions

    # PolyFunctions::itemToBankingAccounts(item) # Array[{description, number}]
    def self.itemToBankingAccounts(item)

        accounts = []

        accounts << {
            "description" => item["description"] || item["mikuType"],
            "number"      => item["uuid"]
        }

        if item["engine-1706"] then
            target = Items::itemOrNull(item["engine-1706"]["targetuuid"])
            if target then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(target)
            end
        end

        if item["donation-1205"] then
            target = Items::itemOrNull(item["donation-1205"])
            if target then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(target)
            end
        end

        if (parent = PolyFunctions::parentOrNull(item)) then
            accounts = accounts + PolyFunctions::itemToBankingAccounts(parent)
        end

        if item["mikuType"] == "NxStrat" then
            bottom = Items::itemOrNull(item["bottomuuid"])
            if bottom then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(bottom)
            end
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
        if item["mikuType"] == "NxLambda" then
            return NxLambdas::toString(item)
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
        if item["mikuType"] == "NxMonitor" then
            return NxMonitors::toString(item)
        end
        if item["mikuType"] == "NxStrat" then
            return NxStrats::toString(item)
        end
        if item["mikuType"] == "NxStackPriority" then
            return NxStackPriorities::toString(item)
        end
        if item["mikuType"] == "NxTask" then
            return NxTasks::toString(item)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671d) I do not know how to PolyFunctions::toString(item): #{item}"
    end

    # PolyFunctions::parentOrNull(item)
    def self.parentOrNull(item)
        return nil if item["mikuType"] != "NxTask"
        Items::itemOrNull(item["nx1940"]["coreuuid"])
    end

    # PolyFunctions::naturalChildren(item)
    def self.naturalChildren(item)
        Items::items()
            .select{|i| i["nx1940"] and i["nx1940"]["coreuuid"] == item["uuid"] }
    end

    # PolyFunctions::childrenForPrefix(item)
    def self.childrenForPrefix(item)
        if st = NxStrats::parentOrNull(item) then
            return [st]
        end
        PolyFunctions::naturalChildren(item).sort_by{|item| item["nx1940"]["position"] }
    end

    # PolyFunctions::firstPositionInParent(parent)
    def self.firstPositionInParent(parent)
        elements = PolyFunctions::naturalChildren(parent)
        ([0] + elements.map{|item| item["nx1940"]["position"] }).min
    end

    # PolyFunctions::lastPositionInParent(parent)
    def self.lastPositionInParent(parent)
        elements = PolyFunctions::naturalChildren(parent)
        ([0] + elements.map{|item| item["nx1940"]["position"] }).max
    end

    # PolyFunctions::parentingSuffix(item)
    def self.parentingSuffix(item)
        parent = PolyFunctions::parentOrNull(item)
        return "" if parent.nil?
        " #{"(p: #{parent["description"]})".yellow}"
    end

    # PolyFunctions::donationSuffix(item)
    def self.donationSuffix(item)
        return "" if item["mikuType"] == "NxTask" # we have dedicated display for NxTask
        return "" if item["donation-1205"].nil?
        target = Items::itemOrNull(item["donation-1205"])
        return "" if target.nil?
        " #{"(d: #{target["description"]})".yellow}"
    end

    # PolyFunctions::interactivelySelectDonationTargetOrNull()
    def self.interactivelySelectDonationTargetOrNull()
        items = Items::mikuType("NxCore").sort_by{|item| NxCores::ratio(item) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("target", items, lambda{|item| PolyFunctions::toString(item) })
    end

    # PolyFunctions::measure(experimentname, lambda)
    def self.measure(experimentname, lambda)
        t1 = Time.new.to_f
        result = lambda.call()
        puts "measure: #{experimentname}: #{Time.new.to_f-t1}"
        result
    end

    # PolyFunctions::ratio(item)
    def self.ratio(item)
        if item["mikuType"] == "NxCore" then
            return NxCores::ratio(item)
        end
        if item["mikuType"] == "NxMonitor" then
            return NxMonitors::ratio(item)
        end
        raise "(error: 1931-e258c72b)"
    end
end
