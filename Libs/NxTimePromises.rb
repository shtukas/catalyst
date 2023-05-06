
class NxTimePromises

    # NxTimePromises::operate()
    def self.operate()
        return if !Config::isPrimaryInstance()
        N3Objects::getMikuType("NxTimePromise").each{|item|
            if Time.new.to_i > item["unixtime"] then
                Bank::put(item["account"], item["value"])
                Blades::destroy(item["uuid"])
            end
        }
    end

    # NxTimePromises::makePromise(unixtime, account, value)
    def self.makePromise(unixtime, account, value)
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "NxTimePromise",
            "unixtime" => unixtime,
            "datetime" => Time.at(unixtime).utc.iso8601,
            "account"  => account,
            "value"    => value
        }
    end

    # NxTimePromises::smooth_compute(account, value, periodInDays)
    def self.smooth_compute(account, value, periodInDays)
        items = []
        items << NxTimePromises::makePromise(Time.new.to_i, account, value)
        unitpayment = -value.to_f/periodInDays
        (1..periodInDays).each{|i|
            items << NxTimePromises::makePromise(Time.new.to_i + 86400*i, account, unitpayment)
        }
        items
    end

    # NxTimePromises::smooth_effect(account, value, periodInDays)
    def self.smooth_effect(account, value, periodInDays)
        items = NxTimePromises::smooth_compute(account, value, periodInDays)
        items.each{|promise|
            puts "NxTimePromise: account: #{promise["account"]}; date: #{promise["datetime"]}; #{promise["value"]}".green
            puts JSON.pretty_generate(promise)
            N3Objects::commit(promise)
        }
    end

    # NxTimePromises::show()
    def self.show()
        N3Objects::getMikuType("NxTimePromise")
            .sort{|c1, c2| c1["unixtime"] <=> c2["unixtime"] }
            .each{|capsule|
                board = NxBoards::getItemOfNull(capsule["account"])
                puts "#{Time.at(capsule["unixtime"]).to_s} : #{capsule["account"]} : #{capsule["value"]}#{board ? " (#{board["description"]})" : ""}"
            }
        LucilleCore::pressEnterToContinue()
    end
end