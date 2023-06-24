# encoding: UTF-8

class TmpSkip1

    # TmpSkip1::tmpskip1(item, hours)
    def self.tmpskip1(item, hours)
        directive = {
            "unixtime"        => Time.new.to_f,
            "datetime"        => Time.new.utc.iso8601,
            "durationInHours" => hours
        }
        puts JSON.pretty_generate(directive)
        DarkEnergy::patch(item["uuid"], "tmpskip1", directive)
        # The backup items are dynamically generated and do not correspond to item
        # in the database. We also put the skip directive to the cache
        XCache::set("464e0d79-36b5-4bb6-951c-4d91d661ac6f:#{item["uuid"]}", JSON.generate(directive))
    end

    # TmpSkip1::skipSuffix(item)
    def self.skipSuffix(item)
        skipDirectiveOrNull = lambda {|item|
            if item["tmpskip1"] then
                return item["tmpskip1"]
            end
            cachedDirective = XCache::getOrNull("464e0d79-36b5-4bb6-951c-4d91d661ac6f:#{item["uuid"]}")
            if cachedDirective then
                return JSON.parse(cachedDirective)
            end
        }

        skipTargetTimeOrNull = lambda {|item|
            directive = skipDirectiveOrNull.call(item)
            return nil if directive.nil?
            targetTime = directive["unixtime"] + directive["durationInHours"]*3600
            (Time.new.to_f < targetTime) ? targetTime : nil
        }

        if skipTargetTimeOrNull.call(item) then
            " (tmpskip1'ed)".yellow
        else
            ""
        end
    end

    # TmpSkip1::isSkipped(item)
    def self.isSkipped(item)
        skipDirectiveOrNull = lambda {|item|
            if item["tmpskip1"] then
                return item["tmpskip1"]
            end
            cachedDirective = XCache::getOrNull("464e0d79-36b5-4bb6-951c-4d91d661ac6f:#{item["uuid"]}")
            if cachedDirective then
                return JSON.parse(cachedDirective)
            end
        }

        skipTargetTimeOrNull = lambda {|item|
            directive = skipDirectiveOrNull.call(item)
            return nil if directive.nil?
            targetTime = directive["unixtime"] + directive["durationInHours"]*3600
            (Time.new.to_f < targetTime) ? targetTime : nil
        }

        skipTargetTimeOrNull.call(item)
    end
end
