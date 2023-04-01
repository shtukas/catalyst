
class Metric

    # Metric::epsilon(item)
    def self.epsilon(item)
        e = XCache::getOrNull(item["uuid"])
        return e.to_f if e
        e = 0.01 * rand
        XCache::set(item["uuid"], e)
        e
    end

    # Metric::metric(item)
    def self.metric(item)
        return item[:metric] if item[:metric]

        if item["mikuType"] == "NxAnniversary" then
            return 14 + Metric::epsilon(item)
        end
        if item["mikuType"] == "DesktopTx1" then
            return 13 + Metric::epsilon(item)
        end
        if item["mikuType"] == "NxListingPriority" then
            return 12 + Metric::epsilon(item)
        end
        if item["mikuType"] == "Wave" and item["priority"] then
            return 11 + Metric::epsilon(item)
        end
        if item["mikuType"] == "DeviceBackup" then
            return 10 + Metric::epsilon(item)
        end
        if item["mikuType"] == "NxFire" then
            return 19 + Metric::epsilon(item)
        end
        if item["mikuType"] == "NxLine" then
            return 8 + Metric::epsilon(item)
        end
        if item["mikuType"] == "NxOndate" then
            return 7 + Metric::epsilon(item)
        end
        if item["mikuType"] == "TxNumberTarget" then
            return 6 + Metric::epsilon(item)
        end
        if item["mikuType"] == "NxFloat" then
            return 5 + Metric::epsilon(item)
        end
        if item["mikuType"] == "NxProject" then
            return 4 + Metric::epsilon(item)
        end
        if item["mikuType"] == "NxOpenCycle" then
            return 3 + Metric::epsilon(item)
        end
        if item["mikuType"] == "Wave" and !item["priority"] then
            return 2 + Metric::epsilon(item)
        end
        if item["mikuType"] == "NxTask" then
            return 2 + Metric::epsilon(item)
        end

        raise "Could not Metric::metric item: #{JSON.pretty_generate(item)}"
    end
end
