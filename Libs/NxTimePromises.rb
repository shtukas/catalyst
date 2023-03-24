
class NxTimePromises

    # NxTimePromises::operate()
    def self.operate()
        return if !Config::isPrimaryInstance()
        N3Objects::getMikuType("NxTimePromise").each{|item|
            if Time.new.to_i > item["unixtime"] then
                BankCore::put(item["account"], item["value"])
                N3Objects::destroy(item["uuid"])
            end
        }
    end

    # NxTimePromises::makeCapsule(unixtime, account, value)
    def self.makeCapsule(unixtime, account, value)
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "NxTimePromise",
            "unixtime" => unixtime,
            "account"  => account,
            "value"    => value
        }
    end

    # NxTimePromises::smooth(accountnumber, value, periodInDays)
    def self.smooth(accountnumber, value, periodInDays)
        items = []
        items << NxTimePromises::makeCapsule(Time.new.to_i, accountnumber, value)
        unitpayment = -value.to_f/periodInDays
        (1..periodInDays).each{|i|
            items << NxTimePromises::makeCapsule(Time.new.to_i + 86400*i, accountnumber, unitpayment)
        }
        items
    end

    # NxTimePromises::smooth_commit(accountnumber, value, periodInDays)
    def self.smooth_commit(accountnumber, value, periodInDays)
        items = NxTimePromises::smooth(accountnumber, value, periodInDays)
        puts "NxTimePromises".green
        puts JSON.pretty_generate(items)
        items.each{|capsule|
            capsule["datetime"] = Time.at(capsule["unixtime"]).utc.iso8601
            puts "NxTimePromise: account: #{accountnumber}; date: #{capsule["datetime"]}; #{capsule["value"]}".green
            puts JSON.pretty_generate(capsule)
            N3Objects::commit(capsule)
        }
    end

    # NxTimePromises::show()
    def self.show()
        N3Objects::getMikuType("NxTimePromise")
            .sort{|c1, c2| c1["unixtime"] <=> c2["unixtime"] }
            .each{|capsule|
                puts "#{Time.at(capsule["unixtime"]).to_s} : #{capsule["account"]} : #{capsule["value"]}"
            }
        LucilleCore::pressEnterToContinue()
    end
end