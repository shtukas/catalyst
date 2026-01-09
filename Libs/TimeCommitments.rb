# encoding: UTF-8

class TimeCommitments

    # TimeCommitments::suffix(item)
    def self.suffix(item)
        if item["tc-15"] then
            return " (#{item["tc-15"]} hours day)".yellow
        end
        if item["tc-16"] then
            return " (#{item["tc-16"]} hours week)".yellow
        end
        ""
    end
end
