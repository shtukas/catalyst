
class Nx2133

    # ----------------------------------------------
    # Decisions

    # Nx2133::getNxOrNull(item)
    def self.getNxOrNull(item)
        if item["nx2133"] then
            return item["nx2133"]
        end
        nil
    end

    # Nx2133::decideDurationInMinutes(item)
    def self.decideDurationInMinutes(item)
        if item["nx0607-duration"] then
            return item["nx0607-duration"]
        end
        if item["mikuType"] == "NxTask" then
            return 60
        end
        if item["mikuType"] == "NxCore" then
            return 60
        end
        duration = LucilleCore::askQuestionAnswerAsString("Duration for '#{PolyFunctions::toString(item).green}' (in mins): ").to_f
        Items::setAttribute(item["uuid"], "nx0607-duration", duration)
        duration
    end

    # Nx2133::decideDeadlineOrNull(item)
    def self.decideDeadlineOrNull(item)
        nx2133 = Nx2133::getNxOrNull(item)
        if nx2133 then
            return nx2133["deadline"]
        end
        if item["mikuType"] == "NxTask" and item["nx2290-important"] then
            t1 = [ Time.new.to_i, CommonUtils::unixtimeAtLastMidnightAtLocalTimezone() + 9 * 3600 ].max
            t2 = [ Time.new.to_i + 6 * 3600, CommonUtils::unixtimeAtLastMidnightAtLocalTimezone() + 12 * 3600 ].max
            tx = t1 + rand * (t2-t1)
            deadline = Time.at(tx).utc.iso8601
            return deadline
        end
        if item["mikuType"] == "NxCore" then
            t1 = [ Time.new.to_i, CommonUtils::unixtimeAtLastMidnightAtLocalTimezone() + 12 * 3600 ].max
            t2 = [ Time.new.to_i + 6 * 3600, CommonUtils::unixtimeAtLastMidnightAtLocalTimezone() + 15 * 3600 ].max
            tx = t1 + rand * (t2-t1)
            deadline = Time.at(tx).utc.iso8601
            return deadline
        end
        if item["mikuType"] == "NxDated" then
            t1 = [ Time.new.to_i, CommonUtils::unixtimeAtLastMidnightAtLocalTimezone() + 11 * 3600 ].max
            t2 = [ Time.new.to_i + 6 * 3600, CommonUtils::unixtimeAtLastMidnightAtLocalTimezone() + 16 * 3600 ].max
            tx = t1 + rand * (t2-t1)
            deadline = Time.at(tx).utc.iso8601
            return deadline
        end
        nil
    end

    # Nx2133::decideCountdownToDelistingInSecondsOrNull(item)
    def self.decideCountdownToDelistingInSecondsOrNull(item)
        if item["mikuType"] == "NxTask" and item["nx2290-important"] then
            return 3600
        end
        if item["mikuType"] == "NxCore" then
            return 3600
        end
        nil
    end

    # Nx2133::determineNewFirstDeadline()
    def self.determineNewFirstDeadline()
        items = Items::items()
        deadlines = items
            .map{|item|
                nx2133 = Nx2133::getNxOrNull(item)
                if nx2133 and nx2133["deadline"] then
                    nx2133["deadline"]
                else
                    nil
                end
            }
            .compact
        return Time.new.utc.iso8601 if deadlines.empty?
        Time.at(DateTime.parse(deadlines.min).to_time - 1).utc.iso8601
    end

    # Nx2133::determineFirstPosition()
    def self.determineFirstPosition()
        items = Items::items()
        positions = items
            .map{|item|
                nx2133 = Nx2133::getNxOrNull(item)
                if nx2133 then
                    nx2133["position"]
                else
                    nil
                end
            }
            .compact
        return 0.5 if positions.empty?
        positions.min
    end

    # Nx2133::determineLastPosition()
    def self.determineLastPosition()
        items = Items::items()
        positions = items
            .map{|item|
                nx2133 = Nx2133::getNxOrNull(item)
                if nx2133 then
                    nx2133["position"]
                else
                    nil
                end
            }
            .compact
        return 0.5 if positions.empty?
        positions.max
    end

    # ----------------------------------------------
    # Makers

    # Nx2133::buildNewNx(item)
    def self.buildNewNx(item)
        lastPosition = Nx2133::determineLastPosition()
        duration = Nx2133::decideDurationInMinutes(item)
        deadline = Nx2133::decideDeadlineOrNull(item)
        countdownToDelisting = Nx2133::decideCountdownToDelistingInSecondsOrNull(item)

        {
            "position" => lastPosition + rand * (1 - lastPosition),
            "duration" => duration,
            "deadline" => deadline, # optional
            "countdownToDelisting" => countdownToDelisting
        }
    end

    # Nx2133::architechNx(item)
    def self.architechNx(item)
        nx2133 = Nx2133::getNxOrNull(item)
        return nx2133 if nx2133
        nx2133 = Nx2133::buildNewNx(item)
        Items::setAttribute(item["uuid"], "nx2133", nx2133)
        nx2133
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

    # Nx2133::suffix(item)
    def self.suffix(item)
        nx2133 = Nx2133::getNxOrNull(item)
        if nx2133 then
            lateStatus = nx2133["deadline"] ? (  nx2133["deadline"] < Time.new.utc.iso8601 ? " [late]".red : "" ) : ""
            " (#{nx2133["position"]}, #{nx2133["duration"]}, #{nx2133["deadline"]})".yellow + lateStatus
        else
            ""
        end
    end

    # ----------------------------------------------
    # Transforms

    # Nx2133::permutePositions(items, i1, i2) # items -> items
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

    # Nx2133::timesCheckout(deadline1, durationsInMinutes, durationInMinutes, deadline2)
    def self.timesCheckout(deadline1, durationsInMinutes, durationInMinutes, deadline2)
        DateTime.parse(deadline1).to_time.to_i + durationsInMinutes.map{|d| d*60 }.sum + durationInMinutes * 60 <= DateTime.parse(deadline2).to_time.to_i
    end

    # Nx2133::luci(headEndingWithARock, fillings, rocks, waters)
    def self.luci(headEndingWithARock, fillings, rocks, waters)
        if rocks.empty? and waters.empty? then
            return headEndingWithARock + fillings
        end
        if rocks.empty? and waters.size > 0 then
            return headEndingWithARock + fillings + waters
        end
        if rocks.size > 0 and waters.empty? then
            return headEndingWithARock + fillings + rocks
        end
        if headEndingWithARock.empty? then
            # Here we are making the arbitrary decision to always start with a water and a rock
            return Nx2133::luci(waters.take(1) + rocks.take(1), fillings, rocks.drop(1), waters.drop(1))
        end
        # By now we have non empty heading, rocks and waters
        check = Nx2133::timesCheckout(headEndingWithARock.last["nx2133"]["deadline"], fillings.map{|i| i["nx2133"]["duration"] }, waters.first["nx2133"]["duration"], rocks.first["nx2133"]["deadline"])
        if check then
            Nx2133::luci(headEndingWithARock, fillings + waters.take(1), rocks, waters.drop(1))
        else
            Nx2133::luci(headEndingWithARock + fillings + rocks.take(1), [], rocks.drop(1), waters)
        end
    end

    # Nx2133::ordering(items) # items -> items
    def self.ordering(items)
        items = items.sort_by{|item| item["nx2133"]["position"] }
        trace1 = Digest::SHA1.hexdigest(items.to_s)
        rocks, waters = items.partition{|item| item["nx2133"]["deadline"] }
        rocks = rocks.sort_by{|item| item["nx2133"]["deadline"] }
        (0..rocks.size-2).each{|i|
            if rocks[i]["nx2133"]["position"] < rocks[i+1]["nx2133"]["position"] then
                # noting to happen
            else
                rocks[i+1]["nx2133"]["position"] = 0.5 * (rocks[i]["nx2133"]["position"] + 1 + i.to_f/100)
            end
        }
        waters = waters.sort_by{|item| item["nx2133"]["position"] }
        items = Nx2133::luci([], [], rocks, waters)
        (0..items.size-2).each{|i|
            if items[i]["nx2133"]["position"] < items[i+1]["nx2133"]["position"] then
                # noting to happen
            else
                items[i+1]["nx2133"]["position"] = 0.5 * (items[i]["nx2133"]["position"] + 1)
            end
        }
        items = waters.sort_by{|item| item["nx2133"]["position"] }
        items.each{|item|
            i2 = Items::itemOrNull(item["uuid"])
            if item["nx2133"].to_s != i2["nx2133"].to_s then
                Items::setAttribute(item["uuid"], "nx2133", item["nx2133"])
            end
        }
        items
    end

    # Nx2133::ensureNx2133(item)
    def self.ensureNx2133(item)
        item["nx2133"] = Nx2133::architechNx(item)
        item
    end

    # Nx2133::decreaseCountdownIfRelevant(item, timespanInSeconds)
    def self.decreaseCountdownIfRelevant(item, timespanInSeconds)
        if item["nx2133"] and item["nx2133"]["countdownToDelisting"] then
            item["nx2133"]["countdownToDelisting"] = item["nx2133"]["countdownToDelisting"] -  timespanInSeconds
            if item["nx2133"]["countdownToDelisting"] < 0 then
                Nx2133::removeNx2133(item)
            else
                Items::setAttribute(item["uuid"], "nx2133",item["nx2133"])
            end
        end
    end

    # Nx2133::removeNx2133(item)
    def self.removeNx2133(item)
        Items::setAttribute(item["uuid"], "nx2133", nil)
    end

    # Nx2133::maintenance()
    def self.maintenance()
        fp = Nx2133::determineFirstPosition()
        if fp > 0.35 then
            Items::items()
                .each{|item|
                    nx2133 = Nx2133::getNxOrNull(item)
                    if nx2133 then
                        nx2133["position"] = nx2133["position"] - (fp - 0.1)
                        Items::setAttribute(item["uuid"], "nx2133", nx2133)
                    end
                }
        end
    end

    # Nx2133::reset()
    def self.reset()
        Items::items().each{|item|
            next if item["nx2133"].nil?
            Items::setAttribute(item["uuid"], "nx2133", nil)
        }
    end
end
