# encoding: UTF-8

class Inbox

    # Inbox::repository()
    def self.repository()
        "/Users/pascal/Desktop/Inbox"
    end

    # Inbox::run(location)
    def self.run(location)
        time1 = Time.new.to_f

        domain = nil

        system("clear")
        puts location.green

        # -------------------------------------
        # Lookup
        if File.file?(location) then
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["open", "copy to desktop", "next step (default)"])
            if action == "open" then
                system("open '#{location}'")
            end
            if action == "copy to desktop" then
                FileUtils.cp(location, "/Users/pascal/Desktop")
            end
        else
            system("open '#{location}'")
        end

        # -------------------------------------
        # Dispatch

        locationToDescription = lambda{|location|
            description = File.basename(location)
            puts "description: #{description}"
            d = LucilleCore::askQuestionAnswerAsString("description (empty to ignore step) : ")
            if d.size > 0 then
                description = d
            end
            description
        }

        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["delete", "dispatch"])
        if action == "delete" then
            LucilleCore::removeFileSystemLocation(location)
        end
        if action == "dispatch" then
            target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", ["ondate", "communication", "todo"])
            if target == "ondate" then

                date = Dated::interactivelySelectADateOrNull()
                return nil if date.nil?

                atom = CoreData2::issueAionPointAtomUsingLocation(SecureRandom.hex, description, locationToDescription.call(location) [Dated::coreData2SetUUID()])
                atom["date"] = date
                CoreData2::commitAtom2(atom)

                puts JSON.pretty_generate(atom)
                LucilleCore::removeFileSystemLocation(location)
            end
            if target == "communication" then
                domain = Domain::interactivelySelectDomain()
                Nx50s::issuePriorityCommunicationItemUsingLocation(location, locationToDescription.call(location), domain)
                LucilleCore::removeFileSystemLocation(location)
            end
            if target == "todo" then
                unixtime = Nx50s::getNewUnixtime()
                domain = Domain::interactivelySelectDomain()
                Nx50s::issueItemUsingLocation(location, locationToDescription.call(location), unixtime, domain)
                LucilleCore::removeFileSystemLocation(location)
            end
        end

        if domain.nil? then 
            domain = Domain::interactivelySelectDomain()
        end
        account = Domain::domainToBankAccount(domain)
        time2 = Time.new.to_f
        timespan = time2 - time1
        puts "Putting #{timespan} seconds into #{account}"
        Bank::put(account, timespan)
    end

    # Inbox::ns16s()
    def self.ns16s()

        getLocationUUID = lambda{|location|
            uuid = KeyValueStore::getOrNull(nil, "54226eda-9437-4f64-9ab9-7e5141a15471:#{location}")
            return uuid.to_f if uuid
            uuid = SecureRandom.uuid
            KeyValueStore::set(nil, "54226eda-9437-4f64-9ab9-7e5141a15471:#{location}", uuid)
            uuid
        }

        getLocationUnixtime = lambda{|location|
            unixtime = KeyValueStore::getOrNull(nil, "54226eda-9437-4f64-9ab9-7e5141a15471:#{location}")
            return unixtime.to_f if unixtime
            unixtime = Time.new.to_f
            KeyValueStore::set(nil, "54226eda-9437-4f64-9ab9-7e5141a15471:#{location}", unixtime)
            unixtime
        }

        LucilleCore::locationsAtFolder(Inbox::repository())
            .map{|location|
                announce = "[inbx] #{File.basename(location)}"
                {
                    "uuid"         => getLocationUUID.call(location),
                    "NS198"        => "ns16:inbox1",
                    "unixtime"     => getLocationUnixtime.call(location),
                    "announce"     => announce,
                    "commands"     => [".."],
                    "location"     => location
                }
            }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # Inbox::nx19s()
    def self.nx19s()
        Inbox::ns16s().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => item["announce"],
                "lambda"   => lambda { Inbox::run(item) }
            }
        }
    end
end
