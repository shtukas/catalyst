# encoding: UTF-8

class Cubes1

    # Cubes1::datatrace()
    def self.datatrace()
        Digest::SHA1.hexdigest(Cubes1::getInstancesFilepaths().join(":"))
    end

    # ----------------------------------------
    # Interface

    # Cubes1::itemInit(uuid, mikuType)
    def self.itemInit(uuid, mikuType)
        Cubes1::setAttribute(uuid, "uuid", uuid)
        Cubes1::setAttribute(uuid, "mikuType", mikuType)
    end

    # Cubes1::itemOrNull(datatrace, uuid)
    def self.itemOrNull(datatrace, uuid)

        #puts "Cubes1::itemOrNull(#{datatrace}, #{uuid}) (from memory)".yellow

        if datatrace and InMemoryCache::getOrNull("31e555b3-5e19-44f2-84af-7d1dcd98b45e:#{datatrace}:#{uuid}") then
            item = InMemoryCache::getOrNull("31e555b3-5e19-44f2-84af-7d1dcd98b45e:#{datatrace}:#{uuid}")
            if item == "NOTHING" then
                return nil
            end
            return item
        end

        #puts "Cubes1::itemOrNull(#{datatrace}, #{uuid}) (from disk)".yellow

        item = {}
        rows = []
        Cubes1::getInstancesFilepaths().each{|filepath|
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from Attributes where _itemuuid_=?", [uuid]) do |row|
                rows << row
                #row = {
                #    "_recorduuid_"
                #    "_updatetime_"
                #    "_itemuuid_"
                #    "_attrname_"
                #    "_attrvalue_"
                #}
            end
            db.close
        }
        if rows.empty? then
            InMemoryCache::set("31e555b3-5e19-44f2-84af-7d1dcd98b45e:#{datatrace}:#{uuid}", "NOTHING")
            return nil
        end
        rows
            .sort_by{|row| row["_updatetime_"] }
            .each{|row|
                item[row["_attrname_"]] = JSON.parse("#{row["_attrvalue_"]}")
            }

        if item["IS-DELETED"] then
            item = nil
        end

        if datatrace then
            InMemoryCache::set("31e555b3-5e19-44f2-84af-7d1dcd98b45e:#{datatrace}:#{uuid}", item || "NOTHING")
        end

        item
    end

    # Cubes1::items(datatrace)
    def self.items(datatrace)

        if datatrace and InMemoryCache::getOrNull("0a702a6f-943b-4897-9693-e0f3a564f5cc:#{datatrace}") then
            return InMemoryCache::getOrNull("0a702a6f-943b-4897-9693-e0f3a564f5cc:#{datatrace}")
        end

        #puts "Cubes1::items(#{datatrace}) (from disk)".yellow

        instancesFilepaths = Cubes1::getInstancesFilepaths()
        rows = []
        structure = {}
        instancesFilepaths.each{|filepath|
            rows = rows + Cubes1::readRows(filepath)
        }
        rows
            .sort_by{|row| row["_updatetime_"] }
            .each{|row|
                if structure[row["_itemuuid_"]].nil? then
                    structure[row["_itemuuid_"]] = {}
                end
                structure[row["_itemuuid_"]][row["_attrname_"]] = JSON.parse("#{row["_attrvalue_"]}")
            }
        
        items = structure.values.select{|item| !item["IS-DELETED"] }

        if datatrace then
            InMemoryCache::set("0a702a6f-943b-4897-9693-e0f3a564f5cc:#{datatrace}", items)
        end

        items
    end

    # Cubes1::mikuType(datatrace, mikuType)
    def self.mikuType(datatrace, mikuType)
        if datatrace and InMemoryCache::getOrNull("076692b1-ba75-4f94-bf16-e5d6ff33fcd9:#{datatrace}:#{mikuType}") then
            return InMemoryCache::getOrNull("076692b1-ba75-4f94-bf16-e5d6ff33fcd9:#{datatrace}:#{mikuType}")
        end

        #puts "Cubes1::mikuType(#{datatrace}, #{mikuType}) (from disk)".yellow

        items = Cubes1::items(datatrace).select{|item| item["mikuType"] == mikuType }

        if datatrace then
            InMemoryCache::set("076692b1-ba75-4f94-bf16-e5d6ff33fcd9:#{datatrace}:#{mikuType}", items)
        end

        items
    end

    # Cubes1::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        filepath = Cubes1::getInstanceFilepathMakeIfMissing()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("insert into Attributes (_recorduuid_, _updatetime_, _itemuuid_, _attrname_, _attrvalue_) values (?, ?, ?, ?, ?)", [SecureRandom.hex, Time.new.to_f, uuid, attrname, JSON.generate(attrvalue)])
        db.close

        # Renaming to keep the file content addressed for caching
        FileUtils.mv(filepath, "#{Config::pathToCatalystDataRepository()}/Attributes-20240523/#{CommonUtils::today()}-#{Config::thisInstanceId()}-#{Digest::SHA1.file(filepath).hexdigest}.sqlite3")
    end

    # Cubes1::getAttributeOrNull(uuid, attrname)
    def self.getAttributeOrNull(uuid, attrname)
        rows = []
        Cubes1::getInstancesFilepaths().each{|filepath|
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from Attributes where _itemuuid_=? and _attrname_=?", [uuid, attrname]) do |row|
                rows << row
                #row = {
                #    "_recorduuid_"
                #    "_updatetime_"
                #    "_itemuuid_"
                #    "_attrname_"
                #    "_attrvalue_"
                #}
            end
            db.close
        }
        return nil if rows.empty?
        JSON.parse(rows.sort_by{|row| row["_updatetime_"] }.first["_attrvalue_"])
    end

    # Cubes1::destroy(uuid)
    def self.destroy(uuid)
        Cubes1::setAttribute(uuid, "IS-DELETED", true)
    end

    # ----------------------------------------
    # Core

    # Cubes1::readRows(filepath)
    def self.readRows(filepath)
        rows = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Attributes", []) do |row|
            # It's strange that I need to duplicate the object like this otherwise I get Ruby kernel error 🤔
            rows << {
                "_recorduuid_" => row["_recorduuid_"],
                "_updatetime_" => row["_updatetime_"],
                "_itemuuid_"   => row["_itemuuid_"],
                "_attrname_"   => row["_attrname_"],
                "_attrvalue_"  => row["_attrvalue_"]
            }
        end
        db.close
        rows
    end

    # Cubes1::getInstancesFilepaths()
    def self.getInstancesFilepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToCatalystDataRepository()}/Attributes-20240523")
            .select{|location| location[-8, 8] == ".sqlite3" }
    end

    # Cubes1::getInstanceFilepathMakeIfMissing()
    def self.getInstanceFilepathMakeIfMissing()
        filepath = Cubes1::getInstancesFilepaths()
                    .select{|filepath|
                        File.basename(filepath).include?("#{CommonUtils::today()}-#{Config::thisInstanceId()}")
                    }
                    .first
        return filepath if filepath
        filepath = "#{Config::pathToCatalystDataRepository()}/Attributes-20240523/#{CommonUtils::today()}-#{Config::thisInstanceId()}.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table Attributes (_recorduuid_ string primary key, _updatetime_ float, _itemuuid_ string, _attrname_ string, _attrvalue_ string)")
        db.close
        filepath
    end
end
