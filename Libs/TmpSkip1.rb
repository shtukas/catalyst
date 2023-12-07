# encoding: UTF-8

class TmpSkip1

    # TmpSkip1::isSkipped(item)
    def self.isSkipped(item)
        item["skip-0843"] and item["skip-0843"] > Time.new.to_i
    end

    # TmpSkip1::skipSuffix(item)
    def self.skipSuffix(item)
        return " (skipped)".yellow if TmpSkip1::isSkipped(item)
        ""
    end
end
