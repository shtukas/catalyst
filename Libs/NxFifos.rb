
class NxFifos

    # ---------------------------------------
    # Data

    # NxFifos::itemToListingLine(item)
    def self.itemToListingLine(item)
        item = Solingen::getItemOrNull(item["uuid"])
        if item .nil? then
            raise "(error: payload has disappeared)"
        end
        line = "Px02#{Listing::skipfragment(item)}#{PolyFunctions::toString(item)}#{CoreData::itemToSuffixString(item)}#{BoardsAndItems::toStringSuffix(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{NxNotes::toStringSuffix(item)}#{DoNotShowUntil::suffixString(item)}"
        if Listing::isInterruption(item) then
            line = line.gsub("Px02", "(intt) ".red)
        else
            line = line.gsub("Px02", "")
        end
        if NxBalls::itemIsActive(item) then
            line = line.green
        end
        if !DoNotShowUntil::isVisible(item) and !NxBalls::itemIsActive(item) then
            line = line.yellow
        end
        if Listing::isOverflowingTask(item) and !NxBalls::itemIsActive(item) then
            line = line.yellow
        end
        line
    end

    # NxFifos::toString(item)
    def self.toString(item)
        begin
            "(fifo) (#{"%6.3f" % item["position"]}) #{item["time"] ? "[#{item["time"]}] " : "        "}#{NxFifos::itemToListingLine(item["payload"])}"
        rescue
            Solingen::destroy(item["uuid"])
            return "(fifo item has just been deleted)"
        end
    end

    # NxFifos::firstPosition1()
    def self.firstPosition1()
        items = Solingen::mikuTypeItems("NxFifo")
        return 1 if items.empty?
        items.map{|item| item["position"] }.max + 1
    end

    # NxFifos::nextPosition1(issuerId)
    def self.nextPosition1(issuerId)
        if issuerId == "interruption" then
            items = Solingen::mikuTypeItems("NxFifo").select{|item| item["payload"]["interruption"] }
            return NxFifos::firstPosition1()-1 if items.empty?
            return items.map{|item| item["position"] }.max + 1
        end
        items = Solingen::mikuTypeItems("NxFifo")
        return 1 if items.empty?
        items.map{|item| item["position"] }.max + 1
    end

    # NxFifos::payloadIsPresent(payload)
    def self.payloadIsPresent(payload)
        Solingen::mikuTypeItems("NxFifo").any?{|item| item["payload"]["uuid"] == payload["uuid"] }
    end

    # NxFifos::timeToPosition(time)
    def self.timeToPosition(time)
        before = Solingen::mikuTypeItems("NxFifo").select{|item| item["time"] and item["time"] <= time }
        after = Solingen::mikuTypeItems("NxFifo").select{|item| item["time"] and item["time"] >= time }
        if before.empty? then
            time1 = 1
        else 
            time1 = before.map{|item| item["position"] }.max
        end
        if after.empty? then
            time2 = time1 + 1
        else 
            time2 = after.map{|item| item["position"] }.min
        end
        0.5*(time1 + time2)
    end

    # NxFifos::listingItems()
    def self.listingItems()
        Solingen::mikuTypeItems("NxFifo")
            .sort_by{|item| item["position"] }
            .map{|item|
                payload1 = item["payload"]
                payload2 = Solingen::getItemOrNull(payload1["uuid"])
                if JSON.generate(payload2) != JSON.generate(payload1) then
                    Solingen::setAttribute2(item["uuid"], "payload", payload2)
                end
                item
            }
    end

    # ---------------------------------------
    # Ops

    # NxFifos::issue1(issuerId, payload, position)
    def self.issue1(issuerId, payload, position)
        uuid = SecureRandom.uuid
        Solingen::init("NxFifo", uuid)
        Solingen::setAttribute2(uuid, "issuerId", issuerId)
        Solingen::setAttribute2(uuid, "payload", payload)
        Solingen::setAttribute2(uuid, "position", position)
        Solingen::getItemOrNull(uuid)
    end

    # NxFifos::issue2(issuerId, payload, time)
    def self.issue2(issuerId, payload, time)
        position = NxFifos::timeToPosition(time)
        uuid = SecureRandom.uuid
        Solingen::init("NxFifo", uuid)
        Solingen::setAttribute2(uuid, "issuerId", issuerId)
        Solingen::setAttribute2(uuid, "payload", payload)
        Solingen::setAttribute2(uuid, "time", time)
        Solingen::setAttribute2(uuid, "position", position)
        Solingen::getItemOrNull(uuid)
    end

    # NxFifos::issueIfNotPresent(issuerId, payload)
    def self.issueIfNotPresent(issuerId, payload)
        return if NxFifos::payloadIsPresent(payload)
        position = NxFifos::nextPosition1(issuerId)
        item = NxFifos::issue1(issuerId, payload, position)
    end
end