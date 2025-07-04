
class Nx2133

    # ----------------------------------------------
    # Decisions

    # Nx2133::decideDurationInMinutes(item)
    def self.decideDurationInMinutes(item)
        if item["nx0607-duration"] then
            item["nx0607-duration"]
        end
        if item["mikuType"] == "NxTask" and item["nx2290-important"] then
            return 60
        end
        duration = LucilleCore::askQuestionAnswerAsString("Duration for '#{PolyFunctions::toString(item).green}' (in mins): ").to_f
        Items::setAttribute(item["uuid"], "nx0607-duration", duration)
        duration
    end

    # Nx2133::decideDeadlineOrNull(item)
    def self.decideDeadlineOrNull(item)
        if item["nx2133"] then
            if item["nx2133"]["date"] == CommonUtils::today() then
                return item["nx2133"]["deadline"]
            end
        end
        if item["mikuType"] == "NxTask" and item["nx2290-important"] then
            t1 = Time.new.to_i
            t2 = CommonUtils::unixtimeAtLastMidnightAtLocalTimezone() + 21*3600
            tx = t1 + rand * (t2-t1)
            deadline = Time.at(tx).utc.iso8601
            return deadline
        end
        if item["mikuType"] == "NxDated" then
            t1 = Time.new.to_i
            t2 = CommonUtils::unixtimeAtLastMidnightAtLocalTimezone() + 18*3600
            tx = t1 + rand * (t2-t1)
            deadline = Time.at(tx).utc.iso8601
            return deadline
        end
        nil
    end

    # Nx2133::decideNx(item)
    def self.decideNx(item)
        duration = Nx2133::decideDurationInMinutes(item)
        deadline = Nx2133::decideDeadlineOrNull(item)
        {
            "date"     => CommonUtils::today(),
            "position" => rand,
            "duration" => duration,
            "deadline" => deadline # optional
        }
    end

    # ----------------------------------------------
    # Data

    # Nx2133::getNx(item)
    def self.getNx(item)
        if item["nx2133"] then
            if item["nx2133"]["date"] == CommonUtils::today() then
                return item["nx2133"]
            end
        end
        nx2133 = Nx2133::decideNx(item)
        Items::setAttribute(item["uuid"], "nx2133", nx2133)
        nx2133
    end

    # Nx2133::suffix(item)
    def self.suffix(item)
        if item["nx2133"] then
            nx = item["nx2133"]
            " (#{item["nx2133"]["position"]}, #{item["nx2133"]["duration"]}, #{item["nx2133"]["deadline"]})".yellow
        else
            ""
        end
    end

    # ----------------------------------------------
    # Updates

    # Nx2133::permute(items, i1, i2)
    def self.permute(items, i1, i2)
        # The two items remain in place but exchange their nx2133's positions
        item1 = items[i1]
        item2 = items[i2]
        nx1 = item1["nx2133"]
        nx2 = item2["nx2133"]
        position1 = nx1["position"]
        position2 = nx2["position"]
        nx1["position"] = position2
        nx2["position"] = position1
        Items::setAttribute(item1["uuid"], "nx2133", nx1)
        Items::setAttribute(item2["uuid"], "nx2133", nx2)
        item1["nx2133"] = nx1
        item2["nx2133"] = nx2
        items[i1] = item1
        items[i2] = item2
        items
    end

    # Nx2133::ensureItemsWithDeadlinesInOrder(items)
    def self.ensureItemsWithDeadlinesInOrder(items)
        return [] if items.empty?
        (0..items.size-1).each{|i|
            (i..items.size-1).each{|j|
                if items[i]["nx2133"]["deadline"] and items[j]["nx2133"]["deadline"] and items[i]["nx2133"]["deadline"] > items[j]["nx2133"]["deadline"] then
                    items = Nx2133::permute(items, i, j)
                end
            }
        }
        items
    end

    # Nx2133::updates(items)
    def self.updates(items)
        Nx2133::ensureItemsWithDeadlinesInOrder(items)
    end

end
