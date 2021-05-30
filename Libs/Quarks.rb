
# encoding: UTF-8

class Quarks

    # Quarks::interactivelyIssueNewQuarkOrNull()
    def self.interactivelyIssueNewQuarkOrNull()
        uuid = SecureRandom.uuid

        quark = {}
        quark["uuid"]        = uuid
        quark["schema"]      = "quark"
        quark["unixtime"]    = Time.new.to_f

        coordinates = Nx102::interactivelyIssueNewCoordinates3OrNull()
        return nil if coordinates.nil?

        quark["description"] = coordinates[0]
        quark["contentType"] = coordinates[1]
        quark["payload"]     = coordinates[2]

        agent = LucilleCore::selectEntityFromListOfEntitiesOrNull("air traffic control agent", AirTrafficControl::agents(), lambda{|agent| agent["name"]})
        if agent then
            quark["air-traffic-control-agent"] = agent["uuid"]
        end

        CoreDataTx::commit(quark)
    end

    # --------------------------------------------------

    # Quarks::toString(quark)
    def self.toString(quark)
        "[quark] #{quark["description"]}"
    end

    # Quarks::quarks()
    def self.quarks()
        CoreDataTx::getObjectsBySchema("quark")
    end

    # --------------------------------------------------

    # Quarks::quarkToAgent(quark)
    def self.quarkToAgent(quark)
        agentuuid = quark["air-traffic-control-agent"]
        return AirTrafficControl::defaultAgent() if agentuuid.nil?
        AirTrafficControl::getAgentByIdOrNull(agentuuid) || AirTrafficControl::defaultAgent()
    end

    # Quarks::runQuark(quark)
    def self.runQuark(quark)

        uuid = quark["uuid"]

        agent = Quarks::quarkToAgent(quark)

        startUnixtime = Time.new.to_f

        thr = Thread.new {
            sleep 3600
            loop {
                Utils::onScreenNotification("Catalyst", "Quark running for more than an hour")
                sleep 60
            }
        }

        system("clear")
        puts Quarks::toString(quark)
        coordinates = Nx102::access(quark["contentType"], quark["payload"])
        if coordinates then
            quark["contentType"] = coordinates[0]
            quark["payload"]     = coordinates[1]
            CoreDataTx::commit(quark)
        end

        loop {

            return if CoreDataTx::getObjectByIdOrNull(quark["uuid"]).nil?

            system("clear")

            puts Quarks::toString(quark)

            agent = Quarks::quarkToAgent(quark)
            puts "@agent: #{agent["name"]}"

            puts "landing | update agent | set dependency | <datecode> | detach running | done | (empty) # default # exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(quark["uuid"], unixtime)
                break
            end

            if Interpreting::match("landing", command) then
                Quarks::landing(quark)
            end

            if Interpreting::match("update agent", command) then
                agent = LucilleCore::selectEntityFromListOfEntitiesOrNull("air traffic control agent", AirTrafficControl::agents(), lambda{|agent| agent["name"]})
                next if agent.nil?
                quark["air-traffic-control-agent"] = agent["uuid"]
                CoreDataTx::commit(quark)
                next
            end

            if Interpreting::match("detach running", command) then
                agent = Quarks::quarkToAgent(quark)
                DetachedRunning::issueNew2(Quarks::toString(quark), Time.new.to_i, "bank accounts", [uuid, agent["uuid"]])
                break
            end

            if Interpreting::match("done", command) then
                Nx102::postAccessCleanUp(quark["contentType"], quark["payload"])
                CoreDataTx::delete(quark["uuid"])
                $counterx.registerDone()
                break
            end

            if Interpreting::match("", command) then
                break
            end
        }

        thr.exit

        timespan = Time.new.to_f - startUnixtime

        puts "Time since start: #{timespan}"

        timespan = [timespan, 3600*2].min

        puts "putting #{timespan} seconds to uuid: #{uuid} ; quark: #{Quarks::toString(quark)}"
        Bank::put(uuid, timespan)

        puts "putting #{timespan} seconds to uuid: #{agent}"
        Bank::put(agent["uuid"], timespan)

        $counterx.registerTimeInSeconds(timespan)

        Nx102::postAccessCleanUp(quark["contentType"], quark["payload"])
    end

    # Quarks::quarkToNS16(quark)
    def self.quarkToNS16(quark)
        uuid = quark["uuid"]

        recoveryTime = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        # To prevent endlessly focusing on new items
        if recoveryTime == 0 then
            Bank::put(uuid, rand*3600)
            recoveryTime = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        end

        agent = Quarks::quarkToAgent(quark)

        announce = "[qurk] (#{agent["name"]}) #{quark["description"]}"

        {
            "uuid"     => uuid,
            "metric"   => ["ns:zone", recoveryTime, nil],
            "announce" => announce,
            "access"   => lambda{ Quarks::runQuark(quark) },
            "done"     => lambda{
                if LucilleCore::askQuestionAnswerAsBoolean("done '#{Quarks::toString(quark)}' ? ", true) then
                    CoreDataTx::delete(quark["uuid"])
                end
            },
            "x-source"       => "Quarks",
            "x-recoveryTime" => recoveryTime,
            "x-agent"        => agent
        }
    end

    # --------------------------------------------------

    # Quarks::landing(quark)
    def self.landing(quark)
        loop {

            puts Quarks::toString(quark)
            puts "uuid: #{quark["uuid"]}".yellow
            unixtime = DoNotShowUntil::getUnixtimeOrNull(quark["uuid"])
            if unixtime then
                puts "DoNotDisplayUntil: #{Time.at(unixtime).to_s}".yellow
            end
            puts "stdRecoveredDailyTimeInHours: #{BankExtended::stdRecoveredDailyTimeInHours(quark["uuid"])}".yellow

            puts "access (partial edit) | edit | transmute | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")
            break if command == ""

            if Interpreting::match("access", command) then
                coordinates = Nx102::access(quark["contentType"], quark["payload"])
                if coordinates then
                    quark["contentType"] = coordinates[0]
                    quark["payload"]     = coordinates[1]
                    CoreDataTx::commit(quark)
                end
            end

            if Interpreting::match("edit", command) then
                coordinates = Nx102::edit(quark["description"], quark["contentType"], quark["payload"])
                if coordinates then
                    quark["description"] = coordinates[0]
                    quark["contentType"] = coordinates[1]
                    quark["payload"]     = coordinates[2]
                    CoreDataTx::commit(quark)
                end
            end

            if Interpreting::match("transmute", command) then
                Nx102::transmute(quark["description"], quark["contentType"], quark["payload"])
            end

            if Interpreting::match("destroy", command) then
                CoreDataTx::delete(quark["uuid"])
                break
            end
        }
    end
end