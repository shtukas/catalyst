# encoding: UTF-8

class Dispatch

    # Dispatch::duration_average(entries)
    def self.duration_average(entries)
        entries = entries.select{|entry| entry["date"] < CommonUtils::today() }
        sum = entries.map{|entry| entry["mins"] }.sum
        sum.to_f/entries.size
    end

    # Dispatch::is_good_planning(items)
    def self.is_good_planning(items)
        # A good planning is defined as the last task end time is before 23:00 today
        # A task is defined as anything that is not a wave
        tasks_end_unixtime = Time.new.to_i
        items.each{|item|
            next if item["mikuType"] != "Wave"
            next if NxBalls::itemIsRunning(item)
            tasks_end_unixtime = tasks_end_unixtime + Dispatch::duration_average(item["durations-mins-40"]) * 60
        }
        deadline_unixtime = DateTime.parse("#{CommonUtils::today()} 23:00:00").to_time.to_i
        tasks_end_unixtime < deadline_unixtime
    end

    # Dispatch::dispatch(prefix, waves, tasks, fallback)
    def self.dispatch(prefix, waves, tasks, fallback)
        items = prefix.clone
        ws = waves.clone
        ts = tasks.clone
        loop {
            break if (ws + ts).empty?
            items << ws.shift
            items << ts.shift
        }
        items = items.compact
        if Dispatch::is_good_planning(items) then
            return Dispatch::dispatch((prefix + waves.take(1)).clone, waves.drop(1).clone, tasks.clone, items.clone)
        end
        fallback
    end

    # Dispatch::itemsForListing(items)
    def self.itemsForListing(items)
        if Time.new.hour >= 23 then
            return []
        end

        active, items = items.partition{|item| NxBalls::itemIsActive(item) }

        items = items.map{|item|
            if item["durations-mins-40"].nil? then
                durations = [{"date" => CommonUtils::nDaysInTheFuture(-1), "mins" => 20}]
                item["durations-mins-40"] = durations
                Blades::setAttribute(item["uuid"], "durations-mins-40", durations)
            end
            item
        }

        waves, tasks = items.partition{|item| item["mikuType"] == "Wave" }
        Dispatch::dispatch(active, waves.clone, tasks.clone, tasks.clone + waves.clone)
    end

    # Dispatch::incoming(item, duration_in_seconds)
    def self.incoming(item, duration_in_seconds)
        if item["durations-mins-40"].nil? then
            durations = [{"date" => CommonUtils::nDaysInTheFuture(-1), "mins" => 20}]
            item["durations-mins-40"] = durations
            Blades::setAttribute(item["uuid"], "durations-mins-40", durations)
        end
        if item["durations-mins-40"].last["date"] == CommonUtils::today() then
            last_entry = item["durations-mins-40"].last.clone
            last_entry["mins"] = last_entry["mins"] + duration_in_seconds.to_f/60
            item["durations-mins-40"] = item["durations-mins-40"].reverse.drop(1).reverse + [last_entry]
        else
            item["durations-mins-40"] = item["durations-mins-40"] + [{"date" => CommonUtils::today(), "mins" => duration_in_seconds.to_f/60}]
        end
        Blades::setAttribute(item["uuid"], "durations-mins-40", item["durations-mins-40"])
    end
end
