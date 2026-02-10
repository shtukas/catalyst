# encoding: UTF-8

class Dispatch

    # Dispatch::decide_duration_in_mins(item)
    def self.decide_duration_in_mins(item)
        todayComputedDemandInHours = XCache::getOrNull("today-demain-in-hours-112c8ddfee17:#{CommonUtils::today()}:#{item["uuid"]}")
        if todayComputedDemandInHours then
            todayComputedDemandInHours = todayComputedDemandInHours.to_f
            return todayComputedDemandInHours * 60
        end

        entries = item["durations-mins-40"]
        entries = entries.select{|entry| entry["date"] < CommonUtils::today() }
        sum = entries.map{|entry| entry["mins"] }.sum
        sum.to_f/entries.size
    end

    # Dispatch::decide_deadline_or_null()
    def self.decide_deadline_or_null()
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
        nil
    end

    # Dispatch::sequence_meets_deadline(items, deadline)
    def self.sequence_meets_deadline(items, deadline)
        cursor_end_task = Time.new.to_i
        cursor_end_task_non_wave = Time.new.to_i
        items.each{|item|
            cursor_end_task = cursor_end_task + Dispatch::decide_duration_in_mins(item) * 60
            if item["mikuType"] != "Wave" then
                cursor_end_task_non_wave = cursor_end_task
            end
        }
        cursor_end_task_non_wave < deadline["unixtime"]
    end

    # Dispatch::dispatch(prefix, waves, tasks, depth, deadline)
    def self.dispatch(prefix, waves, tasks, depth, deadline)
        return prefix + tasks if waves.empty?
        return prefix + waves + tasks if depth > waves.size
        return prefix + waves + tasks if deadline.nil?
        if Dispatch::sequence_meets_deadline(prefix + waves.take(depth+1) + tasks + waves.drop(depth+1), deadline) then
            return Dispatch::dispatch(prefix, waves, tasks, depth+1, deadline)
        end
        prefix + waves.take(depth) + tasks + waves.drop(depth)
    end

    # Dispatch::itemsForListing(items)
    def self.itemsForListing(items)

        active, items = items.partition{|item| NxBalls::itemIsActive(item) or (item["mikuType"] == "Wave" and item["interruption"]) }

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

        deadline = Dispatch::decide_deadline_or_null()

        waves, tasks = items.partition{|item| item["mikuType"] == "Wave" }
        items = Dispatch::dispatch(active, waves, tasks, 0, deadline)

        if XCache::getOrNull("c416f157-735f-49c3-9270-92e3968c7b82:#{CommonUtils::today()}").nil? then
            cursor = Time.new.to_i
            items.each{|item|
                XCache::set("dispatch-start-unixtime:96282efed924:#{CommonUtils::today()}:#{item["uuid"]}", cursor)
                cursor = cursor + Dispatch::decide_duration_in_mins(item) * 60
            }
            XCache::set("c416f157-735f-49c3-9270-92e3968c7b82:#{CommonUtils::today()}", "true")
        end

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
