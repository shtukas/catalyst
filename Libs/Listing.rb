
class SpaceControl

    def initialize(remaining_vertical_space)
        @remaining_vertical_space = remaining_vertical_space
    end

    def putsline(line) # boolean
        vspace = CommonUtils::verticalSize(line)
        return false if vspace > @remaining_vertical_space
        puts line
        @remaining_vertical_space = @remaining_vertical_space - vspace
        true
    end
end

class Speedometer
    def initialize()
    end

    def start_contest()
        @contest = []
    end

    def contest_entry(description, l)
        t1 = Time.new.to_f
        l.call()
        t2 = Time.new.to_f
        @contest << {
            "description" => description,
            "time"        => t2 - t1
        }
    end

    def end_contest()
        @contest
            .sort_by{|entry| entry["time"] }
            .reverse
            .each{|entry| puts "#{"%6.2f" % entry["time"]}: #{entry["description"]}" }
    end

    def start_unit(description)
        @description = description
        @t = Time.new.to_f
    end

    def end_unit()
        puts "#{"%6.2f" % (Time.new.to_f - @t)}: #{@description}"
    end

end

class Listing

    # -----------------------------------------
    # Data

    # Listing::listable(item)
    def self.listable(item)
        return true if NxBalls::itemIsActive(item)
        return false if !DoNotShowUntil1::isVisible(item)
        true
    end

    # Listing::canBeDefault(item)
    def self.canBeDefault(item)
        return false if TmpSkip1::isSkipped(item)
        return true if NxBalls::itemIsRunning(item)
        return false if !DoNotShowUntil1::isVisible(item)
        return false if TmpSkip1::isSkipped(item)
        return false if item["mikuType"] == "TxCondition"
        true
    end

    # Listing::isInterruption(item)
    def self.isInterruption(item)
        item["interruption"]
    end

    # Listing::toString2(store, item, context = nil)
    def self.toString2(store, item, context = nil)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "      "
        line = "#{storePrefix} #{PolyFunctions::toString(item, context)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil1::suffixString(item)}#{Catalyst::donationSuffix(item)}"

        if !DoNotShowUntil1::isVisible(item) and !NxBalls::itemIsActive(item) then
            line = line.yellow
        end

        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end

        if NxBalls::itemIsActive(item) then
            line = line.green
        end

        line
    end

    # Listing::items()
    def self.items()
        items = [
            Anniversaries::listingItems(),
            Waves::muiItemsInterruption(),
            NxFloats::listingItems(),
            DropBox::items(),
            Desktop::listingItems(),
            NxOndates::listingItems(),
            NxMiniProjects::listingItems(),
            TargetNumbers::listingItems(),
            NxThreads::listingItems(),
            NxBackups::listingItems(),
            Waves::muiItemsNotInterruption(),
        ]
            .flatten
            .select{|item| Listing::listable(item) }
            .reduce([]){|selected, item|
                if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }
    end

    # -----------------------------------------
    # Ops

    # Listing::speedTest()
    def self.speedTest()

        spot = Speedometer.new()

        spot.start_contest()
        spot.contest_entry("NxBalls::activeItems()", lambda{ NxBalls::activeItems() })
        spot.contest_entry("DropBox::items()", lambda { DropBox::items() })
        spot.contest_entry("Desktop::listingItems()", lambda { Desktop::listingItems() })
        spot.contest_entry("Anniversaries::listingItems()", lambda { Anniversaries::listingItems() })
        spot.contest_entry("TargetNumbers::listingItems()", lambda{ TargetNumbers::listingItems() })
        spot.contest_entry("Waves::muiItemsInterruption()", lambda{ Waves::muiItemsInterruption() })
        spot.contest_entry("NxOndates::listingItems()", lambda{ NxOndates::listingItems() })
        spot.contest_entry("NxBackups::listingItems()", lambda{ NxBackups::listingItems() })
        spot.contest_entry("NxFloats::listingItems()", lambda{ NxFloats::listingItems() })
        spot.contest_entry("Waves::muiItemsNotInterruption()", lambda{ Waves::muiItemsNotInterruption() })
        spot.end_contest()

        puts ""

        spot.start_unit("Listing::items()")
        Listing::items()
        spot.end_unit()

        spot.start_unit("Listing::items().first(100) >> Listing::toString2(store, item)")
        store = ItemStore.new()
        items = Listing::items().first(100)
        items.each {|item| Listing::toString2(store, item) }
        spot.end_unit()

        LucilleCore::pressEnterToContinue()
    end

    # Listing::checkForCodeUpdates()
    def self.checkForCodeUpdates()
        if CommonUtils::isOnline() and (CommonUtils::localLastCommitId() != CommonUtils::remoteLastCommitId()) then
            puts "Attempting to download new code"
            output = `#{File.dirname(__FILE__)}/../pull-from-origin`.strip
            return (output == "Already up to date.")
        end
        false
    end

    # Listing::dispatch(items)
    def self.dispatch(items)
        system('clear')

        i1s, i2s = items.partition{|item| item["listing45"] }
        i1s = i1s.sort_by{|i| i["listing45"] } 
        if i2s.empty? then
            return i1s
        end
        i3 = i2s.shift

        puts "-- (dispatch) ---------"
        i1s
            .sort_by{|i| i["listing45"] }
            .each{|i| puts "#{"%5.2f" % i["listing45"]} : #{PolyFunctions::toString(i)}" }

        puts "dispatch: '#{PolyFunctions::toString(i3).green}'"

        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("dispatch mode", ["do now (default)", "set listing position", "position next", "done", "push", "push by 2 hours", "Cx04", "sort"])

        if option.nil? then
            PolyActions::doubleDot(i3)
            return Listing::dispatch(i1s + i2s)
        end

        if option == "do now (default)" then
            PolyActions::doubleDot(i3)
            return Listing::dispatch(i1s + i2s)
        end

        if option == "done" then
            PolyActions::done(i3)
            return Listing::dispatch(i1s + i2s)
        end

        if option == "Cx04" then
            cx04 = Cx04::architectOrNull()
            return Listing::dispatch(i1s + [i3] + i2s) if cx04.nil?
            Items::setAttribute(i3["uuid"], "cx04", cx04)
            return Listing::dispatch(i1s + i2s)
        end

        if option == "set listing position" then
            position = LucilleCore::askQuestionAnswerAsString("position for '#{PolyFunctions::toString(i3).green}' : ").to_f
            Items::setAttribute(i3["uuid"], "listing45", position)
            i3["listing45"] =  position
            return Listing::dispatch(i1s + [i3] + i2s)
        end

        if option == "position next" then
            lastPosition = Listing::items()
                            .select{|i| i["cx04"].nil? }
                            .select{|i| i["listing45"] }
                            .map{|i| i["listing45"] }
                            .reduce(0){|top, position| [top, position].max }
            Items::setAttribute(i3["uuid"], "listing45", lastPosition+1)
            i3["listing45"] =  lastPosition
            return Listing::dispatch(i1s + [i3] + i2s)
        end

        if option == "push" then
            unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
            if unixtime.nil? then
                return Listing::dispatch(i1s + [i3] + i2s)
            end
            NxBalls::stop(i3)
            puts "pushing until '#{Time.at(unixtime).to_s.green}'"
            DoNotShowUntil1::setUnixtime(i3["uuid"], unixtime)
            return Listing::dispatch(i1s + i2s)
        end

        if option == "push by 2 hours" then
            unixtime = Time.new.to_i + 3600*2
            NxBalls::stop(i3)
            puts "pushing until '#{Time.at(unixtime).to_s.green}'"
            DoNotShowUntil1::setUnixtime(i3["uuid"], unixtime)
            return Listing::dispatch(i1s + i2s)
        end

        if option == "sort" then
            selected, _ = LucilleCore::selectZeroOrMore("elements", [], i1s, lambda{|i| PolyFunctions::toString(i) })
            selected.reverse.each{|i|
                firstPosition = Listing::items()
                                .select{|i| i["cx04"].nil? }
                                .select{|i| i["listing45"] }
                                .map{|i| i["listing45"] }
                                .reduce(0){|top, position| [top, position].min }
                Items::setAttribute(i["uuid"], "listing45", firstPosition - 1)
            }
            return Listing::dispatch(
                Listing::items().select{|i| i["cx04"].nil? }
            )
        end
    end

    # Listing::listing(initialCodeTrace)
    def self.listing(initialCodeTrace)
        loop {

            if CommonUtils::catalystTraceCode() != initialCodeTrace then
                puts "Code change detected"
                exit
            end

            if Config::isPrimaryInstance() then
                Items::processJournal()
                Bank1::processJournal()
                DoNotShowUntil1::processJournal()
            end

            if Config::isPrimaryInstance() and ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("fd3b5554-84f4-40c2-9c89-1c3cb2a67717", 86400) then
                Catalyst::periodicPrimaryInstanceMaintenance()
            end

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
            store = ItemStore.new()

            system("clear")

            items = Listing::items()

            cx04s = Cx04::cx04sFromItems(items)


            items = items.select{|item| item["cx04"].nil? }

            items = Listing::dispatch(items)

            items = items.sort_by{|item| item["listing45"] }

            items = items.take(10) + NxBalls::activeItems() + items.drop(10)

            items = Prefix::addPrefix(items)

            system("clear")

            spacecontrol.putsline ""

            if !cx04s.empty? then
                cx04s.each{|item|
                    store.register(item, false)
                    line = Listing::toString2(store, item, "main-listing-1315")
                    status = spacecontrol.putsline line
                }
                spacecontrol.putsline ""
            end

            items
                .reduce([]){|selected, item|
                    if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                        selected
                    else
                        selected + [item]
                    end
                }
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    line = Listing::toString2(store, item, "main-listing-1315")
                    status = spacecontrol.putsline line
                    break if !status
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            if input == "exit" then
                return
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Listing::main()
    def self.main()
        initialCodeTrace = CommonUtils::catalystTraceCode()
        Thread.new {
            loop {
                (lambda {
                    return if !NxBalls::shouldNotify()
                    CommonUtils::onScreenNotification("Catalyst", "running ball is over running")
                }).call()
                sleep 120
            }
        }
        loop {
            Listing::listing(initialCodeTrace)
        }
    end
end
