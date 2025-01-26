# encoding: UTF-8

=begin

Updates:
    {
        "updateType": "init",
        "uuid"       : String,
        "mikuType"   : String
    }

    {
      "updateType": "set-attribute",
      "uuid"       : String,
      "attrname"   : String,
      "attrvalue"  : String
    }

    {
        "updateType": "destroy",
        "uuid"       : String,
    }
=end

class Items

    # ----------------------------------------
    # Core

    # Keep this file absolutely in sync with the same in Nyx

    # Items::commitItemToDatabase(item)
    def self.commitItemToDatabase(item)
        filepath = "#{Config::pathToCatalystDataRepository()}/Items/20240607-155704-609823.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from Items where _uuid_=?", [item["uuid"]])
        db.execute("insert into Items (_uuid_, _mikuType_, _item_) values (?, ?, ?)", [item["uuid"], item["mikuType"], JSON.generate(item)])
        db.commit
        db.close
    end

    # Items::itemFromDatabaseOrNull(uuid)
    def self.itemFromDatabaseOrNull(uuid)
        item = nil
        db = SQLite3::Database.new("#{Config::pathToCatalystDataRepository()}/Items/20240607-155704-609823.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items where _uuid_=?", [uuid]) do |row|
            item = JSON.parse(row["_item_"])
        end
        db.close
        item
    end

    # Items::deleteItemInDatabase(uuid)
    def self.deleteItemInDatabase(uuid)
        filepath = "#{Config::pathToCatalystDataRepository()}/Items/20240607-155704-609823.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from Items where _uuid_=?", [uuid])
        db.commit
        db.close
    end

    # Items::issueUpdate(update)
    def self.issueUpdate(update)
        filepath = "#{Config::pathToCatalystDataRepository()}/Items/#{CommonUtils::timeStringL22()}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(update)) }
    end

    # Items::attributesJournal()
    def self.attributesJournal()
        LucilleCore::locationsAtFolder("#{Config::pathToCatalystDataRepository()}/Items")
            .select{|location| location[-5, 5] == ".json" }
            .sort
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # Items::upgradeItemsWithAttributesJournal(items, journal)
    def self.upgradeItemsWithAttributesJournal(items, journal)
        items = items + journal.select{|update| update["updateType"] == "init" }
        journal.each{|update|
            if update["updateType"] == "set-attribute" then
                uuid = update["uuid"]
                attrname = update["attrname"]
                attrvalue = update["attrvalue"]
                items = items.map{|item|
                    if item["uuid"] == uuid then
                        item[attrname] = attrvalue
                    end
                    item
                }
            end
            if update["updateType"] == "destroy" then
                uuid = update["uuid"]
                items = items.select{|item| item["uuid"] != uuid}
            end
        }
        items
    end

    # ----------------------------------------
    # Interface

    # Keep this file absolutely in sync with the same in Nyx

    # Items::itemInit(uuid, mikuType)
    def self.itemInit(uuid, mikuType)
        update = {
            "updateType" => "init",
            "uuid" => uuid,
            "mikuType" => mikuType
        }
        Items::issueUpdate(update)
    end

    # Items::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        item = nil
        db = SQLite3::Database.new("#{Config::pathToCatalystDataRepository()}/Items/20240607-155704-609823.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items where _uuid_=?", [uuid]) do |row|
            item = JSON.parse(row["_item_"])
        end
        db.close
        Items::upgradeItemsWithAttributesJournal([item].compact, Items::attributesJournal())
            .select{|item| item["uuid"] == uuid }
            .first
    end

    # Items::items()
    def self.items()
        databasefilepath = "#{Config::pathToCatalystDataRepository()}/Items/20240607-155704-609823.sqlite3"

        trace = LucilleCore::locationsAtFolder("#{Config::pathToCatalystDataRepository()}/Items")
                        .reduce(""){|trace, location| Digest::SHA1.hexdigest("#{trace}:#{File.mtime(location)}") }

        items = InMemoryCache::getOrNull("5ab5557d-d9aa-46a6-abbe-fef363620d98:#{trace}")
        return items if items

        items = []
        db = SQLite3::Database.new(databasefilepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items", []) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
        items = Items::upgradeItemsWithAttributesJournal(items, Items::attributesJournal())

        InMemoryCache::set("5ab5557d-d9aa-46a6-abbe-fef363620d98:#{trace}", items)
        items
    end

    # Items::mikuType(mikuType)
    def self.mikuType(mikuType)
        databasefilepath = "#{Config::pathToCatalystDataRepository()}/Items/20240607-155704-609823.sqlite3"

        trace = LucilleCore::locationsAtFolder("#{Config::pathToCatalystDataRepository()}/Items")
                        .reduce(""){|trace, location| Digest::SHA1.hexdigest("#{trace}:#{File.mtime(location)}") }

        items = InMemoryCache::getOrNull("41182940-e0f0-4acc-8a22-699797d25baf:#{trace}:#{mikuType}")
        return items if items

        items = []
        db = SQLite3::Database.new("#{Config::pathToCatalystDataRepository()}/Items/20240607-155704-609823.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items where _mikuType_=?", [mikuType]) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
        items = Items::upgradeItemsWithAttributesJournal(items, Items::attributesJournal())
            .select{|item| item["mikuType"] == mikuType }

        InMemoryCache::set("41182940-e0f0-4acc-8a22-699797d25baf:#{trace}:#{mikuType}", items)
        items
    end

    # Items::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        update = {
            "updateType" => "set-attribute",
            "uuid" => uuid,
            "attrname" => attrname,
            "attrvalue" => attrvalue
        }
        Items::issueUpdate(update)
    end

    # Items::destroy(uuid)
    def self.destroy(uuid)
        update = {
            "updateType" => "destroy",
            "uuid" => uuid,
        }
        Items::issueUpdate(update)
        Datablobs::deleteFile(uuid)
    end

    # Items::processJournal()
    def self.processJournal()
        LucilleCore::locationsAtFolder("#{Config::pathToCatalystDataRepository()}/Items")
            .select{|location| location[-5, 5] == ".json" }
            .map{|filepath|
                update = JSON.parse(IO.read(filepath))

                puts JSON.pretty_generate(update).yellow

                if update["updateType"] == "init" then
                    item = {
                        "uuid" => update["uuid"],
                        "mikuType" => update["mikuType"]
                    }
                    Items::commitItemToDatabase(item)
                end

                if update["updateType"] == "set-attribute" then
                    uuid = update["uuid"]
                    attrname = update["attrname"]
                    attrvalue = update["attrvalue"]
                    item = Items::itemFromDatabaseOrNull(uuid)
                    if item then
                        item[attrname] = attrvalue
                        Items::commitItemToDatabase(item)
                    end
                end

                if update["updateType"] == "destroy" then
                    uuid = update["uuid"]
                    Items::deleteItemInDatabase(uuid)
                end

                FileUtils.rm(filepath)
            }
    end
end
