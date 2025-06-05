# encoding: UTF-8

class Index

    # Index::getDataBaseFilepathInitiateIfNeeded()
    def self.getDataBaseFilepathInitiateIfNeeded()
        filepath = XCache::filepath("fe6740df-ac63-485a-8baf-87fda1fcecf6:#{CommonUtils::today()}")
        if !File.exist?(filepath)
            puts "Initiating new database file: #{filepath}".yellow
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            #db.transaction
            db.execute("create table attributes (_uuid_ TEXT, _attribute_ TEXT, _value_ TEXT);", [])
            #db.commit
            Blades::items_enumerator().each{|item|
                puts "bulding index: registering item: #{item["uuid"]}".yellow
                item.each{|attribute, value|
                    #db.execute("delete from attributes where _uuid_=? and _attribute_=?", [item["uuid"], attribute])
                    db.execute("insert into attributes (_uuid_, _attribute_, _value_) values (?, ?, ?)", [item["uuid"], attribute, JSON.generate(value)])
                }
            }
            db.close
        end
        filepath
    end

    # Index::commitItemToIndex(item)
    def self.commitItemToIndex(item)
        item.each{|attrname, attrvalue|
            Index::setAttribute(item["uuid"], attrname, attrvalue)
        }
    end

    # Index::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        item = nil
        db = SQLite3::Database.new(Index::getDataBaseFilepathInitiateIfNeeded())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from attributes where _uuid_=?", [uuid]) do |row|
            item = item || {}
            item[row["_attribute_"]] = JSON.parse(row["_value_"])
        end
        db.close
        item
    end

    # Index::items()
    def self.items()
        data = {}
        db = SQLite3::Database.new(Index::getDataBaseFilepathInitiateIfNeeded())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from attributes", []) do |row|
            uuid = row["_uuid_"]
            data[uuid] = data[uuid] || {}
            data[uuid][row["_attribute_"]] = JSON.parse(row["_value_"])
        end
        db.close
        data.values
    end

    # Index::mikuType(mikuType)
    def self.mikuType(mikuType)
        Index::items().select{|item| item["mikuType"] == mikuType }
    end

    # Index::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        db = SQLite3::Database.new(Index::getDataBaseFilepathInitiateIfNeeded())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from attributes where _uuid_=? and _attribute_=?", [uuid, attrname])
        db.execute("insert into attributes (_uuid_, _attribute_, _value_) values (?, ?, ?)", [uuid, attrname, JSON.generate(attrvalue)])
        db.commit
        db.close
    end

    # Index::destroy(uuid)
    def self.destroy(uuid)
        puts "Index: destroying uuid: #{uuid}".yellow
        db = SQLite3::Database.new(Index::getDataBaseFilepathInitiateIfNeeded())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from attributes where _uuid_=?", [uuid])
        db.commit
        db.close
    end
end

