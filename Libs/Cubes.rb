# encoding: UTF-8

class Cubes1

    # ----------------------------------------
    # Interface

    # Cubes1::itemInit(uuid, mikuType)
    def self.itemInit(uuid, mikuType)
        Cubes1::setAttribute(uuid, "uuid", uuid)
        Cubes1::setAttribute(uuid, "mikuType", mikuType)
    end

    # Cubes1::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        item = {}
        rows = []
        Cubes1::getDataFilepaths().each{|filepath|
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

        item
    end

    # Cubes1::items()
    def self.items()

        instancesFilepaths = Cubes1::getDataFilepaths()
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
        
        structure.values.select{|item| !item["IS-DELETED"] }
    end

    # Cubes1::mikuType(mikuType)
    def self.mikuType(mikuType)
        Cubes1::items().select{|item| item["mikuType"] == mikuType }
    end

    # Cubes1::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        filepath = Cubes1::newDatabase()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("insert into Attributes (_recorduuid_, _updatetime_, _itemuuid_, _attrname_, _attrvalue_) values (?, ?, ?, ?, ?)", [SecureRandom.hex, Time.new.to_f, uuid, attrname, JSON.generate(attrvalue)])
        db.close
    end

    # Cubes1::getAttributeOrNull(uuid, attrname)
    def self.getAttributeOrNull(uuid, attrname)
        rows = []
        Cubes1::getDataFilepaths().each{|filepath|
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

    # Cubes1::getDataFilepaths()
    def self.getDataFilepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToCatalystDataRepository()}/Attributes-20240523")
            .select{|location| location[-8, 8] == ".sqlite3" }
    end

    # Cubes1::getInstanceFilepathMakeIfMissing()
    def self.getInstanceFilepathMakeIfMissing()
        filepath = Cubes1::getDataFilepaths()
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

    # Cubes1::newDatabase()
    def self.newDatabase()
        filepath = "#{Config::pathToCatalystDataRepository()}/Attributes-20240523/#{CommonUtils::timeStringL22()}.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table Attributes (_recorduuid_ string primary key, _updatetime_ float, _itemuuid_ string, _attrname_ string, _attrvalue_ string)")
        db.close
        filepath
    end

    # Cubes1::merge(filepath1, filepath2)
    def self.merge(filepath1, filepath2)

        # We copy the data from filepath2 into filepath1 and delete filepath2

        db1 = SQLite3::Database.new(filepath1)
        db1.busy_timeout = 117
        db1.busy_handler { |count| true }
        db1.results_as_hash = true

        db2 = SQLite3::Database.new(filepath2)
        db2.busy_timeout = 117
        db2.busy_handler { |count| true }
        db2.results_as_hash = true
        db2.execute("select * from Attributes", []) do |row|
            db1.execute("insert into Attributes (_recorduuid_, _updatetime_, _itemuuid_, _attrname_, _attrvalue_) values (?, ?, ?, ?, ?)", [SecureRandom.hex, row["_updatetime_"], row["_itemuuid_"], row["_attrname_"], row["_attrvalue_"]])
        end
        db2.close

        db1.close

        FileUtils.rm(filepath2)
    end

    # Cubes1::reduceDataFiles()
    def self.reduceDataFiles()
        filepaths = Cubes1::getDataFilepaths()
        return if filepaths.size < 2
        Cubes1::merge(filepaths[0], filepaths[1])
    end
end
