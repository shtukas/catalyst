# encoding: UTF-8

class Backups

    # Backups::listingItems()
    def self.listingItems()
        return [] if !Config::isPrimaryInstance()
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/Drives, Passwords, Backups and Lost Procedures.txt"
        IO.read(filepath)
            .lines
            .map{|l| l.strip }
            .select{|l| l.include?("::") }
            .map{|line| 
                period, description = line.split("::").map{|token| token.strip }
                uuid = Digest::SHA1.hexdigest("9c12395e-06c8-4ea3-b57f-a16f99012186:#{description}")
                {
                    "uuid" => uuid,
                    "mikuType" => "Backup",
                    "description" => description,
                    "period" => period.to_f,
                    "lastDoneUnixtime" => XCache::getOrDefaultValue("1c959874-c958-469f-967a-690d681412ca:#{uuid}", "0").to_f
                }
            }
            .select{|item|
                Time.new.to_i >= item["lastDoneUnixtime"] + item["period"]*86400
            }
    end

    # Backups::toString(item)
    def self.toString(item)
        "💾 #{item["description"]}"
    end
end
