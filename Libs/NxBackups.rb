
class NxBackups

    # NxBackups::datafilepath()
    def self.datafilepath()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/Drives, Passwords, Backups and Lost Procedures.txt"
    end

    # NxBackups::instructions()
    def self.instructions()
        IO.read(NxBackups::datafilepath())
            .lines
            .select{|line| line.include?("::") }
            .map{|line|  
                parts = line.split("::").map{|t| t.strip }
                {
                    "operation" => parts[1],
                    "periodInDays" => parts[0].to_f,
                }
            }
    end

    # NxBackups::items()
    def self.items()
        BladeAdaptation::mikuTypeItems("NxBackup")
    end

    # NxBackups::getItemByOperationOrNull(operation)
    def self.getItemByOperationOrNull(operation)
        NxBackups::items()
            .select{|item|
                item["description"] == operation
            }
            .first
    end

    # NxBackups::getInstructionByOperationOrNull(operation)
    def self.getInstructionByOperationOrNull(operation)
        NxBackups::instructions()
            .select{|instruction| instruction["operation"] == operation }
            .first
    end

    # NxBackups::destroy(uuid)
    def self.destroy(uuid)
        Blades::destroy(uuid)
    end

    # NxBackups::dataMaintenance()
    def self.dataMaintenance()

        # -----------------------------------------------
        # In the first stage we just check that every instruction has a corresponding NxBackup with 
        # the right period

        NxBackups::instructions()
            .each{|instruction|
                item = NxBackups::getItemByOperationOrNull(instruction["operation"])
                if item then
                    if item["periodInDays"] != instruction["periodInDays"] then
                        Blades::setAttribute2(item["uuid"], "periodInDays", instruction["periodInDays"])
                    end
                else
                    uuid  = SecureRandom.uuid
                    Blades::init("NxBackup", uuid)
                    Blades::setAttribute2(uuid, "unixtime", Time.new.to_i)
                    Blades::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
                    Blades::setAttribute2(uuid, "description", instruction["operation"])
                    Blades::setAttribute2(uuid, "periodInDays", periodInDays)
                    Blades::setAttribute2(uuid, "periodInDays", instruction["periodInDays"])
                    Blades::setAttribute2(uuid, "lastDoneUnixtime", 0)
                end
            }

        # In the second stage we are checking that each item has a corresponsing instruction
        NxBackups::items()
            .select{|item| NxBackups::getInstructionByOperationOrNull(item["description"]).nil? }
            .each{|item| Blades::destroy(item["uuid"]) }
    end

    # NxBackups::toString(item)
    def self.toString(item)
        "(backup) #{item["description"]}"
    end

    # NxBackups::listingItems()
    def self.listingItems()
        NxBackups::items()
            .select{|item| Time.new.to_i >= (item["lastDoneUnixtime"] + item["periodInDays"]*86400) }
    end

    # NxBackups::performDone(item)
    def self.performDone(item)
        Blades::setAttribute2(item["uuid"], "lastDoneUnixtime", Time.new.to_i)
    end
end
