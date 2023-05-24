
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
        Solingen::mikuTypeItems("NxTimePromise").each{|item|
            if Time.new.to_i > item["unixtime"] then
                puts "Performing time promise against target uuid: #{item["targetuuid"]}".green
                targetitem = Solingen::getItemOrNull(item["targetuuid"])
                if targetitem.nil? then
                    puts "Could not recover item for target uuid: #{item["targetuuid"]}"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                bankaccounts = PolyFunctions::itemsToBankingAccounts(targetitem)
                bankaccounts.each{|account|
                    puts "adding #{item["value"]} to account: #{account}"
                    Bank::put(account["number"], item["value"])
                }
                Solingen::destroy(item["uuid"])
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

    # NxTimePromises::compute_things(item, value, periodInDays)
    def self.compute_things(item, value, periodInDays)
        # This function takes an item that is engine carrier and performs the following operations

        # 1. Issue a capsule that is going to substract that value from the item's engine capsule.
        #    Note that the two capsules in the previous sentence are not the same type :)
        #    The value is meant to represent some partial overflow.

        # 2. For each (1..periodInDays)
        #    issue a promise against the item (using the item uuid)

        # Note that the value given is positive, so we substract and then add

        things = []
        things << NxTimeCapsules::make(Time.new.to_i, item["engine"]["capsule"], -value)
        (1..periodInDays).each{|i|
            things << NxTimePromises::make(Time.new.to_i + 86400*i, item["uuid"], value.to_f/periodInDays)
        }
        things
    end

    # NxTimePromises::issue_things(item, value, periodInDays)
    def self.issue_things(item, value, periodInDays)
        NxTimePromises::compute_things(item, value, periodInDays)
            .each{|thing|
                uuid = thing["uuid"]
                if thing["mikuType"] == "NxTimeCapsule" then
                    puts JSON.pretty_generate(thing)
                    puts "NxTimeCapsule: account: #{thing["account"]}; date: #{thing["datetime"]}; #{thing["value"]}".green
                    Solingen::init("NxTimeCapsule", uuid)
                    Solingen::setAttribute2(uuid, "unixtime", thing["unixtime"])
                    Solingen::setAttribute2(uuid, "datetime", thing["datetime"])
                    Solingen::setAttribute2(uuid, "account", thing["account"])
                    Solingen::setAttribute2(uuid, "value", thing["value"])
                end
                if thing["mikuType"] == "NxTimePromise" then
                    puts JSON.pretty_generate(thing)
                    puts "NxTimePromise: targetuuid: #{thing["targetuuid"]}; date: #{thing["datetime"]}; #{thing["value"]}".green
                    Solingen::init("NxTimePromise", uuid)
                    Solingen::setAttribute2(uuid, "unixtime", thing["unixtime"])
                    Solingen::setAttribute2(uuid, "datetime", thing["datetime"])
                    Solingen::setAttribute2(uuid, "targetuuid", thing["targetuuid"])
                    Solingen::setAttribute2(uuid, "value", thing["value"])
                end
            }
    end

    # NxTimePromises::show()
    def self.show()
        (Solingen::mikuTypeItems("NxTimeCapsule") + Solingen::mikuTypeItems("NxTimePromise"))
            .sort{|c1, c2| c1["unixtime"] <=> c2["unixtime"] }
            .each{|thing|
                if thing["mikuType"] == "NxTimeCapsule" then
                    board = NxPrincipals::getItemOrNull(thing["account"])
                    puts "#{Time.at(thing["unixtime"]).to_s} : #{thing["account"]} : #{thing["value"]}#{board ? " (#{board["description"]})" : ""}"
                end
                if thing["mikuType"] == "NxTimePromise" then
                    targetitem = Solingen::getItemOrNull(thing["targetuuid"])
                    if targetitem.nil? then
                        puts "Could not recover item for target uuid: #{item["targetuuid"]}"
                    end
                    puts "#{Time.at(thing["unixtime"]).to_s} : #{targetitem["description"]} : #{thing["value"]}"
                end
            }
        LucilleCore::pressEnterToContinue()
    end
end