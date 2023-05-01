
class NxFrontOrdinals

    # ---------------------------------------------
    # IO

    # NxFrontOrdinals::items()
    def self.items()
        N3Objects::getMikuType("NxFrontOrdinal")
    end

    # NxFrontOrdinals::issue(targetuuid, ordinal)
    def self.issue(targetuuid, ordinal)
        item = {
            "uuid"          => SecureRandom.uuid,
            "mikuType"      => "NxFrontOrdinal",
            "targetuuid"    => targetuuid,
            "targetordinal" => ordinal
        }
        N3Objects::commit(item)
        item
    end

    # ---------------------------------------------
    # Data

    # NxFrontOrdinals::getOrdinalByTargetuuid(targetuuid)
    def self.getOrdinalByTargetuuid(targetuuid)
        item = NxFrontOrdinals::items()
                .select{|item| item["targetuuid"] == targetuuid }
                .first
        return item["targetordinal"] if item
        raise "(error: c419fc28-873b-47e3-a6b2-f1b28848918e) targetuuid: #{targetuuid}"
    end

    # NxFrontOrdinals::queue1()
    def self.queue1()
        items = NxFrontOrdinals::items()
            .sort_by{|fo| fo["targetordinal"] }
            .map{|fo| 
                (lambda{|fo|
                    item = N3Objects::getOrNull(fo["targetuuid"]) 
                    return nil if item.nil?

                    if !DoNotShowUntil::isVisible(item) then
                        N3Objects::destroy(fo["uuid"])
                        return nil
                    end

                    item[:isFifo] = true
                    item[:fifoOrdinal] = fo["targetordinal"]
                    item
                }).call(fo)
            }
            .compact
    end

    # ---------------------------------------------
    # Ops

    # NxFrontOrdinals::destroyByTargetUUID(targetuuid)
    def self.destroyByTargetUUID(targetuuid)
        NxFrontOrdinals::items()
            .select{|item| item["targetuuid"] == targetuuid }
            .each{|item| N3Objects::destroy(item["uuid"]) }
    end

    # NxFrontOrdinals::addAtTheEnd(item)
    def self.addAtTheEnd(item)
        nextOrdinal = (([1] + NxFrontOrdinals::items().map{|i| i["targetordinal"] }).max + 1).floor
        NxFrontOrdinals::issue(item["uuid"], nextOrdinal)
    end

    # NxFrontOrdinals::dataManagement(queue2)
    def self.dataManagement(queue2)

        # if we have less than 10 items in the fifo, we add the first from queue2
        if NxFrontOrdinals::items().size < 10 and !queue2.empty? then
            NxFrontOrdinals::addAtTheEnd(queue2.first)
            return
        end

        # Prevent the ordinal values to grow beyond 100 (for 2 digits main value)
        if NxFrontOrdinals::items().map{|item| item["targetordinal"] }.max > 99 then
            NxFrontOrdinals::items().map{|item|
                item["targetordinal"] = item["targetordinal"] * 0.5
                N3Objects::commit(item)
            }
            return
        end

        # Get the last items of fifo
        if NxFrontOrdinals::items().size > 0 then
            fo = NxFrontOrdinals::items().last
            item = N3Objects::getOrNull(fo["uuid"])
            if item then
                if item["mikuType"] == "Wave" and !item["interruption"] and (picks = queue2.select{|item| item["mikuType"] != "Wave" }).size > 0 then
                    NxFrontOrdinals::addAtTheEnd(picks.first)
                    return
                end
            else
                N3Objects::destroy(fo["uuid"])
                return
            end
        end
    end

    # NxFrontOrdinals::rotateCatalystItem(catalystItem)
    def self.rotateCatalystItem(catalystItem)
        NxFrontOrdinals::items()
            .select{|item| item["targetuuid"] == catalystItem["uuid"] }
            .each{|item| N3Objects::destroy(item["uuid"]) }
        nextOrdinal = (([1] + NxFrontOrdinals::items().map{|i| i["targetordinal"] }).max + 1).floor
        NxFrontOrdinals::issue(catalystItem["uuid"], nextOrdinal)
    end
end
