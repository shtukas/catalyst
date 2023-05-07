
class NxTimeCapsules

    # NxTimeCapsules::operate()
    def self.operate()
        return if !Config::isPrimaryInstance()
        Solingen::mikuTypeItems("NxTimeCapsule").each{|item|
            if Time.new.to_i > item["unixtime"] then
                Bank::put(item["account"], item["value"])
                Solingen::destroy(item["uuid"])
            end
        }
    end

    # NxTimeCapsules::capsule(unixtime, account, value)
    def self.capsule(unixtime, account, value)
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "NxTimeCapsule",
            "unixtime" => unixtime,
            "datetime" => Time.at(unixtime).utc.iso8601,
            "account"  => account,
            "value"    => value
        }
    end

    # NxTimeCapsules::smooth_compute2(item, value, periodInDays)
    def self.smooth_compute2(item, value, periodInDays)
        # This function takes an item that is engine carrier and performs the following operations
        # 1. Issue a capsule that is going to substract that value from the item's engine capsule.
        #    The value is meant to represent some partial overflow.
        # 2. For each (1..periodInDays)
        #    For each bank account derived from that object
        #    issue a time capsule.

        # Note that the value given is positive, so we substract and then add

        capsules = []
        capsules << NxTimeCapsules::capsule(Time.new.to_i, item["engine"]["capsule"], -value)
        (1..periodInDays).each{|i|
            # Array[{description, number}]
            PolyFunctions::itemsToBankingAccounts(item).each{|ba|
                capsules << NxTimeCapsules::capsule(Time.new.to_i + 86400*i, ba["number"], value.to_f/periodInDays)
            }
        }
        capsules
    end

    # NxTimeCapsules::smooth_effect2(item, value, periodInDays)
    def self.smooth_effect2(item, value, periodInDays)
        NxTimeCapsules::smooth_compute2(item, value, periodInDays)
            .each{|capsule|
                puts JSON.pretty_generate(capsule)
                puts "NxTimeCapsule: account: #{capsule["account"]}; date: #{capsule["datetime"]}; #{capsule["value"]}".green
                Solingen::init("NxTimeCapsule", capsule["uuid"])
                Solingen::setAttribute2(uuid, "unixtime", capsule["unixtime"])
                Solingen::setAttribute2(uuid, "datetime", capsule["datetime"])
                Solingen::setAttribute2(uuid, "account", capsule["account"])
                Solingen::setAttribute2(uuid, "value", capsule["value"])
            }
    end

    # NxTimeCapsules::show()
    def self.show()
        Solingen::mikuTypeItems("NxTimeCapsule")
            .sort{|c1, c2| c1["unixtime"] <=> c2["unixtime"] }
            .each{|capsule|
                board = NxBoards::getItemOfNull(capsule["account"])
                puts "#{Time.at(capsule["unixtime"]).to_s} : #{capsule["account"]} : #{capsule["value"]}#{board ? " (#{board["description"]})" : ""}"
            }
        LucilleCore::pressEnterToContinue()
    end
end