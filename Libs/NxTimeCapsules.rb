
class NxTimeCapsules
    # NxTimeCapsules::operate()
    def self.operate()
        return if !Config::isPrimaryInstance()
        N3Objects::getMikuType("NxTimeCapsule").each{|item|
            if Time.new.to_i > item["unixtime"] then
                BankCore::put(item["account"], item["value"])
                N3Objects::destroy(item["uuid"])
            end
        }
    end

    # NxTimeCapsules::issueCapsule(unixtime, account, value)
    def self.issueCapsule(unixtime, account, value)
        item = {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "NxTimeCapsule",
            "unixtime" => unixtime,
            "account"  => account,
            "value"    => value
        }
        N3Objects::commit(item)
    end
end