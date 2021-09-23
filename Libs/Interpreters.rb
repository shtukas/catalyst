# encoding: UTF-8

# ------------------------------------------------------------------------------------------

class Interpreters

    # Interpreters::listingCommands()
    def self.listingCommands()
        "[listing] .. | <n> | <datecode> | hide <n> <datecode> | set domain |expose"
    end

    # Interpreters::listingInterpreter(store, command)
    def self.listingInterpreter(store, command)

        # The case <n> should hve already been captured by UIServices

        # The case [] should have already been caputred by UIServices

        if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
            ns16 = store.getDefault()
            return if ns16.nil? 
            DoNotShowUntil::setUnixtime(ns16["uuid"], unixtime)
            puts "Hidden until: #{Time.at(unixtime).to_s}"
        end

        if Interpreting::match("hide * *", command) then
            _, ordinal, datecode = Interpreting::tokenizer(command)
            ordinal = ordinal.to_i
            ns16 = store.get(ordinal)
            return if ns16.nil?
            unixtime = Utils::codeToUnixtimeOrNull(datecode)
            return if unixtime.nil?
            DoNotShowUntil::setUnixtime(ns16["uuid"], unixtime)
        end

        if Interpreting::match("expose", command) then
            ns16 = store.getDefault()
            return if ns16.nil? 
            puts JSON.pretty_generate(ns16)
            LucilleCore::pressEnterToContinue()
        end

        if Interpreting::match("set domain", command) then
            ns16 = store.getDefault()
            return if ns16.nil? 
            domain = Domains::interactivelySelectDomainOrNull()
            return if domain.nil?
            Domains::setDomainForItem(ns16["uuid"], domain)
        end
    end

    # Interpreters::mainMenuCommands()
    def self.mainMenuCommands()
        "[general] float | wave | todo | ondate | calendar item | anniversary | Nx50 | waves | ondates | calendar | Nx50s | anniversaries | search | >> | nyx"
    end

    # Interpreters::mainMenuInterpreter(command)
    def self.mainMenuInterpreter(command)

        if Interpreting::match("float", command) then
            NxFloats::interactivelyCreateNewOrNull()
        end

        if Interpreting::match("wave", command) then
            Waves::issueNewWaveInteractivelyOrNull()
        end

        if Interpreting::match("todo", command) then
            Nx50s::interactivelyCreateNewOrNull()
        end

        if Interpreting::match("ondate", command) then
            nx31 = NxOnDate::interactivelyIssueNewOrNull()
            if nx31 then
                puts JSON.pretty_generate(nx31)
            end
        end

        if Interpreting::match("calendar item", command) then
            Calendar::interactivelyIssueNewCalendarItem()
        end

        if Interpreting::match("Nx50", command) then
            nx50 = Nx50s::interactivelyCreateNewOrNull()
            return if nx50.nil?
            puts JSON.pretty_generate(nx50)
        end

        if Interpreting::match("anniversary", command) then
            Anniversaries::issueNewAnniversaryOrNullInteractively()
        end

        if Interpreting::match("ondates", command) then
            NxOnDate::main()
        end

        if Interpreting::match("anniversaries", command) then
            Anniversaries::anniversariesDive()
        end

        if Interpreting::match("calendar", command) then
            Calendar::main()
        end

        if Interpreting::match("waves", command) then
            Waves::main()
        end

        if Interpreting::match("Nx50s", command) then
            nx50s = Nx50s::nx50s()
            if LucilleCore::askQuestionAnswerAsBoolean("limit to 100 ? ", true) then
                nx50s = nx50s.first(100)
            end
            loop {
                nx50 = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx50", nx50s, lambda {|nx50| Nx50s::toString(nx50) })
                return if nx50.nil?
                Nx50s::run(nx50)
            }
        end

        if Interpreting::match(">>", command) then
            key = "4b23af4b-4536-44f6-a85a-d4e8cb320b30"
            Nx50s::nx50s().each{|nx50|

                domain = Domains::getDomainForItemOrNull(nx50["uuid"])
                nxball = NxBalls::makeNxBall([nx50["uuid"], "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7", Domains::domainBankAccountOrNull(domain)].compact)

                next if !(nx50["domain"].nil? or nx50["domain"] == "eva")
                next if KeyValueStore::flagIsTrue(nil, "#{key}:#{nx50["uuid"]}")

                Nx50s::accessContent(nx50)

                command = LucilleCore::askQuestionAnswerAsString("#{Nx50s::toString(nx50).green} (done, landing, exit) : ")

                if command == "gg" then
                    Nx50s::complete(nx50)
                end

                if command == "landing" then
                    Nx50s::run(nx50)
                end

                if command == "exit" then
                    break
                end

                NxBalls::closeNxBall(nxball, false)

                KeyValueStore::setFlagTrue(nil, "#{key}:#{nx50["uuid"]}")
            }
        end

        if Interpreting::match("search", command) then
            Search::search()
        end

        if Interpreting::match("nyx", command) then
            system("/Users/pascal/Galaxy/Software/Nyx/nyx")
        end
    end
end
