# encoding: UTF-8

class NxBackups

    # NxBackups::readUuidsFromFile()
    def self.filepath()
        "#{Config::pathToGalaxy()}/DataHub/Drives, Passwords, Backups and Lost Procedures.txt"
    end

    # NxBackups::readUuidsFromFile()
    def self.readUuidsFromFile()
        IO.read(filepath)
            .lines
            .map{|l| l.strip }
            .select{|l| l.include?("::") }
            .map{|line| 
                period, description = line.split("::").map{|token| token.strip }
                Digest::SHA1.hexdigest("9c12395e-06c8-4ea3-b57f-a16f99012186:#{description}")
            }
    end

    # NxBackups::maintenance()
    def self.maintenance()
        NxBackups::buildMissingItems()
        NxBackups::removeObsoleteItems()
    end

    # NxBackups::buildMissingItems()
    def self.buildMissingItems()
        missinguuids = NxBackups::readUuidsFromFile() - Cubes2::mikuType("NxBackup").map{|item| item["uuid"] }
        IO.read(filepath)
            .lines
            .map{|l| l.strip }
            .select{|l| l.include?("::") }
            .map{|line| 
                period, description = line.split("::").map{|token| token.strip }
                uuid = Digest::SHA1.hexdigest("9c12395e-06c8-4ea3-b57f-a16f99012186:#{description}")
                next if !missinguuids.include?(uuid)
                puts "Creating missing NxBackup: #{line}"
                Cubes2::itemInit(uuid, "NxBackup")
                Cubes2::setAttribute(uuid, "description", description)
                Cubes2::setAttribute(uuid, "periodInDays", period.to_f)
            }
    end

    # NxBackups::removeObsoleteItems()
    def self.removeObsoleteItems()
        (Cubes2::mikuType("NxBackup").map{|item| item["uuid"] } - NxBackups::readUuidsFromFile()).each{|uuid|
            Cores::destroy(uuid)
        }
    end

    # NxBackups::listingItems()
    def self.listingItems()
        Cubes2::mikuType("NxBackup")
    end

    # NxBackups::toString(item)
    def self.toString(item)
        "💾 #{item["description"]}"
    end
end
