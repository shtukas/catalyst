# encoding: UTF-8

class TheLine

    # reference = {
    #     "count"    =>
    #     "datetime" =>
    # }

    # TheLine::count()
    def self.count()
        ["NxTask", "NxFire", "NxOndate"].map{|mikuType| N3Objects::getMikuTypeCount(mikuType) }.inject(0, :+)
    end

    # TheLine::getCurrentCount()
    def self.getCurrentCount()
        [TheLine::count(), 1].max # It should not be 0, because we divide by it.
    end

    # TheLine::issueNewReference()
    def self.issueNewReference()
        count = TheLine::getCurrentCount()
        reference = {
            "count"    => count,
            "datetime" => Time.new.utc.iso8601
        }
        XCache::set("002c358b-e6ee-41bd-9bee-105396a6349a", JSON.generate(reference))
        reference
    end

    # TheLine::getReference()
    def self.getReference()
        reference = XCache::getOrNull("002c358b-e6ee-41bd-9bee-105396a6349a")
        if reference then
            return JSON.parse(reference)
        end
        TheLine::issueNewReference()
    end

    # TheLine::referenceMonitor()
    def self.referenceMonitor()
        reference = TheLine::getReference()
        current   = TheLine::getCurrentCount()
        ratio = current.to_f/reference["count"]
        if ratio < 0.99 then
            reference = TheLine::issueNewReference()
            ratio = current.to_f/reference["count"]
        end
        if ratio > 1.01 then
            reference = TheLine::issueNewReference()
            ratio = current.to_f/reference["count"]
        end
        ratio
    end

    # TheLine::line()
    def self.line()
        TheLine::referenceMonitor()
        reference = TheLine::getReference()
        current = TheLine::getCurrentCount()
        version = CommonUtils::localLastCommitId()
        "(inventory: #{current}, #{(current.to_f/reference["count"]).round(5)}, reference: #{reference["count"]} @ #{reference["datetime"]}) (version: #{version})"
    end
end
