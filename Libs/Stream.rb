
class Stream

    # Stream::toString3(item)
    def self.toString3(item)
        toString = Listing::redRewrite(item, PolyFunctions::toString(item))
        "#{toString}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil::suffixString(item)}#{OpenCycles::suffix(item)}#{TxCores::suffix(item)}"
    end

    # Stream::main()
    def self.main()

        initialCodeTrace = CommonUtils::catalystTraceCode()

        latestCodeTrace = initialCodeTrace

        Listing::checkForCodeUpdates()

        Thread.new {
            loop {
                sleep 300
                Listing::checkForCodeUpdates()
            }
        }

        loop {

            if CommonUtils::catalystTraceCode() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            EventsTimelineProcessor::procesLine()

            if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("fd3b5554-84f4-40c2-9c89-1c3cb2a67717", 3600) then
                Listing::maintenance()
            end

            store = ItemStore.new()
            item = Listing::items().first
            if item["mikuType"] == "NxThread" then
                item = NxThreads::childrenInOrder(item).first
                return if item.nil?
            end

            fragment = (lambda {|item|
                if item["mikuType"] == "Wave" then
                    return "[enter] to start"
                end
                if item["mikuType"] == "PhysicalTarget" then
                    return "[enter] for access"
                end
                if item["mikuType"] == "Backup" then
                    return "[enter] for done"
                end
                if item["mikuType"] == "NxTask" then
                    return "[enter] for processing"
                end
                raise "(error: 59585a2d-fe88) I do not know how to compute fragment for item: #{item}"
            }).call(item)

            print "#{Time.new.utc.iso8601.red}: #{Stream::toString3(item).green}#{NxThreads::suffix(item)}: #{fragment.green} > "
            input = STDIN.gets().strip
            return if input == "exit"

            if input == "'" then
                command = LucilleCore::askQuestionAnswerAsString("> command: ")
                next if command == ""
                store = ItemStore.new()
                store.register(item, true)
                ListingCommandsAndInterpreters::interpreter(command, store)
                next
            end

            if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                next
            end

            if item["mikuType"] == "PhysicalTarget" then
                PolyActions::access(item)
                next
            end
            if item["mikuType"] == "Backup" then
                XCache::set("1c959874-c958-469f-967a-690d681412ca:#{item["uuid"]}", Time.new.to_i)
                next
            end
            if item["mikuType"] == "Wave" then
                PolyFunctions::toString(item).green
                NxBalls::start(item)
                PolyActions::access(item)
                if LucilleCore::askQuestionAnswerAsBoolean("#{Time.new.utc.iso8601.red}: #{Waves::toString(item).green}: for done-ing: ", true) then
                    NxBalls::stop(item)
                    Waves::performWaveDone(item)
                end
                next
            end
            if item["mikuType"] == "NxTask" then
                NxBalls::start(item)
                PolyActions::access(item)
                LucilleCore::pressEnterToContinue("[enter] to stop: ")
                NxBalls::stop(item)
                if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", false) then
                    Catalyst::destroy(item["uuid"])
                else
                    if item["parent-1328"].nil? then
                        NxThreads::interactivelySelectAndInstallInThread(item)
                    end
                end
                next
            end

            raise "(error: ac6f-c5bad8fb5527) could not do: #{item}"
        }
    end
end
