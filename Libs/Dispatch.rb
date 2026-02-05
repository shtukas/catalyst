# encoding: UTF-8

class Dispatch

    # Dispatch::is_good_planning(items)
    def self.is_good_planning(items)
        false
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
        waves, tasks = items.partition{|item| item["mikuType"] == "Wave" }
        Dispatch::dispatch([], waves.clone, tasks.clone, tasks.clone + waves.clone)
    end
end
