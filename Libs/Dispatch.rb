
=begin

notification
    ["update", <uuid>]
    ["destroy", <uuid>]

=end

class Dispatch

    # Dispatch::dispatchToInstance(instanceId, notification)
    def self.dispatchToInstance(instanceId, notification)
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/Catalyst/data/Dispatch/#{instanceId}/#{SecureRandom.hex}.json"
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
                            .map{|filepath| JSON.parse(IO.read(filepath)) }
        updateuuids = notifications
                        .select{|notification| notification[0] == "update" }
                        .map{|notification| notification[1] }
                        .uniq # nice one Pascal!

        destroyuuids = notifications
                        .select{|notification| notification[0] == "destroy" }
                        .map{|notification| notification[1] }
                        .uniq # nice one Pascal!

        updateuuids.each{|uuid| HardProblem::blade_has_been_updated(uuid) }

        destroyuuids.each{|uuid| HardProblem::blade_has_been_destroyed(uuid) }
    end
end
