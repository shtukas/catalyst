# encoding: UTF-8

class Dispatch

    # Dispatch::duration_average(entries)
    def self.duration_average(entries)
        entries = entries.select{|entry| entry["date"] < CommonUtils::today() }
        sum = entries.map{|entry| entry["mins"] }.sum
        sum.to_f/entries.size
    end

    # Dispatch::decide_deadline()
    def self.decide_deadline()
        if Time.new.hour < 12 then
            unixtime = DateTime.parse("#{CommonUtils::today()} 12:00:00").to_time.to_i
            return {
                "unixtime" => unixtime,
                "datetime" => Time.at(unixtime).to_s
            }
        end
        if Time.new.hour < 16 then
            unixtime = DateTime.parse("#{CommonUtils::today()} 16:00:00").to_time.to_i
            return {
                "unixtime" => unixtime,
                "datetime" => Time.at(unixtime).to_s
            }
        end
        if Time.new.hour < 22 then
            unixtime = DateTime.parse("#{CommonUtils::today()} 21:00:00").to_time.to_i
            return {
                "unixtime" => unixtime,
                "datetime" => Time.at(unixtime).to_s
            }
        end
    end

    # Dispatch::sequence_meets_deadline(items, deadline_unixtime)
    def self.sequence_meets_deadline(items, deadline_unixtime)
        cursor_end_task = Time.new.to_i
        cursor_end_task_non_wave = Time.new.to_i
        items.each{|item|
            cursor_end_task = cursor_end_task + Dispatch::duration_average(item["durations-mins-40"]) * 60
            if item["mikuType"] != "Wave" then
                cursor_end_task_non_wave = cursor_end_task
            end
        }
        cursor_end_task_non_wave < deadline_unixtime
    end

    # Dispatch::dispatch(prefix, waves, tasks, depth, fallback, deadline)
    def self.dispatch(prefix, waves, tasks, depth, fallback, deadline)
        return fallback if waves.empty?
        return fallback if depth > waves.size
        items = prefix + waves.take(depth) + tasks + waves.drop(depth)
        if Dispatch::sequence_meets_deadline(items, deadline["unixtime"]) then
            return Dispatch::dispatch(prefix, waves, tasks, depth+1, items, deadline)
        end
        fallback
    end

    # Dispatch::itemsForListing(items)
    def self.itemsForListing(items)

        # From 22:00 we only return waves

        if Time.new.hour >= 22 then
            return items.select{|item| item["mikuType"] == "Wave" }
        end

        active, items = items.partition{|item| NxBalls::itemIsActive(item) }

        if active.size > 0 then
            return active + items.sort_by{|item| XCache::getOrDefaultValue("dispatch-start-unixtime:96282efed924:#{CommonUtils::today()}:#{item["uuid"]}", 0).to_i }
        end

        items = items.map{|item|
            if item["durations-mins-40"].nil? then
                durations = [{"date" => CommonUtils::nDaysInTheFuture(-1), "mins" => 20}]
                item["durations-mins-40"] = durations
                Blades::setAttribute(item["uuid"], "durations-mins-40", durations)
            end
            item
        }

        deadline = Dispatch::decide_deadline()

        waves, tasks = items.partition{|item| item["mikuType"] == "Wave" and !item["interruption"] }
        items = Dispatch::dispatch(active, waves, tasks, 1, active + tasks + waves, deadline)

        cursor = Time.new.to_i
        items.map{|item|
            XCache::set("dispatch-start-unixtime:96282efed924:#{CommonUtils::today()}:#{item["uuid"]}", cursor)
            cursor = cursor + Dispatch::duration_average(item["durations-mins-40"]) * 60
        }

        items
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
