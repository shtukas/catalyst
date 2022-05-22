
# encoding: UTF-8

class AlexandraDidactSynchronization

    # AlexandraDidactSynchronization::run()
    def self.run()

        puts "AlexandraDidactSynchronization::run() is not going to run until we implement the new Didact-DataBank-Type1-Interface"
        LucilleCore::pressEnterToContinue()
        return

        # --------------------------------------------------------------------------------------

        # Tx46 track the state, more exactly the trace, of a Edition Desk location. This is how we detect which ones have been dead for a while and can be deleted
        # Tx46 = {
        #     "name"     : String
        #     "trace"    : String
        #     "unixtime" : String
        # }

        issueNewTx46 = lambda {|location|
            tx46 = {
                "name"     => File.basename(location),
                "trace"    => Utils::locationTrace(location),
                "unixtime" => Time.new.to_i
            }
            XCache::set("5981674c-998c-4275-9890-b33ee4a6486f:#{location}", JSON.generate(tx46))
            tx46
        }

        getExistingLocationTx46OrNull = lambda{|location|
            item = XCache::getOrNull("5981674c-998c-4275-9890-b33ee4a6486f:#{location}")
            if item then
                return JSON.parse(item)
            end
            nil
        }

        getLocationTx46 = lambda{|location|
            item = XCache::getOrNull("5981674c-998c-4275-9890-b33ee4a6486f:#{location}")
            if item then
                tx46 = JSON.parse(item)
                trace = Utils::locationTrace(location)
                if tx46["trace"] != trace then
                    issueNewTx46.call(location)
                else
                    tx46
                end
            else
                issueNewTx46.call(location)
            end
        }

        puts "Edition Desk processing".green
        LucilleCore::locationsAtFolder(EditionDesk::pathToEditionDesk()).each{|location|
            puts "Edition Desk processing: #{File.basename(location)}"
            tx46 = getExistingLocationTx46OrNull.call(location)
            next if (tx46 and Utils::locationTrace(location) == tx46["trace"])
            EditionDesk::updateItemFromDeskLocationOrNothing(location)
            tx46 = getLocationTx46.call(location)
            #puts "tx46: #{JSON.pretty_generate(tx46)}"
            #puts "last change #{(Time.new.to_i - tx46["unixtime"]).to_f/86400} days ago"
            if (Time.new.to_i - tx46["unixtime"]) > 86400*14 then # 2 weeks
                puts "    Last change was #{(Time.new.to_i - tx46["unixtime"]).to_f/86400} days ago"
                puts "    Deleting Edition Desk location: #{File.basename(location)}"
                LucilleCore::removeFileSystemLocation(location)
            end
        }
    end
end
