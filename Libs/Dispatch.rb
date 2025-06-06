
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
        LucilleCore::locationsAtFolder(directory)
            .select{|filepath| filepath[-5, 5] == ".json" }
            .each{|filepath|
                notification = JSON.parse(IO.read(filepath))
                puts "notification: #{notification.to_s}".yellow
                if notification[0] == "update" then
                    HardProblem::blade_has_been_updated(notification[1])
                end
                if notification[0] == "destroy" then
                    HardProblem::blade_has_been_destroyed(notification[1])
                end
                FileUtils.rm(filepath)
            }
    end
end
