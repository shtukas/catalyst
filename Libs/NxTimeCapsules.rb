
class NxTimeCapsules

    # NxTimeCapsules::operate()
    def self.operate()
        return if !Config::isPrimaryInstance()
        N3Objects::getMikuType("NxTimeCapsule").each{|item|
            if Time.new.to_i > item["unixtime"] then
                BankCore::put(item["account"], item["value"])
                N3Objects::destroy(item["uuid"])
            end
        }
    end

    # NxTimeCapsules::makeCapsule(unixtime, account, value)
    def self.makeCapsule(unixtime, account, value)
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "NxTimeCapsule",
            "unixtime" => unixtime,
            "account"  => account,
            "value"    => value
        }
    end

    # NxTimeCapsules::smooth(accountnumber, value, periodInDays)
    def self.smooth(accountnumber, value, periodInDays)
        capsules = []
        capsules << NxTimeCapsules::makeCapsule(Time.new.to_i, accountnumber, value)
        unitpayment = -value.to_f/periodInDays
        (1..periodInDays).each{|i|
            capsules << NxTimeCapsules::makeCapsule(Time.new.to_i + 86400*i, accountnumber, unitpayment)
        }
        capsules
    end

    # NxTimeCapsules::smooth_commit(accountnumber, value, periodInDays)
    def self.smooth_commit(accountnumber, value, periodInDays)
        capsules = NxTimeCapsules::smooth(accountnumber, value, periodInDays)
        puts "NxTimeCapsules".green
        puts JSON.pretty_generate(capsules)
        LucilleCore::pressEnterToContinue()
        capsules.each{|capsule|
            capsule["datetime"] = Time.at(capsule["unixtime"]).utc.iso8601
            puts "NxTimeCapsule: account: #{accountnumber}; date: #{capsule["datetime"]}; #{value}".green
            puts JSON.pretty_generate(capsule)
            LucilleCore::pressEnterToContinue()
            N3Objects::commit(capsule)
        }
    end

    # NxTimeCapsules::timeCapsules()
    def self.timeCapsules()
        N3Objects::getMikuType("NxTimeCapsule")
            .sort{|c1, c2| c1["unixtime"] <=> c2["unixtime"] }
            .each{|capsule|
                puts "#{Time.at(capsule["unixtime"]).to_s} : #{capsule["account"]} : #{capsule["value"]}"
            }
        LucilleCore::pressEnterToContinue()
    end
end