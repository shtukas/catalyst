
class DoNotShowUntil
    # DoNotShowUntil::doNotShowUntil(item, unixtime)
    def self.doNotShowUntil(item, unixtime)
        Items::setAttribute(item["uuid"], "do-not-show-until-51", Time.at(unixtime).utc.iso8601)
    end

    # DoNotShowUntil::isVisible(item)
    def self.isVisible(item)
        item["do-not-show-until-51"].nil? or item["do-not-show-until-51"] < Time.new.utc.iso8601 
    end
end
