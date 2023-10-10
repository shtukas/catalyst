
class EventsTimelineProcessor

    # EventsTimelineProcessor::eventsTimelineLocation()
    def self.eventsTimelineLocation()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/events-timeline"
    end

    # EventsTimelineProcessor::firstFilepathOrNull()
    def self.firstFilepathOrNull()
        LucilleCore::locationsAtFolder(EventsTimelineProcessor::eventsTimelineLocation()).sort.each{|locationYear|
            LucilleCore::locationsAtFolder(locationYear).sort.each{|locationMonth|
                LucilleCore::locationsAtFolder(locationMonth).sort.each{|locationDay|
                    LucilleCore::locationsAtFolder(locationDay).sort.each{|locationIndexFolder|
                        LucilleCore::locationsAtFolder(locationIndexFolder)
                        .select{|location| File.basename(location).start_with?("2") }
                        .sort.each{|eventfilepath|
                            return eventfilepath
                        }
                        if LucilleCore::locationsAtFolder(locationIndexFolder).empty? then
                            LucilleCore::removeFileSystemLocation(locationIndexFolder)
                        end
                    }
                    if LucilleCore::locationsAtFolder(locationDay).empty? then
                        LucilleCore::removeFileSystemLocation(locationDay)
                    end
                }
                if LucilleCore::locationsAtFolder(locationMonth).empty? then
                    LucilleCore::removeFileSystemLocation(locationMonth)
                end
            }
            if LucilleCore::locationsAtFolder(locationYear).empty? then
                LucilleCore::removeFileSystemLocation(locationYear)
            end
        }
        nil
    end

    # EventsTimelineProcessor::digestEvent(event)
    def self.digestEvent(event)

        if event["eventType"] == "DoNotShowUntil2" then
            targetId = event["payload"]["targetId"]
            unixtime = event["payload"]["unixtime"]

            filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/DoNotShowUntil.sqlite3"
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "delete from DoNotShowUntil where _id_=?", [targetId]
            db.execute "insert into DoNotShowUntil (_id_, _unixtime_) values (?, ?)", [targetId, unixtime]
            db.close
            return
        end

        if event["eventType"] == "ItemInit" then
            uuid = event["payload"]["uuid"]
            mikuType = event["payload"]["mikuType"]

            # We need to deal with attributes and instructions appearing out of order
            # In particular we could have created a phantom item when we received the attribute update, before the init

            item = Catalyst::itemOrNull(uuid)
            if item.nil? then
                item = {
                    "uuid"     => uuid,
                    "mikuType" => mikuType
                }
            else
                item["mikuType"] = mikuType
            end

            filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/Items.sqlite3"
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "delete from Items where _uuid_=?", [itemuuid]
            db.execute "insert into Items (_uuid_, _mikuType_, _item_) values (?, ?, ?)", [item["uuid"], item["mikuType"], JSON.generate(item)]
            db.close
            return
        end

        if event["eventType"] == "ItemAttributeUpdate" then
            itemuuid = event["payload"]["itemuuid"]
            attname  = event["payload"]["attname"]
            attvalue = event["payload"]["attvalue"]
            item = Catalyst::itemOrNull(itemuuid)
            if item.nil? then
                item = {
                    "uuid"     => itemuuid,
                    "mikuType" => "NxThePhantomMenace",
                    "unixtime" => Time.new.to_i
                }
            end
            item[attname] = attvalue
            filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/Items.sqlite3"
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "delete from Items where _uuid_=?", [itemuuid]
            db.execute "insert into Items (_uuid_, _mikuType_, _item_) values (?, ?, ?)", [item["uuid"], item["mikuType"], JSON.generate(item)]
            db.close
            return
        end

        if event["eventType"] == "ItemDestroy2" then
            itemuuid = event["payload"]["uuid"]
            filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/Items.sqlite3"
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "delete from Items where _uuid_=?", [itemuuid]
            db.close
            return
        end

        if event["eventType"] == "BankDeposit" then
            uuid = event["payload"]["uuid"]
            date = event["payload"]["date"]
            value = event["payload"]["value"]
            filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/Bank.sqlite3"
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "insert into Bank (_recorduuid_, _id_, _date_, _value_) values (?, ?, ?, ?)", [SecureRandom.uuid, uuid, date, value]
            db.close
            return
        end

        raise "(error: 0d1295ae-b021-42f7-b419-3214ac0a917f) cannot digest event: #{event}"
    end

    # EventsTimelineProcessor::procesLine()
    def self.procesLine()
        loop {
            filepath = EventsTimelineProcessor::firstFilepathOrNull()
            return if filepath.nil?
            puts "processing: #{filepath}"
            event = JSON.parse(IO.read(filepath))
            return if (Time.new.to_i - event["unixtime"]) < 300
            EventsTimelineProcessor::digestEvent(event)
            FileUtils.rm(filepath)
        }
    end
end


