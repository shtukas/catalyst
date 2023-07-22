
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

    # NxBackups::getItemByOperationOrNull(operation)
    def self.getItemByOperationOrNull(operation)
        BladesItemised::mikuType("NxBackup")
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

    # NxBackups::maintenance()
    def self.maintenance()

        # -----------------------------------------------
        # In the first stage we just check that every instruction has a corresponding NxBackup with 
        # the right period

        NxBackups::instructions()
            .each{|instruction|
                item = NxBackups::getItemByOperationOrNull(instruction["operation"])
                if item then
                    if item["periodInDays"] != instruction["periodInDays"] then
                        BladesGI::setAttribute2(item["uuid"], "periodInDays", instruction["periodInDays"])
                    end
                else
                    uuid  = SecureRandom.uuid
                    BladesGI::init("NxBackup", uuid)
                    BladesGI::setAttribute2(uuid, "unixtime", Time.new.to_i)
                    BladesGI::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
                    BladesGI::setAttribute2(uuid, "description", instruction["operation"])
                    BladesGI::setAttribute2(uuid, "periodInDays", instruction["periodInDays"])
                    BladesGI::setAttribute2(uuid, "lastDoneUnixtime", 0)
                end
            }

        # In the second stage we are checking that each item has a corresponsing instruction
        BladesItemised::mikuType("NxBackup")
            .select{|item| NxBackups::getInstructionByOperationOrNull(item["description"]).nil? }
            .each{|item| BladesItemised::destroy(item["uuid"]) }
    end

    # NxBackups::toString(item)
    def self.toString(item)
        "💾 #{item["description"]}"
    end

    # NxBackups::listingItems()
    def self.listingItems()
        BladesItemised::mikuType("NxBackup")
            .select{|item| Time.new.to_i >= (item["lastDoneUnixtime"] + item["periodInDays"]*86400) }
    end

    # NxBackups::performDone(item)
    def self.performDone(item)
        BladesGI::setAttribute2(item["uuid"], "lastDoneUnixtime", Time.new.to_i)
    end

    # NxBackups::program(item)
    def self.program(item)
        loop {
            puts PolyFunctions::toString(item).green
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["perform done"])
            return if action.nil?
            if action == "perform done" then
                NxBackups::performDone(item)
            end
        }
    end
end
