# encoding: UTF-8

class AsteroidsOfInterest

    # AsteroidsOfInterest::getCollection()
    def self.getCollection()
        collection = InMemoryWithOnDiskPersistenceValueCache::getOrNull("5d114a38-f86a-46db-a33b-747c8d7ec22f")
        if collection.nil? then
            collection = {}
        end
        collection
    end

    # AsteroidsOfInterest::register(uuid)
    def self.register(uuid)
        collection = AsteroidsOfInterest::getCollection()
        collection[uuid] = { "uuid" => uuid, "unixtime" => Time.new.to_i }
        InMemoryWithOnDiskPersistenceValueCache::set("5d114a38-f86a-46db-a33b-747c8d7ec22f", collection)
    end

    # AsteroidsOfInterest::getUUIDs()
    def self.getUUIDs()
        AsteroidsOfInterest::getCollection().values.map{|item|  item["uuid"] }
    end
end

class Asteroids

    # Asteroids::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # Asteroids::commitToDisk(asteroid)
    def self.commitToDisk(asteroid)
        NyxObjects::put(asteroid)
    end

    # Asteroids::reCommitToDisk(asteroid)
    def self.reCommitToDisk(asteroid)
        NyxObjects::destroy(asteroid["uuid"])
        NyxObjects::put(asteroid)
    end

    # Asteroids::makePayloadInteractivelyOrNull()
    def self.makePayloadInteractivelyOrNull()
        options = [
            "description",
            "spin",
            "quarks",
            "clique"
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("payload type", options)
        return nil if option.nil?
        if option == "description" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return {
                "type"        => "description",
                "description" => description
            }
        end
        if option == "spin" then
            spin = Spins::issueNewSpinInteractivelyOrNull(SecureRandom.uuid) # this value is going to be picked up as the uuid of the asteroid
            return nil if spin.nil?
            return {
                "type" => "spin",
                "uuid" => [ spin["uuid"] ]
            }
        end
        if option == "quarks" then
            quark = Quarks::issueNewQuarkInteractivelyOrNull()
            return nil if quark.nil?
            return {
                "type"  => "quarks",
                "uuids" => [ quark["uuid"] ]
            }
        end
        if option == "clique" then
            clique = Cliques::selectCliqueFromExistingCliquesOrNull()
            return nil if clique.nil?
            return {
                "type"       => "clique",
                "cliqueuuid" => clique["uuid"]
            }
        end
        nil
    end

    # Asteroids::makeOrbitalInteractivelyOrNull()
    def self.makeOrbitalInteractivelyOrNull()
        opt9 = "inbox"
        opt0 = "top priority"
        opt1 = "single day time commitment"
        opt2 = "repeating daily time commitment"
        opt3 = "on going until completion"
        opt6 = "float to do today"
        opt8 = "indefinite"
        opt7 = "open project in the background"
        opt5 = "todo"

        options = [
            opt9,
            opt0,
            opt1,
            opt2,
            opt3,
            opt6,
            opt8,
            opt7,
            opt5,
        ]

        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("orbital", options)
        return nil if option.nil?
        if option == opt0 then
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
            return {
                "type"                  => "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3",
                "ordinal"               => ordinal
            }
        end
        if option == opt1 then
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
            return {
                "type"                  => "singleton-time-commitment-7c67cb4f-77e0-4fd",
                "timeCommitmentInHours" => timeCommitmentInHours
            }
        end
        if option == opt2 then
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
            return {
                "type"                  => "repeating-daily-time-commitment-8123956c-05",
                "timeCommitmentInHours" => timeCommitmentInHours
            }
        end
        if option == opt3 then
            return {
                "type"                  => "on-going-until-completion-5b26f145-7ebf-498"
            }
        end
        if option == opt8 then
            return {
                "type"                  => "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2"
            }
        end
        if option == opt5 then
            return {
                "type"                  => "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
            }
        end
        if option == opt6 then
            return {
                "type"                  => "float-to-do-today-b0d902a8-3184-45fa-9808-1"
            }
        end
        if option == opt7 then
            return {
                "type"                  => "open-project-in-the-background-b458aa91-6e1"
            }
        end
        if option == opt9 then
            return {
                "type"                  => "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
            }
        end
        
        nil
    end

    # Asteroids::issueAsteroidInteractivelyOrNull()
    def self.issueAsteroidInteractivelyOrNull()
        payload = Asteroids::makePayloadInteractivelyOrNull()
        return if payload.nil?
        orbital = Asteroids::makeOrbitalInteractivelyOrNull()
        return if orbital.nil?
        Asteroids::issue(payload, orbital)
    end

    # Asteroids::issue(payload, orbital)
    def self.issue(payload, orbital)
        asteroid = {
            "uuid"     => SecureRandom.uuid,
            "nyxNxSet" => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime" => Time.new.to_f,
            "payload"  => payload,
            "orbital"  => orbital
        }
        Asteroids::commitToDisk(asteroid)
        asteroid
    end

    # Asteroids::issueAsteroidInboxFromSpin(spin)
    def self.issueAsteroidInboxFromSpin(spin)
        asteroiduuid = spin["targetuuid"]
        payload = {
            "type" => "spin",
            "uuid" => spin["uuid"]
        }
        orbital = {
            "type" => "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
        }
        asteroid = {
            "uuid"     => asteroiduuid,
            "nyxNxSet" => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime" => Time.new.to_f,
            "payload"  => payload,
            "orbital"  => orbital
        }
        Asteroids::commitToDisk(asteroid)
        asteroid
    end

    # Asteroids::asteroidOrbitalTypeAsUserFriendlyString(type)
    def self.asteroidOrbitalTypeAsUserFriendlyString(type)
        return "📥"  if type == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
        return "‼️ " if type == "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3"
        return "⏱️ " if type == "singleton-time-commitment-7c67cb4f-77e0-4fd"
        return "💫"  if type == "repeating-daily-time-commitment-8123956c-05"
        return "⛵"  if type == "on-going-until-completion-5b26f145-7ebf-498"
        return "⛲"  if type == "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2"
        return "👩‍💻"  if type == "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
        return "☀️ " if type == "float-to-do-today-b0d902a8-3184-45fa-9808-1"
        return "😴"  if type == "open-project-in-the-background-b458aa91-6e1"
    end

    # Asteroids::asteroidToString(asteroid)
    def self.asteroidToString(asteroid)
        payloadFragment = lambda{|asteroid|
            payload = asteroid["payload"]
            if payload["type"] == "description" then
                return " " + payload["description"]
            end
            if payload["type"] == "spin" then
                spin = NyxObjects::getOrNull(asteroid["payload"]["uuid"])
                return spin ? (" " + Spins::spinToString(spin)) : " [could not find spin]"
            end
            if payload["type"] == "quarks" then
                quark = Quarks::getOrNull(asteroid["payload"]["uuids"][0])
                return quark ? (" " + Quarks::quarkToString(quark)) : " [could not find quark]"
            end
            if payload["type"] == "clique" then
                clique = Cliques::getOrNull(asteroid["payload"]["cliqueuuid"])
                return clique ? (" " + Cliques::cliqueToString(clique)) : " [could not find clique]"
            end
            raise "[Asteroids] error: CE8497BB"
        }
        orbitalFragment = lambda{|asteroid|
            uuid = asteroid["uuid"]
            if asteroid["orbital"]["type"] == "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3" then
                return " (ordinal: #{asteroid["orbital"]["ordinal"]})"
            end
            if asteroid["orbital"]["type"] == "singleton-time-commitment-7c67cb4f-77e0-4fd" then
                return " (singleton: #{asteroid["orbital"]["timeCommitmentInHours"]} hours, done: #{(Asteroids::bankValueLive(asteroid).to_f/3600).round(2)} hours)"
            end
            if asteroid["orbital"]["type"] == "repeating-daily-time-commitment-8123956c-05" then
                return " (daily commitment: #{asteroid["orbital"]["timeCommitmentInHours"]} hours, recovered daily time: #{Metrics::recoveredDailyTimeInHours(asteroid["uuid"]).round(2)} hours)"
            end
            ""
        }
        uuid = asteroid["uuid"]
        isRunning = Runner::isRunning?(uuid)
        runningString = 
            if isRunning then
                " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
            else
                ""
            end
        "[asteroid] #{Asteroids::asteroidOrbitalTypeAsUserFriendlyString(asteroid["orbital"]["type"])}#{payloadFragment.call(asteroid)}#{orbitalFragment.call(asteroid)}#{runningString}"
    end

    # Asteroids::asteroids()
    def self.asteroids()
        NyxObjects::getSet("b66318f4-2662-4621-a991-a6b966fb4398")
    end

    # Asteroids::getAsteroidsTypeQuarkByQuarkUUID(targetuuid)
    def self.getAsteroidsTypeQuarkByQuarkUUID(targetuuid)
        Asteroids::asteroids()
            .select{|asteroid| asteroid["payload"]["type"] == "quarks" }
            .select{|asteroid| asteroid["payload"]["uuids"].include?(targetuuid) }
    end

    # Asteroids::rePayload(asteroid)
    def self.rePayload(asteroid)
        payload = Asteroids::makePayloadInteractivelyOrNull()
        return if payload.nil?
        asteroid["payload"] = payload
        puts JSON.pretty_generate(asteroid)
        Asteroids::reCommitToDisk(asteroid)
    end

    # Asteroids::reOrbital(asteroid)
    def self.reOrbital(asteroid)
        orbital = Asteroids::makeOrbitalInteractivelyOrNull()
        return if orbital.nil?
        asteroid["orbital"] = orbital
        puts JSON.pretty_generate(asteroid)
        Asteroids::reCommitToDisk(asteroid)
    end

    # Asteroids::asteroidDive(asteroid)
    def self.asteroidDive(asteroid)
        loop {

            asteroid = Asteroids::getOrNull(asteroid["uuid"])
            return if asteroid.nil?

            AsteroidsOfInterest::register(asteroid["uuid"])

            system("clear")

            Miscellaneous::horizontalRule(false)

            puts Asteroids::asteroidToString(asteroid)
            puts "uuid: #{asteroid["uuid"]}"
            puts "orbital type: #{asteroid["orbital"]["type"]}"
            puts "metric: #{Asteroids::metric(asteroid)}"

            unixtime = DoNotShowUntil::getUnixtimeOrNull(asteroid["uuid"])
            if unixtime then
                puts "DoNotShowUntil: #{Time.at(unixtime).to_s}"
            end

            Miscellaneous::horizontalRule(true)

            puts "Bank           : #{Bank::value(asteroid["uuid"]).to_f/3600} hours"
            puts "Bank 7 days    : #{Bank::valueOverTimespan(asteroid["uuid"], 86400*7).to_f/3600} hours"
            puts "Bank 24 hours  : #{Bank::valueOverTimespan(asteroid["uuid"], 86400).to_f/3600} hours"

            Miscellaneous::horizontalRule(true)

            menuitems = LCoreMenuItemsNX1.new()

            menuitems.item(
                "open",
                lambda {
                    Asteroids::openPayload(asteroid)
                    if !Asteroids::isRunning?(asteroid) and LucilleCore::askQuestionAnswerAsBoolean("Would you like to start ? ", false) then
                        Runner::start(asteroid["uuid"])
                    end
                }
            )

            menuitems.item(
                "start",
                lambda { Asteroids::asteroidStartSequence(asteroid) }
            )

            menuitems.item(
                "stop",
                lambda { Asteroids::asteroidStopSequence(asteroid) }
            )


            if asteroid["payload"]["type"] == "description" then
                menuitems.item(
                    "edit description",
                    lambda {
                        asteroid["payload"]["description"] = Miscellaneous::editTextUsingTextmate(asteroid["payload"]["description"]).strip
                        Asteroids::reCommitToDisk(asteroid)
                    }
                )
            end

            menuitems.item(
                "re-payload",
                lambda { Asteroids::rePayload(asteroid) }
            )

            menuitems.item(
                "re-orbital",
                lambda { Asteroids::reOrbital(asteroid) }
            )

            menuitems.item(
                "show json",
                lambda {
                    puts JSON.pretty_generate(asteroid)
                    LucilleCore::pressEnterToContinue()
                }
            )

            menuitems.item(
                "add time",
                lambda {
                    timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                    Asteroids::addTimeToAsteroid(asteroid, timeInHours*3600)
                }
            )

            if asteroid["payload"]["type"] == "quarks" then
                menuitems.item(
                    "quark (dive)",
                    lambda {
                        quark = Quarks::selectQuarkFromQuarkuuidsOrNull(asteroid["payload"]["uuids"])
                        return if quark.nil?
                        Quarks::quarkDive(quark)
                    }
                )
            end

            if asteroid["payload"]["type"] == "clique" then
                menuitems.item(
                    "clique (dive)",
                    lambda {
                        cliqueuuid = asteroid["payload"]["cliqueuuid"]
                        clique = Cliques::getOrNull(cliqueuuid)
                        return if clique.nil?
                        Cliques::cliqueDive(clique)
                    }
                )
            end

            menuitems.item(
                "destroy",
                lambda {
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy this asteroid ? ") then
                        Asteroids::asteroidStopSequence(asteroid)
                        Asteroids::asteroidDestroySequence(asteroid)
                    end
                }
            )

            Miscellaneous::horizontalRule(true)

            status = menuitems.prompt()
            break if !status

        }
    end

    # Asteroids::unixtimeShift_OlderTimesShiftLess(unixtime)
    def self.unixtimeShift_OlderTimesShiftLess(unixtime)
        # "Unixtime To Decreasing Metric Shift Normalised To Interval Zero One"
        unixtimeAtNextMidnightIsh = (1+Time.now.utc.to_i/86400) * 86400
        positiveDatationInMonths = unixtimeAtNextMidnightIsh-unixtime
        1 - positiveDatationInMonths.to_f/(86400*365*100)
    end

    # Asteroids::metric(asteroid)
    def self.metric(asteroid)
        uuid = asteroid["uuid"]

        orbital = asteroid["orbital"]

        return 1 if Asteroids::isRunning?(asteroid)

        if orbital["type"] == "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3" then
            return 0.72 - 0.01*Math.atan(asteroid["orbital"]["ordinal"])
            # We want the most recent one to come first
            # LIFO queue
        end

        if orbital["type"] == "singleton-time-commitment-7c67cb4f-77e0-4fd" then
            return 0.70 - 0.1*Metrics::best7SamplesTimeRatioOverPeriod(uuid, 86400*7)
        end

        if orbital["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            return Metrics::fall(0.69, orbital["type"]) + 0.001*Asteroids::unixtimeShift_OlderTimesShiftLess(asteroid["unixtime"])
        end

        if orbital["type"] == "repeating-daily-time-commitment-8123956c-05" then
            uuid = asteroid["uuid"]
            x1 = Metrics::targetRatioThenFall(0.68, uuid, orbital["timeCommitmentInHours"]*3600)
            x2 = - 0.1*Metrics::best7SamplesTimeRatioOverPeriod(uuid, 86400*7)
            return x1 + x2
        end

        if orbital["type"] == "on-going-until-completion-5b26f145-7ebf-498" then
            uuid = asteroid["uuid"]
            x1 = Metrics::targetRatioThenFall(0.66, uuid, Asteroids::onGoingUnilCompletionDailyExpectationInSeconds())
            x2 = -0.1*Metrics::best7SamplesTimeRatioOverPeriod(uuid, 86400*7)
            return x1 + x2
        end
 
        if orbital["type"] == "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2" then
            uuid = asteroid["uuid"]
            x1 = Metrics::targetRatioThenFall(0.64, uuid, Asteroids::onGoingUnilCompletionDailyExpectationInSeconds())
            x2 = -0.1*Metrics::best7SamplesTimeRatioOverPeriod(uuid, 86400*7)
            return x1 + x2
        end

        if orbital["type"] == "float-to-do-today-b0d902a8-3184-45fa-9808-1" then
            return 0.60 - 0.01*Asteroids::unixtimeShift_OlderTimesShiftLess(asteroid["unixtime"])
        end

        if orbital["type"] == "open-project-in-the-background-b458aa91-6e1" then
            return 0.21 - 0.01*Asteroids::unixtimeShift_OlderTimesShiftLess(asteroid["unixtime"])
        end

        if orbital["type"] == "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c" then
            return 0.49 - 0.01*Asteroids::unixtimeShift_OlderTimesShiftLess(asteroid["unixtime"])
        end

        puts asteroid
        raise "[Asteroids] error: 46b84bdb"
    end

    # Asteroids::runTimeIfAny(asteroid)
    def self.runTimeIfAny(asteroid)
        uuid = asteroid["uuid"]
        Runner::runTimeInSecondsOrNull(uuid) || 0
    end

    # Asteroids::bankValueLive(asteroid)
    def self.bankValueLive(asteroid)
        uuid = asteroid["uuid"]
        Bank::value(uuid) + Asteroids::runTimeIfAny(asteroid)
    end

    # Asteroids::isRunning?(asteroid)
    def self.isRunning?(asteroid)
        Runner::isRunning?(asteroid["uuid"])
    end

    # Asteroids::onGoingUnilCompletionDailyExpectationInSeconds()
    def self.onGoingUnilCompletionDailyExpectationInSeconds()
        0.5*3600
    end

    # Asteroids::isRunningForLong?(asteroid)
    def self.isRunningForLong?(asteroid)
        return false if !Asteroids::isRunning?(asteroid)
        uuid = asteroid["uuid"]
        orbital = asteroid["orbital"]
        if orbital["type"] == "singleton-time-commitment-7c67cb4f-77e0-4fd" then
            if Asteroids::bankValueLive(asteroid) >= orbital["timeCommitmentInHours"]*3600 then
                return true
            end
        end
        ( Runner::runTimeInSecondsOrNull(asteroid["uuid"]) || 0 ) > 3600
    end

    # Asteroids::asteroidOrbitalTypes()
    def self.asteroidOrbitalTypes()
        [
            "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3",
            "singleton-time-commitment-7c67cb4f-77e0-4fd",
            "repeating-daily-time-commitment-8123956c-05",
            "on-going-until-completion-5b26f145-7ebf-498",
            "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2",
            "float-to-do-today-b0d902a8-3184-45fa-9808-1",
            "open-project-in-the-background-b458aa91-6e1",
            "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
        ]
    end

    # Asteroids::asteroidOrbitalTypesThatTerminate()
    def self.asteroidOrbitalTypesThatTerminate()
        [
            "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3",
            "on-going-until-completion-5b26f145-7ebf-498",
            "float-to-do-today-b0d902a8-3184-45fa-9808-1",
            "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
        ]
    end

    # Asteroids::asteroidOrbitalTypesThatStart()
    def self.asteroidOrbitalTypesThatStart()
        [
            "singleton-time-commitment-7c67cb4f-77e0-4fd",
            "repeating-daily-time-commitment-8123956c-05",
            "on-going-until-completion-5b26f145-7ebf-498",
            "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2",
            "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
        ]
    end

    # Asteroids::tryAndMoveThisInboxItem(asteroid)
    def self.tryAndMoveThisInboxItem(asteroid)
        return if asteroid["orbital"]["type"] != "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
        if LucilleCore::askQuestionAnswerAsBoolean("done ? ") then
            Asteroids::asteroidDestroySequence(asteroid)
        else
            if LucilleCore::askQuestionAnswerAsBoolean("move to queue ? ") then
                asteroid["orbital"] = {
                    "type" => "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
                }
                Asteroids::reCommitToDisk(asteroid)
            else
                puts "Not done and not moved to queue. I am going to reOrbital"
                Asteroids::reOrbital(asteroid)
            end
        end
    end

    # Asteroids::asteroidToCalalystObject(asteroid)
    def self.asteroidToCalalystObject(asteroid)
        uuid = asteroid["uuid"]
        {
            "uuid"             => uuid,
            "body"             => Asteroids::asteroidToString(asteroid),
            "metric"           => Asteroids::metric(asteroid),
            "execute"          => lambda { |input|

                # ----------------------------------------
                # Not Running

                if input == ".." and asteroid["orbital"]["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" and !Runner::isRunning?(uuid) then
                    Asteroids::asteroidStartSequence(asteroid)
                    Asteroids::tryAndMoveThisInboxItem(asteroid)
                    return
                end

                if input == ".." and !Runner::isRunning?(uuid) and asteroid["orbital"]["type"] == "top-priority-ca7a15a8-42fa-4dd7-be72-5bfed3" and asteroid["payload"]["type"] == "description" then
                    if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ") then
                        Asteroids::asteroidDestroySequence(asteroid)
                        return
                    end
                end

                if input == ".." and !Runner::isRunning?(uuid) and Asteroids::asteroidOrbitalTypesThatStart().include?(asteroid["orbital"]["type"]) then
                    Asteroids::asteroidStartSequence(asteroid)
                    return
                end

                if input == ".." and !Runner::isRunning?(uuid) and asteroid["payload"]["type"] == "description" then
                    if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                        Asteroids::asteroidDestroySequence(asteroid)
                        return
                    end
                end

                # ----------------------------------------
                # Running

                if input == ".." and asteroid["orbital"]["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" and Runner::isRunning?(uuid) then
                    if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                        Asteroids::asteroidDestroySequence(asteroid)
                        return
                    end
                    Asteroids::asteroidStopSequence(asteroid)
                    Asteroids::tryAndMoveThisInboxItem(asteroid)
                    return
                end

                if input == ".." and Runner::isRunning?(uuid) and Asteroids::asteroidOrbitalTypesThatTerminate().include?(asteroid["orbital"]["type"]) then
                    if LucilleCore::askQuestionAnswerAsBoolean("-> done/destroy ? ", false) then
                        Asteroids::asteroidDestroySequence(asteroid)
                        return
                    else
                        Asteroids::asteroidStopSequence(asteroid)
                    end
                    return
                end

                if input == ".." and Runner::isRunning?(uuid) and !Asteroids::asteroidOrbitalTypesThatTerminate().include?(asteroid["orbital"]["type"]) then
                    Asteroids::asteroidStopSequence(asteroid)
                    return
                end

                Asteroids::asteroidDive(asteroid) 
            },
            "isRunning"        => Asteroids::isRunning?(asteroid),
            "isRunningForLong" => Asteroids::isRunningForLong?(asteroid),
            "x-asteroid"       => asteroid
        }
    end

    # Asteroids::catalystObjects()
    def self.catalystObjects()

        # Asteroids::asteroids()
        #    .map{|asteroid| Asteroids::asteroidToCalalystObject(asteroid) }

        AsteroidsOfInterest::getUUIDs()
            .map{|uuid| Asteroids::getOrNull(uuid) }
            .compact
            .map{|asteroid| Asteroids::asteroidToCalalystObject(asteroid) }
    end

    # Asteroids::asteroidStartSequence(asteroid)
    def self.asteroidStartSequence(asteroid)

        BTreeSets::set(nil, "d015bfdd-deb6-447f-97af-ab9e87875148:#{Time.new.to_s[0, 10]}", asteroid["uuid"], asteroid["uuid"])
        # We cache the value of any asteroid that has started to help with the catalyst objects caching
        # An asteroid that have been started (from diving into it) is not necessarily in the list of 
        # those that the catalyst objects caching will select, and in such a case it would be running
        # wihtout being displayed

        return if Asteroids::isRunning?(asteroid)

        uuid = asteroid["uuid"]
        orbital = asteroid["orbital"]

        if orbital["type"] == "singleton-time-commitment-7c67cb4f-77e0-4fd" then
            if Bank::value(uuid) >= orbital["timeCommitmentInHours"]*3600 then
                puts "singleton time commitment asteroid is completed, destroying it..."
                LucilleCore::pressEnterToContinue()
                Asteroids::asteroidDestroySequence(asteroid)
                return
            end
        end

        Runner::start(asteroid["uuid"])

        if asteroid["payload"]["type"] == "spin" then
            Asteroids::openPayload(asteroid)
        end

        if asteroid["payload"]["type"] == "quarks" then
            Asteroids::openPayload(asteroid)
        end
    end

    # Asteroids::addTimeToAsteroid(asteroid, timespanInSeconds)
    def self.addTimeToAsteroid(asteroid, timespanInSeconds)
        puts "Adding #{timespanInSeconds} seconds to #{Asteroids::asteroidToString(asteroid)}"
        Bank::put(asteroid["uuid"], timespanInSeconds)
        Bank::put(asteroid["orbital"]["type"], timespanInSeconds)
    end

    # Asteroids::asteroidStopSequence(asteroid)
    def self.asteroidStopSequence(asteroid)
        return if !Asteroids::isRunning?(asteroid)
        timespan = Runner::stop(asteroid["uuid"])
        return if timespan.nil?
        timespan = [timespan, 3600*2].min # To avoid problems after leaving things running

        Asteroids::addTimeToAsteroid(asteroid, timespan)

        payload = asteroid["payload"]
        orbital = asteroid["orbital"]

        if orbital["type"] == "singleton-time-commitment-7c67cb4f-77e0-4fd" then
            if Bank::value(asteroid["uuid"]) >= orbital["timeCommitmentInHours"]*3600 then
                puts "time commitment asteroid is completed, destroying it..."
                LucilleCore::pressEnterToContinue()
                Asteroids::asteroidDestroySequence(asteroid)
            end
        end

        if payload["type"] == "spin" then
            spin = NyxObjects::getOrNull(payload["uuid"])
            if spin then
                Spins::ensureSpinDescriptionOrNothing(spin)
            end
        end
    end

    # Asteroids::asteroidDestructionQuarkHandling(quark)
    def self.asteroidDestructionQuarkHandling(quark)
        puts Quarks::quarkToString(quark)
        return if Bosons::getCliquesForQuark(quark).size>0
        if LucilleCore::askQuestionAnswerAsBoolean("Retain quark ? ") then
            Quarks::ensureQuarkDescription(quark)
            Quarks::ensureAtLeastOneQuarkCliques(quark)
        else
            Quarks::destroyQuarkByUUID(quark["uuid"])
        end
    end

    # Asteroids::asteroidDestroySequence(asteroid)
    def self.asteroidDestroySequence(asteroid)
        if Asteroids::isRunning?(asteroid) then
            timespan = Runner::stop(asteroid["uuid"])
            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
            Asteroids::addTimeToAsteroid(asteroid, timespan)
        end

        if asteroid["payload"]["type"] == "spin" then
            NyxObjects::destroy(asteroid["payload"]["uuid"])
        end

        if asteroid["payload"]["type"] == "quarks" then
            asteroid["payload"]["uuids"].each{|uuid|
                quark = Quarks::getOrNull(uuid)
                next if quark.nil?
                Asteroids::asteroidDestructionQuarkHandling(quark)
            }
        end

        NyxObjects::destroy(asteroid["uuid"])
    end

    # Asteroids::openPayload(asteroid)
    def self.openPayload(asteroid)
        if asteroid["payload"]["type"] == "spin" then
            spin = NyxObjects::getOrNull(asteroid["payload"]["uuid"])
            return if spin.nil?
            puts JSON.pretty_generate(spin)
            Spins::openSpin(spin)
        end
        if asteroid["payload"]["type"] == "quarks" then
            quark = Quarks::selectQuarkFromQuarkuuidsOrNull(asteroid["payload"]["uuids"])
            return if quark.nil?
            Quarks::openQuark(quark)
        end
    end

    # Asteroids::diveAsteroidOrbitalType(orbitalType)
    def self.diveAsteroidOrbitalType(orbitalType)
        asteroids = Asteroids::asteroids().select{|asteroid| asteroid["orbital"]["type"] == orbitalType }
        asteroid = LucilleCore::selectEntityFromListOfEntitiesOrNull("asteroid", asteroids, lambda{|asteroid| Asteroids::asteroidToString(asteroid) })
        return if asteroid.nil?
        Asteroids::asteroidDive(asteroid)
    end

    # Asteroids::main()
    def self.main()
        loop {
            system("clear")
            options = [
                "make new asteroid",
                "dive asteroids"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            break if option.nil?
            if option == "make new asteroid" then
                asteroid = Asteroids::issueAsteroidInteractivelyOrNull()
                next if asteroid.nil?
                puts JSON.pretty_generate(asteroid)
            end
            if option == "dive asteroids" then
                loop {
                    orbitalType = LucilleCore::selectEntityFromListOfEntitiesOrNull("asteroid", Asteroids::asteroidOrbitalTypes())
                    break if orbitalType.nil?
                    Asteroids::diveAsteroidOrbitalType(orbitalType)
                }
            end
        }
    end
end

Thread.new {
    loop {
        sleep 120
        Asteroids::asteroids()
            .map{|asteroid| Asteroids::asteroidToCalalystObject(asteroid) }
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse
            .first(50)
            .each{|object| AsteroidsOfInterest::register(object["x-asteroid"]["uuid"]) }
        sleep 1200
    }
}
