
class Stream

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

            commands = (lambda {|item|
                if item["mikuType"] == "Wave" then
                    return "done"
                end
                if item["mikuType"] == "PhysicalTarget" then
                    return ".."
                end
                if item["mikuType"] == "Backup" then
                    return "do and [enter]"
                end
                raise "(error: 59585a2d-fe88) I do not know how to computer commands for item: #{item}"
            }).call(item)

            print "#{PolyFunctions::toString(item).green}: #{commands.green} > "
            input = STDIN.gets().strip
            return if input == "exit"

            if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                next
            end

            if item["mikuType"] == "PhysicalTarget" then
                if input == ".." then
                    PolyActions::access(item)
                end
            end
            if item["mikuType"] == "Backup" then
                XCache::set("1c959874-c958-469f-967a-690d681412ca:#{item["uuid"]}", Time.new.to_i)
            end
        }
    end
end
