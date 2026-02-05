# encoding: UTF-8

class Dispatch

    # Dispatch::duration_average(entries)
    def self.duration_average(entries)
        entries = entries.select{|entry| entry["date"] < CommonUtils::today() }
        sum = entries.map{|entry| entry["mins"] }.sum
        sum.to_f/entries.size
    end

    # Dispatch::is_good_sequence(items)
    def self.is_good_sequence(items)
        cursor_end_task = Time.new.to_i
        cursor_end_task_non_wave = Time.new.to_i
        items.each{|item|
            cursor_end_task = cursor_end_task + Dispatch::duration_average(item["durations-mins-40"]) * 60
            if item["mikuType"] != "Wave" then
                cursor_end_task_non_wave = cursor_end_task
            end
        }
        deadline_unixtime = DateTime.parse("#{CommonUtils::today()} 22:00:00").to_time.to_i
        cursor_end_task_non_wave < deadline_unixtime
    end

    # Dispatch::merge(head, a1, a2)
    def self.merge(head, a1, a2)
        return head if (a1+a2).empty?
        Dispatch::merge(head + a1.take(1) + a2.take(1), a1.drop(1), a2.drop(1))
    end

    # Dispatch::dispatch(prefix, waves, tasks, depth, fallback)
    def self.dispatch(prefix, waves, tasks, depth, fallback)
        items = prefix + Dispatch::merge([], waves.take(depth), tasks + waves.drop(depth))
        if Dispatch::is_good_sequence(items) then
            return Dispatch::dispatch(prefix, waves, tasks, depth+1, items)
        end
        fallback
    end

    # Dispatch::itemsForListing(items)
    def self.itemsForListing(items)
        if Time.new.hour >= 23 then
            return []
        end

        return [] if items.empty?

        active, items = items.partition{|item| NxBalls::itemIsActive(item) }

        if active.size > 0 then
            return active + items.sort_by{|item| XCache::getOrDefaultValue("dispatch-start-unixtime:96282efed924:#{CommonUtils::today()}:#{item["uuid"]}", 0) }
        end

        items = items.map{|item|
            if item["durations-mins-40"].nil? then
                durations = [{"date" => CommonUtils::nDaysInTheFuture(-1), "mins" => 20}]
                item["durations-mins-40"] = durations
                Blades::setAttribute(item["uuid"], "durations-mins-40", durations)
            end
            item
        }

        waves, tasks = items.partition{|item| item["mikuType"] == "Wave" }
        items = Dispatch::dispatch(active, waves, tasks, 1, active + tasks + waves)

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
