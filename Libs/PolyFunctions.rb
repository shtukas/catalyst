
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
            target = Blades::itemOrNull(item["donation-14"])
            if target then
                accounts = accounts + PolyFunctions::itemToBankingAccounts(target)
            else
                accounts << {
                    "description" => "donation: #{PolyFunctions::uuid_to_string_or_null(donationuuid) || item["donation-14"]}",
                    "number"      => donationuuid
                }
            end
        end

        if item["clique9"] then
            parentuuid = item["clique9"]["uuid"]
            accounts << {
                "description" => "parenting: #{PolyFunctions::uuid_to_string_or_null(parentuuid) || parentuuid}",
                "number"      => item["clique9"]["uuid"]
            }
        end

        # operation stratcom trading interception
        if item["uuid"] == "b61f7e245313b7183627b3ec0f1c59cc" then
            accounts << {
                "description" => "stratcom-trading-interception:trading",
                "number"      => "883287db-871b-4c9a-9d8e-85fed2cbd1a3"
            }
        else
            accounts << {
                "description" => "stratcom-trading-interception:everything-else",
                "number"      => "5167c421-dc33-42f0-81be-4c813e9df455"
            }
            # waves versus non waves sub priotirisation
            if item["mikuType"] == "Wave" then
                accounts << {
                    "description" => "sub classification: wave",
                    "number"      => "30185703-3A38-4030-B77A-477D6F2B7889"
                }
            else
                accounts << {
                    "description" => "sub classification: non wave",
                    "number"      => "BBC40E2A-C54F-4637-A6E1-F3DC62D37607"
                }
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
        if item["mikuType"] == "NxListing" then
            return NxListings::toString(item)
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

    # PolyFunctions::uuid_to_string_or_null(uuid)
    def self.uuid_to_string_or_null(uuid)
        item = Blades::itemOrNull(uuid)
        return nil if item
        item["description"]
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
