
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

    # NxTimeCapsules::makePromise(unixtime, account, value)
    def self.makePromise(unixtime, account, value)
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "NxTimeCapsule",
            "unixtime" => unixtime,
            "datetime" => Time.at(unixtime).utc.iso8601,
            "account"  => account,
            "value"    => value
        }
    end

    # NxTimeCapsules::smooth_compute(account, value, periodInDays)
    def self.smooth_compute(account, value, periodInDays)
        items = []
        items << NxTimeCapsules::makePromise(Time.new.to_i, account, value)
        unitpayment = -value.to_f/periodInDays
        (1..periodInDays).each{|i|
            items << NxTimeCapsules::makePromise(Time.new.to_i + 86400*i, account, unitpayment)
        }
        items
    end

    # NxTimeCapsules::smooth_effect(account, value, periodInDays)
    def self.smooth_effect(account, value, periodInDays)
        items = NxTimeCapsules::smooth_compute(account, value, periodInDays)
        items.each{|promise|
            puts "NxTimeCapsule: account: #{promise["account"]}; date: #{promise["datetime"]}; #{promise["value"]}".green
            puts JSON.pretty_generate(promise)
            Solingen::init("NxTimeCapsule", promise["uuid"])
            Solingen::setAttribute2(uuid, "unixtime", promise["unixtime"])
            Solingen::setAttribute2(uuid, "datetime", promise["datetime"])
            Solingen::setAttribute2(uuid, "account", promise["account"])
            Solingen::setAttribute2(uuid, "value", promise["value"])
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