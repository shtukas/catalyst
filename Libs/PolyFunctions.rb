
class PolyFunctions

    # PolyFunctions::itemToBankingAccounts(item, depth = 6) # Array[{description, number}]
    def self.itemToBankingAccounts(item, depth = 6)

        return [] if depth == 0

        accounts = []

        accounts << {
            "description" => item["description"] || item["mikuType"],
            "number"      => item["uuid"]
        }

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
        if item["mikuType"] == "NxDeleted" then
            return "NxDeleted: uuid: #{item["uuid"]}"
        end
        if item["mikuType"] == "NxPolymorph" then
            return NxPolymorphs::toString(item)
        end
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671d) I do not know how to PolyFunctions::toString(item): #{item}"
    end

    # PolyFunctions::get_name_of_donation_target_or_identity(donation_target_id)
    def self.get_name_of_donation_target_or_identity(donation_target_id)
        target = Items::itemOrNull(donation_target_id)
        if target then
            return target["description"]
        end
        donation_target_id
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
        raise "(error: 1931-e258c72b)"
    end
end
