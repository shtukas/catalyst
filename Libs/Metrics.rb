
=begin

3.00 : running items

0.90 : wave interruption

0.80 : PhysicalTarget

0.70 : boosted ratio 0.0

0.60 : boosted ratio 1.0

0.50 : NxCruiser ratio: 0.0

0.45 : ondate

0.44 : Backups

0.43 : sticky

0.40 : NxCruiser ratio: 0.5

0.32 : wave !interruption

0.30 : NxCruiser ratio: 1.0

0.10 : completed boosted

=end

$ShiftsMemory = {}

class Metrics

    # Metrics::infinitesimal(item)
    def self.infinitesimal(item)
        return 0 if item["mikuType"] == "Backup"
        factor = 0.001
        if $ShiftsMemory[item["uuid"]] then
            return factor * $ShiftsMemory[item["uuid"]]
        end
        if item["metric-shift-0815"] then
            return factor * item["metric-shift-0815"]
        else
            shift = rand - 0.5
            DataCenter::setAttribute(item["uuid"], "metric-shift-0815", shift)
            $ShiftsMemory[item["uuid"]] = shift
            factor * shift
        end
    end

    # Metrics::metric1(item)
    def self.metric1(item)
        if TxBoosters::hasActiveBooster(item) then
            ratio = TxBoosters::completionRatio(item["booster-1521"])
            if ratio >= 1 then
                return 0.1
            end
            return 0.60 + 0.10 * (1-ratio)
        end

        if item["mikuType"] == "PhysicalTarget" then
            return 0.80
        end
        if item["mikuType"] == "Wave" and item["interruption"] then
            return 0.90
        end
        if item["mikuType"] == "Wave" and !item["interruption"] then
            return 0.32
        end
        if item["mikuType"] == "NxCruiser" then
            return 0.30 + 0.20 * (1-TxCores::coreDayCompletionRatio(item["engine"]))
        end
        if item["mikuType"] == "NxOndate" then
            return 0.45
        end
        if item["mikuType"] == "NxSticky" then
            return 0.43
        end
        if item["mikuType"] == "Backup" then
            return 0.44
        end
        raise "(error: 3b6f749b-a256-417d-a5a2-9c06aa0344ab) I do not how to metric: #{JSON.pretty_generate(item)}"
    end

    # Metrics::metric2(item)
    def self.metric2(item)
        Metrics::metric1(item) + Metrics::infinitesimal(item)
    end

    # Metrics::order(items)
    def self.order(items)
        items
            .sort_by{|item| Metrics::metric2(item) }
            .reverse
    end
end
