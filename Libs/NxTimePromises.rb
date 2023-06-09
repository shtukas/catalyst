
class NxTimeCapsules
    # NxTimeCapsules::operate()
    def self.operate()
        return if !Config::isPrimaryInstance()
        DarkEnergy::mikuType("NxTimeCapsule").each{|item|
            if Time.new.to_i > item["unixtime"] then
                Bank::put(item["account"], item["value"])
                DarkEnergy::destroy(item["uuid"])
            end
        }
    end

    # NxTimeCapsules::make(unixtime, account, value)
    def self.make(unixtime, account, value)
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "NxTimeCapsule",
            "unixtime" => unixtime,
            "datetime" => Time.at(unixtime).utc.iso8601,
            "account"  => account,
            "value"    => value
        }
    end
end

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

    # NxTimePromises::compute_capsules(engine, value, periodInDays)
    def self.compute_capsules(engine, value, periodInDays)
        # This function takes an engine and performs the following operations

        # 1. Issue a capsule that is going to substract that value from the engine's capsule.
        #    Note that the two "capsule"s in the previous sentence do not represent the same type :)
        #    The value is meant to represent some partial overflow.

        # 2. For each (1..periodInDays)
        #    issue a promise against the engine (using the engine uuid)

        # Note that the value given is positive, so we substract and then add

        things = []
        things << NxTimeCapsules::make(Time.new.to_i, engine["capsule"], -value)
        (1..periodInDays).each{|i|
            things << NxTimePromises::make(Time.new.to_i + 86400*i, engine["uuid"], value.to_f/periodInDays)
        }
        things
    end

    # NxTimePromises::issue_things(engine, value, periodInDays)
    def self.issue_things(engine, value, periodInDays)
        NxTimePromises::compute_capsules(engine, value, periodInDays)
            .each{|thing|
                uuid = thing["uuid"]
                if thing["mikuType"] == "NxTimeCapsule" then
                    puts JSON.pretty_generate(thing)
                    puts "NxTimeCapsule: account: #{thing["account"]}; date: #{thing["datetime"]}; #{thing["value"]}".green
                    DarkEnergy::init("NxTimeCapsule", uuid)
                    DarkEnergy::patch(uuid, "unixtime", thing["unixtime"])
                    DarkEnergy::patch(uuid, "datetime", thing["datetime"])
                    DarkEnergy::patch(uuid, "account", thing["account"])
                    DarkEnergy::patch(uuid, "value", thing["value"])
                end
                if thing["mikuType"] == "NxTimePromise" then
                    puts JSON.pretty_generate(thing)
                    puts "NxTimePromise: targetuuid: #{thing["targetuuid"]}; date: #{thing["datetime"]}; #{thing["value"]}".green
                    DarkEnergy::init("NxTimePromise", uuid)
                    DarkEnergy::patch(uuid, "unixtime", thing["unixtime"])
                    DarkEnergy::patch(uuid, "datetime", thing["datetime"])
                    DarkEnergy::patch(uuid, "targetuuid", thing["targetuuid"])
                    DarkEnergy::patch(uuid, "value", thing["value"])
                end
            }
    end

    # NxTimePromises::show()
    def self.show()
        (DarkEnergy::mikuType("NxTimeCapsule") + DarkEnergy::mikuType("NxTimePromise"))
            .sort{|c1, c2| c1["unixtime"] <=> c2["unixtime"] }
            .each{|thing|
                if thing["mikuType"] == "NxTimeCapsule" then
                    board = DarkEnergy::itemOrNull(thing["account"])
                    puts "#{Time.at(thing["unixtime"]).to_s} : #{thing["account"]} : #{thing["value"]}#{board ? " (#{board["description"]})" : ""}"
                end
                if thing["mikuType"] == "NxTimePromise" then
                    targetitem = DarkEnergy::itemOrNull(thing["targetuuid"])
                    if targetitem.nil? then
                        puts "Could not recover item for target uuid: #{item["targetuuid"]}"
                    end
                    puts "#{Time.at(thing["unixtime"]).to_s} : #{targetitem["description"]} : #{thing["value"]}"
                end
            }
        LucilleCore::pressEnterToContinue()
    end
end