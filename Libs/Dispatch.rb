
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

        notifications = LucilleCore::locationsAtFolder(directory)
                            .select{|filepath| filepath[-5, 5] == ".json" }
                            .map{|filepath|
                                notification = JSON.parse(IO.read(filepath))
                                # HardProblem changes keys everyday,
                                # We keep notifications that are less than a day old
                                # This helps maintaining the queue of rarely used instances, small
                                if (Time.new.to_i - notification["unixtime"]) < 86400 then
                                    notification
                                else
                                    FileUtils.rm(filepath)
                                    nil
                                end
                            }
                            .compact

        updateuuids = notifications
                        .select{|notification| notification["type"] == "update" }
                        .map{|notification| notification["uuid"] }
                        .uniq

        destroyuuids = notifications
                        .select{|notification| notification["type"] == "destroy" }
                        .map{|notification| notification["uuid"] }
                        .uniq

        updateuuids.each{|uuid| HardProblem::blade_has_been_updated(uuid) }

        destroyuuids.each{|uuid| HardProblem::blade_has_been_destroyed(uuid) }
    end
end
