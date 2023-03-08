
# encoding: UTF-8

class DevicesBackups

    # DevicesBackups::filepath()
    def self.filepath()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/Drives, Passwords, Backups and Lost Procedures.txt"
    end

    # DevicesBackups::instructions()
    def self.instructions()
        IO.read(DevicesBackups::filepath())
            .lines
            .select{|line| line.include?("::") }
            .map{|line|  
                parts = line.split("::").map{|t| t.strip }
                {
                    "period" => parts[0].to_f,
                    "operation" => parts[1]
                }
            }            
    end

    # DevicesBackups::listingItems()
    def self.listingItems()
        DevicesBackups::instructions()
            .map{|instruction|
                {
                    "uuid"       => instruction["operation"],
                    "mikuType"   => "DeviceBackup",
                    "announce"   => "(backup) #{instruction["operation"]}",
                    "instruction" => instruction
                }
            }
    end

end
