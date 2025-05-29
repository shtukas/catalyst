
class PolyFunctions

    # PolyFunctions::itemToBankingAccounts(item) # Array[{description, number}]
    def self.itemToBankingAccounts(item)

        accounts = []

        accounts << {
            "description" => item["description"] || item["mikuType"],
            "number"      => item["uuid"]
        }

        if item["donation-1205"] then
            accounts << {
                "description" => "(donation: #{item["donation-1205"]})",
                "number"      => item["donation-1205"]
            }
        end

        if item["mikuType"] == "NxStrat" then
            bottom = Items::itemOrNull(item["bottomuuid"])
            if bottom then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(bottom)
            end
        end

        if item["mikuType"] == "NxTask" then
            core = Items::itemOrNull(item["nx1949"]["parentuuid"]) # we assume that it's not null
            accounts << {
                "description" => "(core: #{core["description"]})",
                "number"      => core["uuid"]
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
        if item["mikuType"] == "NxCore" then
            return NxCores::toString(item)
        end
        if item["mikuType"] == "NxFloat" then
            return NxFloats::toString(item)
        end
        if item["mikuType"] == "NxDated" then
            return NxDateds::toString(item)
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

    # PolyFunctions::childrenForPrefix(item)
    def self.childrenForPrefix(item)
        if st = NxStrats::parentOrNull(item) then
            return [st]
        end
        PolyFunctions::childrenForParent(item)
    end

    # PolyFunctions::get_name_of_donation_target_or_identity(donation_target_id)
    def self.get_name_of_donation_target_or_identity(donation_target_id)
        target = Items::itemOrNull(donation_target_id)
        if target then
            return target["description"]
        end

        core = Item::itemOrNull(donation_target_id)
        if core then
            return core["description"]
        end

        donation_target_id
    end

    # PolyFunctions::donationSuffix(item)
    def self.donationSuffix(item)
        return "" if item["mikuType"] == "NxTask" # we have dedicated display for NxTask
        return "" if item["donation-1205"].nil?
        " #{"(d: #{PolyFunctions::get_name_of_donation_target_or_identity(item["donation-1205"])})".yellow}"
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
        raise "(error: 1931-e258c72b)"
    end

    # PolyFunctions::childrenForParent(parent)
    def self.childrenForParent(parent)
        items = Items::items().select{|item| item["nx1949"] and item["nx1949"]["parentuuid"] == parent["uuid"] }
        uuids = items.map{|item| item["uuid"] }
        XCache::set("75f37c99-edc3-44be-bed0-92ac37e79a74:#{parent["uuid"]}:#{CommonUtils::today()}", JSON.generate(uuids))
        items
    end

    # PolyFunctions::hasChildren(parent)
    def self.hasChildren(parent)
        PolyFunctions::childrenForParent(parent).size > 0
    end

    # PolyFunctions::childrenForParentUseCache(parent)
    def self.childrenForParentUseCache(parent)
        uuids = XCache::getOrNull("75f37c99-edc3-44be-bed0-92ac37e79a74:#{parent["uuid"]}:#{CommonUtils::today()}")
        if uuids then
            uuids = JSON.parse(uuids)
            items = uuids.map{|uuid| Items::getOrNull(uuid) }.compact
            return items
        end
        items = Items::items().select{|item| item["nx1949"] and item["nx1949"]["parentuuid"] == parent["uuid"] }
        uuids = items.map{|item| item["uuid"] }
        XCache::set("75f37c99-edc3-44be-bed0-92ac37e79a74:#{parent["uuid"]}:#{CommonUtils::today()}", JSON.generate(uuids))
        items
    end

    # PolyFunctions::interactivelySelectGlobalPositionInParent(parent)
    def self.interactivelySelectGlobalPositionInParent(parent)
        elements = PolyFunctions::childrenInOrder(parent)
        elements.first(20).each{|item|
            puts "#{PolyFunctions::toString(item)}"
        }
        position = LucilleCore::askQuestionAnswerAsString("position (first, next (default), <position>): ")
        if position == "" then # default does next
            position = "next"
        end
        if position == "first" then
            return ([0] + elements.map{|item| item["nx1949"]["position"] }).min.floor - 1
        end
        if position == "next" then
            return ([0] + elements.map{|item| item["nx1949"]["position"] }).max.ceil + 1
        end
        position = position.to_f
        position
    end

    # PolyFunctions::childrenInOrder(parent)
    def self.childrenInOrder(parent)
        Items::items()
            .select{|item| item["nx1949"] and item["nx1949"]["parentuuid"] == parent["uuid"] }
            .sort_by{|item| item["nx1949"]["position"] }
    end

    # PolyFunctions::firstPositionInParent(parent)
    def self.firstPositionInParent(parent)
        items = PolyFunctions::childrenInOrder(parent)
        return 1 if items.empty?
        items.first["nx1949"]["position"]
    end

    # PolyFunctions::lastPositionInParent(parent)
    def self.lastPositionInParent(parent)
        items = PolyFunctions::childrenInOrder(parent)
        return 1 if items.empty?
        items.last["nx1949"]["position"]
    end

    # PolyFunctions::random_10_20_position_in_parent(parent)
    def self.random_10_20_position_in_parent(parent)
        items = PolyFunctions::childrenInOrder(parent)
        if items.size < 20 then
            return PolyFunctions::lastPositionInParent(parent) + 1
        end
        positions = items.drop(10).take(10).map{|item| item["nx1949"]["position"] }
        first = positions.first
        last = positions.last
        first + rand * (last - first)
    end

end
