# encoding: UTF-8

=begin
NxBackup
    - "uuid"         : String
    - "mikuType"     : "NxBackup"
    - "description"  : String
=end

class NxBackups

    # NxBackups::readUuidsFromFile()
    def self.filepath()
        "#{Config::pathToGalaxy()}/DataHub/Drives, Passwords, Backups and Lost Procedures.txt"
    end

    # NxBackups::descriptionsFromFiles()
    def self.descriptionsFromFiles()
        IO.read(filepath)
            .lines
            .map{|l| l.strip }
            .select{|l| l.include?("::") }
            .map{|line| line.split("::").first.strip }
    end


    # NxBackups::removeObsoleteItems()
    def self.removeObsoleteItems()
        descriptions = NxBackups::descriptionsFromFiles()
        Cubes2::mikuType("NxBackup").each{|item|
            if !descriptions.include?(item["description"]) then
                Cubes2::destroy(item["uuid"])
            end
        }
    end

    # NxBackups::buildMissingItems()
    def self.buildMissingItems()
        descriptionsFromFiles = NxBackups::descriptionsFromFiles()
        descriptionsFromItems = Cubes2::mikuType("NxBackup").map{|item| item["description"] }
        (descriptionsFromFiles - descriptionsFromItems).each{|description|
            uuid = SecureRandom.uuid
            Cubes2::itemInit(uuid, "NxBackup")
            Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
            Cubes2::setAttribute(uuid, "description", description)
        }
    end

    # NxBackups::maintenance()
    def self.maintenance()
        NxBackups::buildMissingItems()
        NxBackups::removeObsoleteItems()
    end

    # NxBackups::getPeriodForDescriptionOrNull(description)
    def self.getPeriodForDescriptionOrNull(description)
        line = IO.read(filepath)
                .lines
                .map{|l| l.strip }
                .select{|l| l.include?("::") }
                .select{|line| line.start_with?(description)}
                .first
        return nil if line.nil? 
        line.split("::")[1].strip.to_f
    end

    # NxBackups::getLastUnixtimeForDescriptionOrZero(description)
    def self.getLastUnixtimeForDescriptionOrZero(description)
        filepath = "#{Config::pathToCatalystDataRepository()}/backups-lastest-times/#{description}.txt"
        return 0 if !File.exist?(filepath)
        DateTime.parse(IO.read(filepath).strip).to_time.to_i
    end

    # NxBackups::setNowForDescription(description)
    def self.setNowForDescription(description)
        filepath = "#{Config::pathToCatalystDataRepository()}/backups-lastest-times/#{description}.txt"
        File.open(filepath, "w"){|f| f.puts(Time.new.utc.iso8601) }
    end

    # NxBackups::dueTime(item)
    def self.dueTime(item)
        NxBackups::getLastUnixtimeForDescriptionOrZero(item["description"]) + NxBackups::getPeriodForDescriptionOrNull(item["description"])*86400
    end

    # NxBackups::itemIsDue(item)
    def self.itemIsDue(item)
        NxBackups::dueTime(item) <= Time.new.to_i
    end

    # NxBackups::muiItems()
    def self.muiItems()
        Cubes2::mikuType("NxBackup").select{|item| NxBackups::itemIsDue(item) }
    end

    # NxBackups::toString(item)
    def self.toString(item)
        "💾 #{item["description"]} (every #{NxBackups::getPeriodForDescriptionOrNull(item["description"])} days; due: #{Time.at(NxBackups::dueTime(item)).utc.iso8601.gsub("T", " ")})"
    end
end
