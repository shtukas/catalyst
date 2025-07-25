
class PolyFunctions

    # PolyFunctions::itemToBankingAccounts(item, depth = 6) # Array[{description, number}]
    def self.itemToBankingAccounts(item, depth = 6)

        return [] if depth == 0

        accounts = []

        accounts << {
            "description" => item["description"] || item["mikuType"],
            "number"      => item["uuid"]
        }

        parent = Index2::childuuidToParentOrNull(item["uuid"])
        if parent then
            accounts << {
                "description" => "(parent: #{parent["description"]})",
                "number"      => parent["uuid"]
            }
            accounts = accounts + PolyFunctions::itemToBankingAccounts(parent, depth-1)
        end

        if item["donation-1205"] then
            target = Items::itemOrNull(item["donation-1205"])
            if target then
                accounts << {
                    "description" => "(donation target: #{target["description"]})",
                    "number"      => item["donation-1205"]
                }
                accounts = accounts + PolyFunctions::itemToBankingAccounts(target, depth - 1)
            else
                accounts << {
                    "description" => "(donation target not found: #{item["donation-1205"]})",
                    "number"      => item["donation-1205"]
                }
            end
        end

        if item["mikuType"] == "NxTask" then
            # This could be seen as redundant because we have already called
            # `Index2::childuuidToParentOrNull` but here we give to NxTasks that are Orphans
            # an opportunity to get Infinity (the Index will do that automatically)
            parent = Index2::childuuidToParentOrDefaultInfinityCore(item["uuid"])
            accounts << {
                "description" => "(parent: #{parent["description"]})",
                "number"      => parent["uuid"]
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
        if item["mikuType"] == "NxLine" then
            return NxLines::toString(item)
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
        if item["mikuType"] == "NxTask" then
            return NxTasks::toString(item)
        end
        if item["mikuType"] == "NxProject" then
            return NxProjects::toString(item)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671d) I do not know how to PolyFunctions::toString(item): #{item}"
    end

    # PolyFunctions::get_name_of_donation_target_or_identity(donation_target_id)
    def self.get_name_of_donation_target_or_identity(donation_target_id)

        if XCache::getOrNull("b1ab3f25-eabd-403f-af5f-81f9b25d5fa8:#{donation_target_id}:#{CommonUtils::today()}") == "lost" then
            return donation_target_id
        end

        target = Items::itemOrNull(donation_target_id)
        if target then
            return target["description"]
        else
            # We could not find a target here (I first noticed this happening
            # after getting rid of Guardian Health)
            # We need to stop wasting time looking for it
            XCache::set("b1ab3f25-eabd-403f-af5f-81f9b25d5fa8:#{donation_target_id}:#{CommonUtils::today()}", "lost")
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

    # PolyFunctions::interactivelySelectGlobalPositionInParent(parent)
    def self.interactivelySelectGlobalPositionInParent(parent)
        elements = Index2::parentuuidToChildrenInOrder(parent["uuid"])
        elements.first(20).each{|item|
            puts "#{PolyFunctions::toString(item)}"
        }
        position = LucilleCore::askQuestionAnswerAsString("position (near (default), first, <position>): ")
        if position == "" then # default does next
            position = "next"
        end
        if position == "near" then
            return PolyFunctions::random_10_20_position_in_parent(parent)
        end
        if position == "first" then
            return ([0] + elements.map{|item| Index2::childPositionAtParentOrZero(item["uuid"], parent["uuid"]) }).min.floor - 1
        end
        position = position.to_f
        position
    end

    # PolyFunctions::firstPositionInParent(parent)
    def self.firstPositionInParent(parent)
        positions = Index2::parentuuidToChildrenPositions(parentuuid)
        return 1 if positions.empty?
        positions.min
    end

    # PolyFunctions::lastPositionInParent(parent)
    def self.lastPositionInParent(parent)
        positions = Index2::parentuuidToChildrenPositions(parentuuid)
        return 1 if positions.empty?
        positions.max
    end

    # PolyFunctions::random_10_20_position_in_parent(parent)
    def self.random_10_20_position_in_parent(parent)
        items = Index2::parentuuidToChildrenInOrder(parent["uuid"])
        if items.size < 20 then
            return PolyFunctions::lastPositionInParent(parent) + 1
        end
        positions = items.drop(10).take(10).map{|item| Index2::childPositionAtParentOrZero(item["uuid"], parent["uuid"]) }
        first = positions.first
        last = positions.last
        first + rand * (last - first)
    end

    # PolyFunctions::makeInfinityuuidAndPositionNearTheTop()
    def self.makeInfinityuuidAndPositionNearTheTop()
        coreuuid = NxCores::infinityuuid()
        core = Items::itemOrNull(coreuuid)
        position = PolyFunctions::random_10_20_position_in_parent(core)
        [coreuuid, position]
    end
end
