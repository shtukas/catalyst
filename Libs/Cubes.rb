# encoding: UTF-8

$ROWS_CACHE = {}

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
        return nil if Cubes1::deleteduuids().include?(uuid)
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
        return nil if rows.empty?
        rows
            .sort_by{|row| row["_updatetime_"] }
            .each{|row|
                item[row["_attrname_"]] = JSON.parse("#{row["_attrvalue_"]}")
            }
        item
    end

    # Cubes1::items()
    def self.items()
        duuids = Cubes1::deleteduuids()
        instancesFilepaths = Cubes1::getInstancesFilepaths()

        trace = "b674ef92-c8d9-4ef2-8d46-8c32b780f275:#{instancesFilepaths.sort}"
        if $ROWS_CACHE[trace] then
            return $ROWS_CACHE[trace].select{|item| !duuids.include?(item["uuid"]) }
        end

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
        items = structure.values.select{|item| !duuids.include?(item["uuid"]) }

        $ROWS_CACHE[trace] =  items

        items
    end

    # Cubes1::mikuType(mikuType)
    def self.mikuType(mikuType)
        Cubes1::items().select{|item| item["mikuType"] == mikuType }
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
        filepath = "#{Config::pathToCatalystDataRepository()}/DeletedCubes/#{(1000000*Time.new.to_f).to_i}.txt"
        File.open(filepath, "w"){|f| f.puts(uuid) }
    end

    # ----------------------------------------
    # Core

    # Cubes1::readRows(filepath)
    def self.readRows(filepath)

        return $ROWS_CACHE[filepath] if $ROWS_CACHE[filepath]

        #puts "reading #{filepath} from scratch".yellow

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

        $ROWS_CACHE[filepath] = rows

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

    # Cubes1::deleteduuids()
    def self.deleteduuids()
        LucilleCore::locationsAtFolder("#{Config::pathToCatalystDataRepository()}/DeletedCubes")
            .select{|filepath| filepath[-4, 4] == ".txt" }
            .map{|filepath| IO.read(filepath).strip }
    end
end

class Elizabeth

    def initialize(uuid)
        @uuid = uuid
    end

    def putBlob(datablob) # nhash
        Datablobs::putBlob(datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        Datablobs::getBlobOrNull(nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        raise "(error: ff339aa3-b7ea-4b92-a211-5fc1048c048b, nhash: #{nhash})"
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 900a9a53-66a3-4860-be5e-dffa7a88c66d) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
