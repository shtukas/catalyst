
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
        N3Objects::getMikuType("NxBackup")
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

    # NxBackups::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxBackups::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
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
                        item["periodInDays"] = instruction["periodInDays"]
                        N3Objects::commit(item)
                    end
                else
                    item = {
                        "uuid"        => SecureRandom.uuid,
                        "mikuType"    => "NxBackup",
                        "unixtime"    => Time.new.to_i,
                        "datetime"    => Time.new.utc.iso8601,
                        "description" => instruction["operation"],
                        "periodInDays"     => instruction["periodInDays"],
                        "lastDoneUnixtime" => 0
                    }
                    N3Objects::commit(item)
                end
            }

        # In the second stage we are checking that each item has a corresponsing instruction
        NxBackups::items()
            .select{|item| NxBackups::getInstructionByOperationOrNull(item["description"]).nil? }
            .each{|item| N3Objects::destroy(item["uuid"]) }
    end

    # NxBackups::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxBackup",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
        }
        puts JSON.pretty_generate(item)
        NxBackups::commit(item)
        item
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
        item["lastDoneUnixtime"] = Time.new.to_i
        N3Objects::commit(item)
    end
end
