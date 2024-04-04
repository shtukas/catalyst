
class DoNotShowUntil2

    # DoNotShowUntil2::getUnixtimeOrNull(id)
    def self.getUnixtimeOrNull(id)
        $DATA_CENTER_DATA["doNotShowUntil"][id]
    end

    # DoNotShowUntil2::setUnixtime(id, unixtime)
    def self.setUnixtime(id, unixtime)
        $DATA_CENTER_DATA["doNotShowUntil"][id] = unixtime
        $DATA_CENTER_UPDATE_QUEUE << {
            "type"     => "do-not-show-until",
            "id"       => id,
            "unixtime" => unixtime
        }
        DataProcessor::processQueue()
    end

    # DoNotShowUntil2::isVisible(item)
    def self.isVisible(item)
        Time.new.to_i >= (DoNotShowUntil2::getUnixtimeOrNull(item["uuid"]) || 0)
    end

    # DoNotShowUntil2::suffixString(item)
    def self.suffixString(item)
        unixtime = (DoNotShowUntil2::getUnixtimeOrNull(item["uuid"]) || 0)
        return "" if unixtime.nil?
        return "" if Time.new.to_i > unixtime
        " (not shown until: #{Time.at(unixtime).to_s})"
    end
end
