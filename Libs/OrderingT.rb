
class OrderingT

    # OrderingT::ratio(item)
    def self.ratio(item)
        if item["mikuType"] == "NxRingworldMission" then
            return NxRingworldMissions::ratio()
        end

        if item["mikuType"] == "NxSingularNonWorkQuest" then
            return NxSingularNonWorkQuests::ratio()
        end

        if item["mikuType"] == "NxBufferInMonitor" then
            return NxBufferInMonitors::ratio()
        end

        if item["mikuType"] == "NxTodo" then
            return NxThreads::listingRatio(item)
        end

        if item["mikuType"] == "NxThread" then
            return NxThreads::listingRatio(item)
        end

        if item["mikuType"] == "Wave" then
            return 0.5 + 0.5*Math.sin(3.14*(item["ordering-shift-0723"] + Time.new.to_f/86400))
        end

        raise "(error: fbffdec2-1fde-4fe4-b072-524ff49ca935): #{item}"
    end

    # OrderingT::apply(items)
    def self.apply(items)
        items.sort_by{|item| OrderingT::ratio(item) }
    end
end
