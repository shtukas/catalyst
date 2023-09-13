
class EventPublisher

    # EventPublisher::root()
    def self.root()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Events"
    end

    # EventPublisher::publish(event)
    def self.publish(event)
        timefragment = "#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y-%m")}/#{Time.new.strftime("%Y-%m-%d")}"
        folder1 = LucilleCore::indexsubfolderpath("#{EventPublisher::root()}/#{timefragment}", 100)
        filepath1 = "#{folder1}/#{CommonUtils::timeStringL22()}.json"
        File.open(filepath1, "w"){|f| f.puts(JSON.pretty_generate(event)) }
    end
end
