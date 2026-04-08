
# encoding: UTF-8

# This class is used to monitor the inner processes of palmer. 

class PalmerMonitor

    # PalmerMonitor::is_working(path_to_ping)
    def self.is_working(path_to_ping)
        (Time.new.to_i - DateTime.parse(IO.read(path_to_ping)).to_time.to_i) < 3600
    end

    # PalmerMonitor::get_package()
    def self.get_package()
        JSON.parse(IO.read("#{Config::pathToGalaxy()}/DataHub/Catalyst/data/palmer-package.json"))
    end

    # PalmerMonitor::printreport()
    def self.printreport()
        PalmerMonitor::get_package().each{|packet|
            # {"ocean-path" => "data-server/triton/ping.txt", "name" => "triton"}
            if !PalmerMonitor::is_working(packet["path-to-ping"]) then
                puts "palmer: I am not seeing #{packet["name"]} active at #{packet["path-to-ping"]}. Last ping at #{IO.read(packet["path-to-ping"])}"
            end
        }
    end

end
