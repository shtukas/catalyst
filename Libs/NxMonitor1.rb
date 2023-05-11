
class NxMonitor1s

    # -------------------------------------
    # Data

    # NxMonitor1s::toString(item)
    def self.toString(item)
        "(#{"monitor".green}) #{item["description"]} #{TxEngines::toString(item["engine"])}"
    end

    # NxMonitor1s::listingItems()
    def self.listingItems()
        Solingen::mikuTypeItems("NxMonitor1")
    end

    # -------------------------------------
    # Ops

    # NxMonitor1s::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = Solingen::mikuTypeItems("NxMonitor1")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("monitor", items, lambda{|item| NxMonitor1s::toString(item) })
    end

    # NxMonitor1s::access(monitor)
    def self.access(monitor)

        if monitor["uuid"] == "347fe760-3c19-4618-8bf3-9854129b5009" then
            NxLongs::program1()
            return
        end

        if monitor["uuid"] == "bea0e9c7-f609-47e7-beea-70e433e0c82e" then
            NxTasksBoardless::program1()
            return
        end

        raise "I do not know how access monitor: #{monitor}"
    end

    # NxMonitor1s::program2(monitor)
    def self.program2(monitor)
        loop {
            monitor = Solingen::getItemOrNull(monitor["uuid"])
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

    # NxMonitor1s::issueMonitorDayDx02s(monitor)
    def self.issueMonitorDayDx02s(monitor)
        (1..4).each {|i|
            Dx02s::issueDx02(Dx02s::generatorToDx04(monitor), Dx02s::dx03Fluid(), i*3 + rand)
        }
    end

    # NxMonitor1s::issueDayDx02s()
    def self.issueDayDx02s()
        Solingen::mikuTypeItems("NxMonitor1").each{|monitor|
            NxMonitor1s::issueMonitorDayDx02s(monitor)
        }
    end

    # NxMonitor1s::dataMaintenance()
    def self.dataMaintenance()
        Solingen::mikuTypeItems("NxMonitor1").each{|monitor|
            engine2 = TxEngines::engineCarrierMaintenance(monitor)
            if engine2 then
                Solingen::setAttribute2(monitor["uuid"], "engine", engine2)
            end
        }
    end
end