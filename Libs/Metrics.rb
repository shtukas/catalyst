
=begin

3.00 : running items

0.90 : wave interruption

0.80 : PhysicalTarget

0.50 : ship (ub)

0.45 : ondate

0.43 : sticky

0.40 : ship ratio: 0.5

0.32 : wave !interruption

0.30 : ship (lb)

=end

$ShiftsMemory = {}

class Metrics

    # Metrics::infinitesimal(item)
    def self.infinitesimal(item)
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
        if item["mikuType"] == "PhysicalTarget" then
            return 0.80
        end
        if item["mikuType"] == "Wave" and item["interruption"] then
            return 0.90
        end
        if item["mikuType"] == "Wave" and !item["interruption"] then
            return 0.32
        end
        if item["mikuType"] == "NxEffect" and item["behaviour"]["type"] == "ship" then
            return 0.30 + 0.20 * (1-TxCores::coreDayCompletionRatio(item["behaviour"]["engine"]))
        end
        if item["mikuType"] == "NxEffect" and item["behaviour"]["type"] == "ondate" then
            return 0.45
        end
        if item["mikuType"] == "NxEffect" and item["behaviour"]["type"] == "sticky" then
            return 0.43
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
