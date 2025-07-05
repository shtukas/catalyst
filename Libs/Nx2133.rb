
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
            return item["nx2133"]["deadline"]
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

    # Nx2133::determineFirstPosition()
    def self.determineFirstPosition()
        items = Items::items()
        return 0.9 if items.empty?
        items
            .map{|item|
                nx2133 = Nx2133::getNxOrNull(item)
                if nx2133 then
                    nx2133["position"]
                else
                    nil
                end
            }
            .compact
            .min
    end

    # Nx2133::determineLastPosition()
    def self.determineLastPosition()
        items = Items::items()
        return 0.9 if items.empty?
        items
            .map{|item|
                nx2133 = Nx2133::getNxOrNull(item)
                if nx2133 then
                    nx2133["position"]
                else
                    nil
                end
            }
            .compact
            .max
    end

    # Nx2133::makeNx(item)
    def self.makeNx(item)
        duration = Nx2133::decideDurationInMinutes(item)
        deadline = Nx2133::decideDeadlineOrNull(item)
        lastPosition = Nx2133::determineLastPosition()
        {
            "position" => lastPosition + rand * (1 - lastPosition),
            "duration" => duration,
            "deadline" => deadline # optional
        }
    end

    # Nx2133::makeTopNx2133(durationInMinutes, deadline)
    def self.makeTopNx2133(durationInMinutes, deadline)
        {
            "position" => Nx2133::determineFirstPosition() * 0.9, # We work with the assumption that the positions are positive
            "duration" => durationInMinutes,
            "deadline" => deadline
        }
    end

    # Nx2133::makeNextNx2133(durationInMinutes, deadline)
    def self.makeNextNx2133(durationInMinutes, deadline)
        lastPosition = Nx2133::determineLastPosition()
        {
            "position" => lastPosition + rand * (1 - lastPosition), # We work with the assumption that the positions are in (0, 1)
            "duration" => durationInMinutes,
            "deadline" => deadline
        }
    end

    # ----------------------------------------------
    # Data

    # Nx2133::getNxOrNull(item)
    def self.getNxOrNull(item)
        if item["nx2133"] then
            return item["nx2133"]
        end
        nil
    end

    # Nx2133::getNx(item)
    def self.getNx(item)
        nx2133 = Nx2133::getNxOrNull(item)
        return nx2133 if nx2133
        nx2133 = Nx2133::makeNx(item)
        Items::setAttribute(item["uuid"], "nx2133", nx2133)
        nx2133
    end

    # Nx2133::suffix(item)
    def self.suffix(item)
        if item["nx2133"] then
            nx = item["nx2133"]
            lateStatus = item["nx2133"]["deadline"] ? (  item["nx2133"]["deadline"] < Time.new.utc.iso8601 ? " [late]".red : "" ) : ""
            " (#{item["nx2133"]["position"]}, #{item["nx2133"]["duration"]}, #{item["nx2133"]["deadline"]})".yellow + lateStatus
        else
            ""
        end
    end

    # ----------------------------------------------
    # Updates

    # Nx2133::permutePositions(items, i1, i2)
    def self.permutePositions(items, i1, i2)
        # The two items remain in place but exchange their nx2133's positions
        item1 = items[i1]
        item2 = items[i2]
        nx1 = item1["nx2133"]
        nx2 = item2["nx2133"]
        position1 = nx1["position"]
        position2 = nx2["position"]
        nx1["position"] = position2
        nx2["position"] = position1
        item1["nx2133"] = nx1
        item2["nx2133"] = nx2
        items[i1] = item1
        items[i2] = item2
        items
    end

    # Nx2133::ensureDeadlineOrdering(items)
    def self.ensureDeadlineOrdering(items)
        return [] if items.empty?
        (0..items.size-1).each{|i|
            (i..items.size-1).each{|j|
                if items[i]["nx2133"]["deadline"] and items[j]["nx2133"]["deadline"] and items[i]["nx2133"]["deadline"] > items[j]["nx2133"]["deadline"] then
                    #puts "ensure deadline ordering: permute: '#{PolyFunctions::toString(items[i]).green}'' and '#{PolyFunctions::toString(items[j]).green}'".yellow
                    items = Nx2133::permutePositions(items, i, j)
                    mutationHasOccured = true
                end
            }
        }
        items
    end

    # Nx2133::ensureDeadlineProjections1(items, indx, time)
    def self.ensureDeadlineProjections1(items, indx, time)
        # Time represents the time at which we start the item at position indx
        if items[indx]["nx2133"]["deadline"] and items[indx]["nx2133"]["deadline"] < Time.at(time).utc.iso8601 and items[indx-1]["nx2133"]["deadline"].nil? then
            #puts "ensure deadline projections: permute: '#{PolyFunctions::toString(items[indx-1]).green}' and '#{PolyFunctions::toString(items[indx]).green}'".yellow
            items = Nx2133::permutePositions(items, indx-1, indx)
        end
        items
    end

    # Nx2133::ensureDeadlineProjections2(items)
    def self.ensureDeadlineProjections2(items)
        return items if items.size < 2
        time = Time.new.to_i + items[0]["nx2133"]["duration"] * 60
        (1..items.size-1).each{|indx|
            items = Nx2133::ensureDeadlineProjections1(items, indx, time)
            time = time + items[indx-1]["nx2133"]["duration"] * 60
        }
        items
    end

    # Nx2133::optimiseNonDeadlinesPlacement1(items, indx, time)
    def self.optimiseNonDeadlinesPlacement1(items, indx, time)
        # Time represents the time at which we start the item at position indx
        if items[indx]["nx2133"]["deadline"] and items[indx+1]["nx2133"]["deadline"].nil? and items[indx]["nx2133"]["deadline"] > Time.at(time + items[indx]["nx2133"]["duration"]*60 + items[indx+1]["nx2133"]["duration"]*60).utc.iso8601 then
            #puts "optimise non deadline placement: permute: '#{PolyFunctions::toString(items[indx]).green}' and '#{PolyFunctions::toString(items[indx+1]).green}'".yellow
            items = Nx2133::permutePositions(items, indx, indx+1)
        end
        items
    end

    # Nx2133::optimiseNonDeadlinesPlacement2(items)
    def self.optimiseNonDeadlinesPlacement2(items)
        return items if items.size < 2
        time = Time.new.to_i + items[0]["nx2133"]["duration"] * 60
        (0..items.size-2).each{|indx|
            items = Nx2133::optimiseNonDeadlinesPlacement1(items, indx, time)
            time = time + items[indx-1]["nx2133"]["duration"] * 60
        }
        items
    end

    # Nx2133::updatesAndSorting(items)
    def self.updatesAndSorting(items)
        items = items.map{|item|
            item["nx2133"] = Nx2133::getNx(item)
            item
        }
        loop {
            trace1 = Digest::SHA1.hexdigest(items.to_s)
            items = Nx2133::ensureDeadlineOrdering(items)
            items = Nx2133::ensureDeadlineProjections2(items)
            items = Nx2133::optimiseNonDeadlinesPlacement2(items)
            items = items.sort_by{|item|
                item["nx2133"]["position"]
            }
            trace2 = Digest::SHA1.hexdigest(items.to_s)
            break if trace1 == trace2
        }
        items.each{|item|
            i2 = Items::itemOrNull(item["uuid"])
            if item["nx2133"].to_s != i2["nx2133"].to_s then
                Items::setAttribute(item["uuid"], "nx2133", item["nx2133"])
            end
        }
        items
    end

    # Nx2133::maintenance()
    def self.maintenance()
        if Nx2133::determineFirstPosition() > 0.35 then
            Items::items()
                .each{|item|
                    nx2133 = Nx2133::getNxOrNull(item)
                    if nx2133 then
                        nx2133["position"] = nx2133["position"] - 0.25
                        Items::setAttribute(item["uuid"], "nx2133", item["nx2133"])
                    end
                }
                .compact
                .min
        end
    end

end
