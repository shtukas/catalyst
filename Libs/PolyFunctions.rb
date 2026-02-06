
class PolyFunctions

    # PolyFunctions::itemToBankingAccounts(item, depth = 6) # Array[{description, number}]
    def self.itemToBankingAccounts(item, depth = 6)

        return [] if depth == 0

        accounts = []

        accounts << {
            "description" => item["description"] || item["mikuType"],
            "number"      => item["uuid"]
        }

        if item["donation-13"] then
            item["donation-13"].each{|donationuuid|
                target = Blades::itemOrNull(donationuuid)
                if target then
                    accounts = accounts + PolyFunctions::itemToBankingAccounts(target)
                else
                    accounts << {
                        "description" => donationuuid,
                        "number"      => donationuuid
                    }
                end
            }
        end

        if item["mikuType"] == "NxTask" then
            item["clique8"].each{|nx38|
                accounts << {
                    "description" => "parenting: #{nx38["uuid"]}",
                    "number"      => nx38["uuid"]
                }
            }
        end

        if item["engine-24"] then
            engine = item["engine-24"]
            accounts << {
                "description" => "engine: #{engine["uuid"]}",
                "number"      => engine["uuid"]
            }
        end

        if item["mikuType"] == "Wave" then
            accounts << {
                "description" => "waves general",
                "number"      => "waves-general-fd3c4ac4-1300"
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

    # PolyFunctions::get_name_of_donation_target_or_identity(donation_target_id)
    def self.get_name_of_donation_target_or_identity(donation_target_id)
        target = Blades::itemOrNull(donation_target_id)
        if target then
            return target["description"]
        end
        donation_target_id
    end
end
