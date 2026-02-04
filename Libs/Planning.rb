
class Planning

    # Planning::distribute(nx1s)
    def self.distribute(nx1s)

        #nx1: {
        #    "item"            : item,
        #    "bucket&position" : data
        #}

        nx1s = nx1s.each{|nx1|
            item = nx1["item"]
            bucket, position = nx1["bucket&position"]

            if position < 4.00 then # the end of today
                if item["duration-38"].nil? then
                    duration = LucilleCore::askQuestionAnswerAsString("#{PolyFunctions::toString(item).green}: duration in minutes : ").to_f
                    item["duration-38"] = duration
                    Blades::setAttribute(item["uuid"], "duration-38", duration)
                end
            end

            nx1["item"] = item
            nx1
        }

        first_item = nx1s[0]["item"]
        first_starting_unixtime = XCache::getOrDefaultValue("2e6b4346-5354-400a-bc55-dde404cc6306:#{CommonUtils::today()}:#{first_item["uuid"]}", Time.new.to_i).to_i 

        if !NxBalls::itemIsRunning(first_item) then
            first_starting_unixtime = [first_starting_unixtime, Time.new.to_i].min
        end

        time_cursor = first_starting_unixtime

        nx1s.each{|nx1|
            item = nx1["item"]
            bucket, position = nx1["bucket&position"]
            if position < 4.00 then
                duration = item["duration-38"]
                end_unixtime = time_cursor + duration * 60
                nx2 = {
                    "start-unixtime" => time_cursor,
                    "start-datetime" => Time.at(time_cursor).to_s,
                    "duration"       => duration,
                    "end-unixtime"   => end_unixtime,
                    "end-datetime"   => Time.at(end_unixtime).to_s,
                }
                XCache::set("nx2:295e252e-9732-4c9d-9020-12374a2c334c:#{item["uuid"]}", JSON.generate(nx2))
                XCache::set("2e6b4346-5354-400a-bc55-dde404cc6306:#{CommonUtils::today()}:#{item["uuid"]}", time_cursor)
                time_cursor = end_unixtime
            end
        }
    end

    # Planning::planningStatus(nx1s)
    def self.planningStatus(nx1s)
        nx1s = FrontPage::itemsAndBucketPositionsForListing()
        #nx1: {
        #    "item"            : item,
        #    "bucket&position" : data
        #}

        end_unixtime = nil

        nx1s.each{|nx1|
            item = nx1["item"]
            nx2 = XCache::getOrNull("nx2:295e252e-9732-4c9d-9020-12374a2c334c:#{item["uuid"]}")
            next if nx2.nil?
            nx2 = JSON.parse(nx2)
            if Time.new.to_i > nx2["end-unixtime"] then
                return "warning: #{PolyFunctions::toString(item)} is overflowing"
            end
            end_unixtime = nx2["end-unixtime"]
        }

        if end_unixtime and DateTime.parse("#{CommonUtils::today()} 23:00:00").to_time.to_i < end_unixtime then
            return "warning: you are finishing after 23:00 (#{Time.at(end_unixtime).to_s})"
        end

        nil
    end
end

