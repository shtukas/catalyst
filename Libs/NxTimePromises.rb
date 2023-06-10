
class NxTimePromises

    # NxTimePromises::operate()
    def self.operate()
        return if !Config::isPrimaryInstance()
        DarkEnergy::mikuType("NxTimePromise").each{|item|
            if Time.new.to_i > item["unixtime"] then
                puts "Performing time promise against target uuid: #{item["targetuuid"]}".green
                targetitem = DarkEnergy::itemOrNull(item["targetuuid"])
                if targetitem.nil? then
                    puts "Could not recover item for target uuid: #{item["targetuuid"]}"
                    LucilleCore::pressEnterToContinue()
                    DarkEnergy::destroy(item["uuid"])
                    next
                end
                bankaccounts = PolyFunctions::itemsToBankingAccounts(targetitem)
                bankaccounts.each{|account|
                    puts "adding #{item["value"]} to account: #{account}"
                    Bank::put(account["number"], item["value"])
                }
                DarkEnergy::destroy(item["uuid"])
            end
        }
    end

    # NxTimePromises::make(unixtime, targetuuid, value)
    def self.make(unixtime, targetuuid, value)
        {
            "uuid"       => SecureRandom.uuid,
            "mikuType"   => "NxTimePromise",
            "unixtime"   => unixtime,
            "datetime"   => Time.at(unixtime).utc.iso8601,
            "targetuuid" => targetuuid,
            "value"      => value
        }
    end

    # NxTimePromises::compute_capsules(core, value, periodInDays)
    def self.compute_capsules(core, value, periodInDays)
        # This function takes an core and performs the following operations:
        # 1. Issue a promise that is going to substract that value from the core's capsule.
        # 2. For each (1..periodInDays)
        #    issue a promise against the core (using the core uuid)
        # Note that the value given is positive, so we substract and then add
        things = []
        things << NxTimePromises::make(Time.new.to_i, core["capsule"], -value)
        (1..periodInDays).each{|i|
            things << NxTimePromises::make(Time.new.to_i + 86400*i, core["uuid"], value.to_f/periodInDays)
        }
        things
    end

    # NxTimePromises::issue_things(core, value, periodInDays)
    def self.issue_things(core, value, periodInDays)
        NxTimePromises::compute_capsules(core, value, periodInDays)
            .each{|promise|
                uuid = promise["uuid"]
                puts JSON.pretty_generate(promise)
                puts "NxTimePromise: targetuuid: #{promise["targetuuid"]}; date: #{promise["datetime"]}; #{promise["value"]}".green
                DarkEnergy::init("NxTimePromise", uuid)
                DarkEnergy::patch(uuid, "unixtime", promise["unixtime"])
                DarkEnergy::patch(uuid, "datetime", promise["datetime"])
                DarkEnergy::patch(uuid, "targetuuid", promise["targetuuid"])
                DarkEnergy::patch(uuid, "value", promise["value"])
            }
    end

    # NxTimePromises::show()
    def self.show()
        (DarkEnergy::mikuType("NxTimeCapsule") + DarkEnergy::mikuType("NxTimePromise"))
            .sort{|c1, c2| c1["unixtime"] <=> c2["unixtime"] }
            .each{|thing|
                targetitem = DarkEnergy::itemOrNull(thing["targetuuid"])
                if targetitem.nil? then
                    puts "Could not recover item for target uuid: #{item["targetuuid"]}"
                end
                puts "#{Time.at(thing["unixtime"]).to_s} : #{targetitem["description"]} : #{thing["value"]}"
            }
        LucilleCore::pressEnterToContinue()
    end
end