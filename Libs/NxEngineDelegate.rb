class NxEngineDelegate

    # NxEngineDelegate::issue(targetuuid, capacity_in_seconds)
    def self.issue(targetuuid, capacity_in_seconds)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "targetuuid", targetuuid)
        Items::setAttribute(uuid, "capacity", capacity_in_seconds)
        Items::setAttribute(uuid, "mikuType", "NxEngineDelegate")
        item = Items::itemOrNull(uuid)
        item
    end

    # ----------------------
    # Data

    # NxEngineDelegate::icon()
    def self.icon()
        "👩🏻‍💻"
    end

    # NxEngineDelegate::toString(item)
    def self.toString(item)
        formatx = lambda {|number|
            (number.to_f/3600).round(2)
        }

        target = Items::itemOrNull(item["targetuuid"])
        "#{NxEngineDelegate::icon()} deleguate for #{target["description"]} (capacity: #{formatx.call(item["capacity"])} hs, done: #{formatx.call(Bank::getValue(item["uuid"]))} hs)"
    end

    # NxEngineDelegate::listingItems()
    def self.listingItems()
        identityOrNull = lambda { |item|
            target = Items::itemOrNull(item["targetuuid"])
            if target.nil? then
                puts "delete delegate (reason: target not found)".yellow
                Items::deleteItem(item["uuid"])
                return nil
            end
            if NxEngines::ratio(target) >= 1 then
                puts "delete delegate for #{target["description"]} (reason: exeeding ratio)".yellow
                Items::deleteItem(item["uuid"])
                return nil
            end
            item
        }
        Items::mikuType("NxEngineDelegate")
            .map{|item| identityOrNull.call(item) }
            .compact
    end

    # NxEngineDelegate::total_capacity_for_targetuuid(targetuuid)
    def self.total_capacity_for_targetuuid(targetuuid)
        Items::mikuType("NxEngineDelegate")
            .select{|item| item["targetuuid"] == targetuuid }
            .map{|item| item["capacity"] }
            .inject(0, :+)
    end
end
