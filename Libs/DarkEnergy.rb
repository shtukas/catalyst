# encoding: UTF-8

# create table energy (uuid string primary key, mikuType string, item string);

class PositiveSpace

    # PositiveSpace::databaseFilepath()
    def self.databaseFilepath()
        filepath = LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkEnergy/01-database")
                    .select{|location| location[-8, 8] == ".sqlite3" }
                    .first
        if filepath.nil? then
            raise "PositiveSpace could not locate database"
        end
        filepath
    end

    # PositiveSpace::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # PositiveSpace::getFirstJournalItemOrNull()
    def self.getFirstJournalItemOrNull()
        LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkEnergy/02-journal")
            .select{|location| location[-5, 5] == ".json" }
            .sort
            .first
    end

    # PositiveSpace::database_destroy(uuid)
    def self.database_destroy(uuid)
        db = SQLite3::Database.new(PositiveSpace::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from energy where uuid=?", [uuid]
        db.close
    end

    # PositiveSpace::database_commit(item)
    def self.database_commit(item)
        db = SQLite3::Database.new(PositiveSpace::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from energy where uuid=?", [item["uuid"]]
        db.execute "insert into energy (uuid, mikuType, item) values (?, ?, ?)", [item["uuid"], item["mikuType"], JSON.generate(item)]
        db.close
    end

    # PositiveSpace::isLeaderInstance()
    def self.isLeaderInstance()
        JSON.parse(IO.read("/Users/pascal/Galaxy/DataBank/Stargate-Config.json"))["isLeaderInstance"]
    end

    # PositiveSpace::maintenance()
    def self.maintenance()
        return if !PositiveSpace::isLeaderInstance()
        loop {
            filepath = PositiveSpace::getFirstJournalItemOrNull()
            break if filepath.nil?
            puts "PositiveSpace::maintenance(): journal process: #{filepath}"
            item = JSON.parse(IO.read(filepath))
            if item["mikuType"] == "NxDeleted" then
                PositiveSpace::database_destroy(item["uuid"])
            else
                PositiveSpace::database_commit(item)
            end
            FileUtils.rm(filepath)
        }

    end
end

class DarkEnergy

    # DarkEnergy::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        # First we read the database and then we read the journal

        filepath = PositiveSpace::databaseFilepath()

        item = nil
        db = SQLite3::Database.new(PositiveSpace::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from energy where uuid=?", [uuid]) do |row|
            item = JSON.parse(row["item"])
        end
        db.close

        LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkEnergy/02-journal")
            .select{|location| location[-5, 5] == ".json" }
            .sort
            .each{|filepath|
                i = JSON.parse(IO.read(filepath))
                if i["uuid"] == uuid then
                    if i["mikuType"] == "NxDeleted" then
                        return nil
                    else
                        item = i
                    end
                    
                end
            }

        item
    end

    # DarkEnergy::commit(item)
    def self.commit(item)
        folderpath = "#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkEnergy/02-journal"
        filename = "#{PositiveSpace::timeStringL22()}.item.json"
        filepath = "#{folderpath}/#{filename}"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # DarkEnergy::mikuType(mikuType)
    def self.mikuType(mikuType)
        items = []
        db = SQLite3::Database.new(PositiveSpace::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from energy where mikuType=?", [mikuType]) do |row|
            items << JSON.parse(row["item"])
        end
        db.close

        LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkEnergy/02-journal")
            .select{|location| location[-5, 5] == ".json" }
            .sort
            .each{|filepath|
                i = JSON.parse(IO.read(filepath))
                if i["mikuType"] == "NxDeleted" then
                    # This item that carry the NxDeleted, we do not know what was its mikuType before it was deleted
                    # So we are always doing the reject
                    items = items.reject{|x| x["uuid"] == i["uuid"] }
                else
                    if i["mikuType"] == mikuType then
                        items = items.reject{|x| x["uuid"] == i["uuid"]} + [i]
                    end
                end
            }

        items
    end

    # DarkEnergy::all()
    def self.all()
        items = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from energy", []) do |row|
            items << JSON.parse(row["item"])
        end
        db.close

        LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkEnergy/02-journal")
            .select{|location| location[-5, 5] == ".json" }
            .sort
            .each{|filepath|
                i = JSON.parse(IO.read(filepath))
                if i["mikuType"] == "NxDeleted" then
                    # This item that carry the NxDeleted, we do not know what was its mikuType before it was deleted
                    # So we are always doing the reject
                    items = items.reject{|x| x["uuid"] == i["uuid"] }
                else
                    items = items.reject{|x| x["uuid"] == i["uuid"]} + [item]
                end
            }

        items
    end

    # DarkEnergy::destroy(uuid)
    def self.destroy(uuid)
        item = {
            "uuid"     => uuid,
            "mikuType" => "NxDeleted"
        }
        folderpath = "#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkEnergy/02-journal"
        filename = "#{PositiveSpace::timeStringL22()}.delete.json"
        filepath = "#{folderpath}/#{filename}"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # -------------------------------------------

    # DarkEnergy::init(mikuType, uuid)
    def self.init(mikuType, uuid)
        item = {
            "uuid"     => uuid,
            "mikuType" => mikuType
        }
        DarkEnergy::commit(item)
    end

    # DarkEnergy::patch(uuid, attribute, value)
    def self.patch(uuid, attribute, value)
        item = DarkEnergy::itemOrNull(uuid)
        return if item.nil?
        item[attribute] = value
        DarkEnergy::commit(item)
    end

    # DarkEnergy::getAttribute(uuid, attribute)
    def self.getAttribute(uuid, attribute)
        item = DarkEnergy::itemOrNull(uuid)
        return nil if item.nil?
        item[attribute]
    end

    # DarkEnergy::mikuTypeCount(mikuType)
    def self.mikuTypeCount(mikuType)
        DarkEnergy::mikuType(mikuType).size
    end
end
