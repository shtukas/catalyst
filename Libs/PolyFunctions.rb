
class PolyFunctions

    # PolyFunctions::itemToBankingAccounts(item, depth = 6) # Array[{description, number}]
    def self.itemToBankingAccounts(item, depth = 6)

        return [] if depth == 0

        accounts = []

        accounts << {
            "description" => item["description"] || item["mikuType"],
            "number"      => item["uuid"]
        }

        if item["nx1949"] then
            parent = Items::itemOrNull(item["nx1949"]["parentuuid"])
            if parent then
                accounts << {
                    "description" => "(parent: #{parent["description"]})",
                    "number"      => item["donation-1205"]
                }
                accounts = accounts + PolyFunctions::itemToBankingAccounts(parent, depth-1)
            else
                accounts << {
                    "description" => "(parent not found: #{item["nx1949"]["parentuuid"]})",
                    "number"      => item["donation-1205"]
                }
            end
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

    # PolyFunctions::childrenForParent(parent)
    def self.childrenForParent(parent)
        directory = "#{Config::userHomeDirectory()}/Galaxy/DataHub/Catalyst/data/HardProblem/Children/#{parent["uuid"]}"
        filepath = HardProblem::retrieveUniqueJsonFileInDirectoryOrNullDestroyMultiple(directory)
        if filepath then
            return JSON.parse(IO.read(filepath))
        else
            items = Items::items()
                        .select{|item|
                            item["nx1949"] and item["nx1949"]["parentuuid"] == parent["uuid"] 
                        }
            HardProblem::commitJsonDataToDiskContentAddressed(directory, items)
            return items
        end
    end

    # PolyFunctions::hasChildren(parent)
    def self.hasChildren(parent)
        PolyFunctions::childrenForParent(parent).size > 0
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
        PolyFunctions::childrenForParent(parent)
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

    # PolyFunctions::makeNewNearTopNx1949InInfinityOrNull()
    def self.makeNewNearTopNx1949InInfinityOrNull()
        coreuuid = NxCores::infinityuuid()
        core = Items::itemOrNull(coreuuid)
        return nil if core.nil?
        position = PolyFunctions::random_10_20_position_in_parent(core)
        {
            "position" => position,
            "parentuuid" => core["uuid"]
        }
    end
end
