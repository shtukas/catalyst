
=begin

notification
{
    "unixtime": Integer
    "type"    : "update" | "destroy"
    "uuid"    : String,
}

=end

class Dispatch

    # Dispatch::dispatchToInstance(instanceId, notification)
    def self.dispatchToInstance(instanceId, notification)
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/Catalyst/data/Dispatch/#{instanceId}/#{CommonUtils::timeStringL22()}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.generate(notification)) }
    end

    # Dispatch::dispatch(notification)
    def self.dispatch(notification)
        Config::instanceIds().each{|instanceId|
            if instanceId != Config::thisInstanceId() then
                Dispatch::dispatchToInstance(instanceId, notification)
            end
        }
    end



    # Dispatch::pickup()
    def self.pickup()
        directory = "#{Config::userHomeDirectory()}/Galaxy/DataHub/Catalyst/data/Dispatch/#{Config::thisInstanceId()}"

        processFilepath = lambda{|updateduuids, filepath|
            notification = JSON.parse(IO.read(filepath))
            # HardProblem changes keys everyday,
            # We keep notifications that are less than a day old
            # This helps maintaining the queue of rarely used instances, small
            if (Time.new.to_i - notification["unixtime"]) > 86400 then
                FileUtils.rm(filepath)
                return updateduuids
            end

            if notification["type"] == "update" then
                uuid = notification["uuid"]
                if updateduuids.include?(uuid) then
                    FileUtils.rm(filepath)
                    return updateduuids + [uuid]
                end
                HardProblem::blade_has_been_updated(uuid)
                FileUtils.rm(filepath)
                return updateduuids + [uuid]
            end

            if notification["type"] == "destroy" then
                HardProblem::blade_has_been_destroyed(notification["uuid"])
                FileUtils.rm(filepath)
                return updateduuids
            end

            raise "[error: 296d7914]"
        }

        LucilleCore::locationsAtFolder(directory)
            .select{|filepath| filepath[-5, 5] == ".json" }
            .reduce([]){|updateduuids, filepath|
                processFilepath.call(updateduuids, filepath)
            }
    end
end
