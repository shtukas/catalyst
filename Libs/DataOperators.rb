
# encoding: UTF-8

class DoNotShowUntilOperator
    # @data = Map[id, unixtime]

    def initialize()
        @data = {}

        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/DoNotShowUntil.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from DoNotShowUntil", []) do |row|
            @data[row["_id_"]] = row["_unixtime_"]
        end
        db.close
    end

    def set(id, unixtime)
        @data[id] = unixtime
    end

    def getUnixtimeOrNull(id)
        @data[id]
    end
end

class BankOperator
    # @data = Array[Datum]
    # Datum = {id, date, value}

    def initialize()
        @data = []

        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/Bank.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Bank", []) do |row|
            @data << {
                "id"    => row["_id_"],
                "date"  => row["_date_"],
                "value" => row["_value_"]
            }
        end
        db.close
    end

    def deposit(uuid, date, value)
        @data << {
            "id"    => uuid,
            "date"  => date,
            "value" => value
        }
    end

    def getValueAtDate(uuid, date)
        @data
            .select{|datum| datum["id"] == uuid and datum["date"] == date }
            .map{|datum| datum["value"] }
            .inject(0, :+)
    end

    def getValue(uuid)
        @data
            .select{|datum| datum["id"] == uuid }
            .map{|datum| datum["value"] }
            .inject(0, :+)
    end
end

class ItemsOperator
    # @data = Array[Item]

    def initialize()
        @data = []

        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/Items.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items", []) do |row|
            @data << JSON.parse(row["_item_"])
        end
        db.close
    end

    def itemAttributeUpdate(itemuuid, attname, attvalue)
        @data = @data.map{|item|
            if item["uuid"] == itemuuid then
                item[attname] = attvalue
            end
            item
        }
    end

    def destroy(itemuuid)
        @data = @data.select{|item| item["uuid"] != itemuuid }
    end

    def init(uuid, mikuType)
        @data << {
            "uuid"     => uuid,
            "mikuType" => mikuType
        }
    end

    def setItem(item)
        @data = @data.reject{|i| i["uuid"] == item["uuid"] } + [item]
    end

    def itemOrNull(uuid)
        @data.select{|item| item["uuid"] == uuid }.first
    end

    def mikuType(mikuType)
        @data.select{|item| item["mikuType"] == mikuType }
    end

    def all()
        @data
    end
end
