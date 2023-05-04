
class NxMonitor1s

    # NxMonitor1s::items()
    def self.items()
        N3Objects::getMikuType("NxMonitor1")
    end

    # NxMonitor1s::toString(item)
    def self.toString(item)
        "(#{"monitor".green}) #{item["description"]} #{TxEngines::toString(item["engine"])}"
    end

    # NxMonitor1s::dataMaintenance()
    def self.dataMaintenance()
        NxMonitor1s::items().each{|monitor|
            engine2 = TxEngines::engineMaintenance(monitor["description"], monitor["engine"])
            if engine2 then
                monitor["engine"] = engine2
                N3Objects::commit(monitor)
            end
        }
    end

    # NxMonitor1s::listingItems()
    def self.listingItems()
        NxMonitor1s::items()
    end

    # NxMonitor1s::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = NxMonitor1s::items()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("monitor", items, lambda{|item| NxMonitor1s::toString(item) })
    end

    # NxMonitor1s::access(item)
    def self.access(item)

        if item["uuid"] == "347fe760-3c19-4618-8bf3-9854129b5009" then
            NxLongs::program1()
            return
        end

        if item["uuid"] == "bea0e9c7-f609-47e7-beea-70e433e0c82e" then
            NxTasksBoardless::program1()
            return
        end

        raise "I do not know how access monitor: #{item}"
    end

    # NxMonitor1s::program2(monitor)
    def self.program2(monitor)
        loop {
            monitor = N3Objects::getOrNull(monitor["uuid"])
            return if monitor.nil?
            puts NxMonitor1s::toString(monitor)
            actions = ["program(monitor)", "start", "add time"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            break if action.nil?
            if action == "start" then
                PolyActions::start(monitor)
            end
            if action == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                PolyActions::addTimeToItem(monitor, timeInHours*3600)
            end
            if action == "program(monitor)" then
                NxMonitor1s::access(monitor)
            end
        }
    end

    # NxMonitor1s::program3()
    def self.program3()
        loop {
            monitor = NxMonitor1s::interactivelySelectOneOrNull()
            return if monitor.nil?
            NxMonitor1s::program2(monitor)
        }
    end
end