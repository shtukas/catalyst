
class PolyFunctions

    # PolyFunctions::itemToBankingAccounts(item, depth = 6) # Array[{description, number}]
    def self.itemToBankingAccounts(item, depth = 6)

        return [] if depth == 0

        accounts = []

        accounts << {
            "description" => item["description"] || item["mikuType"],
            "number"      => item["uuid"]
        }

        if item["donation-14"] then
            if XCache::getOrNull("4ae8961b-204c-44ea-8e1e-fd576ffac499:#{item["donation-14"]}") then
                accounts << {
                    "description" => "donation: #{PolyFunctions::uuid_to_string_or_null_for_bank_account_display_cache_results(donationuuid) || item["donation-14"]}",
                    "number"      => donationuuid
                }
            else

            end

            target = PolyFunctions::uuid_to_item_or_null_cache_results(item["donation-14"])
            if target then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(target)
            else
                accounts << {
                    "description" => "donation: #{PolyFunctions::uuid_to_string_or_null_for_bank_account_display_cache_results(donationuuid) || item["donation-14"]}",
                    "number"      => donationuuid
                }
            end
        end

        if item["timecore-57"] then
            accounts << {
                "description" => "timecore: #{item["timecore-57"]["name"]}",
                "number"      => item["timecore-57"]["uuid"]
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
        if item["mikuType"] == "NxDeleted" then
            return "NxDeleted: uuid: #{item["uuid"]}"
        end
        if item["mikuType"] == "Anniversary" then
            return Anniversaries::toString(item)
        end
        if item["mikuType"] == "NxTask" then
            return NxTasks::toString(item)
        end
        if item["mikuType"] == "BufferIn" then
            return BufferIn::toString(item)
        end
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item)
        end
        if item["mikuType"] == "NxCounter" then
            return NxCounters::toString(item)
        end
        if item["mikuType"] == "NxActive" then
            return NxActives::toString(item)
        end
        if item["mikuType"] == "NxBackup" then
            return NxBackups::toString(item)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671d) I do not know how to PolyFunctions::toString(item): #{item}"
    end

    # PolyFunctions::uuid_to_string_or_null_for_bank_account_display_cache_results(uuid)
    def self.uuid_to_string_or_null_for_bank_account_display_cache_results(uuid)
        use_the_force = lambda {|uuid|
            item = Blades::itemOrNull(uuid)
            if item then
                return item["description"]
            end
            TimeCores::time_cores().each{|core|
                if core["uuid"] == uuid then
                    return core["name"]
                end
            }
            nil
        }

        # let's check the cached result
        str = XCache::getOrNull("cached-result-41f0-b611-d23395a8a7d1:#{uuid}")
        return str if str

        # Now we check if we have already registered it as not found
        if XCache::getFlag("null-result-4041-b57e-d6f5d7447277:#{uuid}") then
            return nil
        end

        str = use_the_force.call(uuid)

        if str.nil? then
            XCache::setFlag("null-result-4041-b57e-d6f5d7447277:#{uuid}")
            return nil
        end

        XCache::set("cached-result-41f0-b611-d23395a8a7d1:#{uuid}", str)

        str
    end

    # PolyFunctions::uuid_to_item_or_null_cache_results(uuid)
    def self.uuid_to_item_or_null_cache_results(uuid)

        # let's check the cached result
        item = XCache::getOrNull("cached-result-b1494ef9-f068:#{uuid}")
        return JSON.parse(item) if item

        # Now we check if we have already registered it as not found
        if XCache::getFlag("null-result-e615993d-1f43:#{uuid}") then
            return nil
        end

        item = Blades::itemOrNull(uuid)

        if item.nil? then
            XCache::setFlag("null-result-e615993d-1f43:#{uuid}", true)
            return nil
        end

        XCache::set("cached-result-b1494ef9-f068:#{uuid}", JSON.generate(item))

        item
    end

    # PolyFunctions::get_name_of_donation_target_or_identity(donation_target_id)
    def self.get_name_of_donation_target_or_identity(donation_target_id)
        target = Blades::itemOrNull(donation_target_id)
        if target then
            return target["description"]
        end
        donation_target_id
    end
end
