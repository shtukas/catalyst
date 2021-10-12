# encoding: UTF-8

class Nx51s

    # Nx51s::itemsFolderPath()
    def self.itemsFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/Nx51s"
    end

    # Nx51s::commitItemToDisk(item)
    def self.commitItemToDisk(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{Nx51s::itemsFolderPath()}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(item)) }
    end

    # Nx51s::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        filename = "#{uuid}.json"
        filepath = "#{Nx51s::itemsFolderPath()}/#{filename}"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Nx51s::items()
    def self.items()
        LucilleCore::locationsAtFolder(Nx51s::itemsFolderPath())
            .select{|location| location[-5, 5] == ".json" }
            .map{|location| JSON.parse(IO.read(location)) }
            .sort{|x1, x2|  x1["unixtime"] <=> x2["unixtime"]}
    end

    # Nx51s::delete(uuid)
    def self.delete(uuid)
        filename = "#{uuid}.json"
        filepath = "#{Nx51s::itemsFolderPath()}/#{filename}"
        puts "filepath: #{filepath}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # --------------------------------------------------
    # Makers

    # Nx51s::interactivelyDetermineNewItemUnixtimeManuallyPosition()
    def self.interactivelyDetermineNewItemUnixtimeManuallyPosition()
        system("clear")
        items = Nx51s::items().first(Utils::screenHeight()-3)
        return Time.new.to_f if items.size == 0
        items.each_with_index{|item, i|
            puts "[#{i.to_s.rjust(2)}] #{Nx51s::toString(item)}"
        }
        puts "new first | <n> # index of previous item".yellow
        command = LucilleCore::askQuestionAnswerAsString("> ")
        if command == "new first" then
            return items[0]["unixtime"]-1 
        else
            # Here we interpret as index of an element
            i = command.to_i
            items = items.drop(i)
            if items.size == 0 then
                return Time.new.to_f
            end
            if items.size == 1 then
                return items[0]["unixtime"]+1 
            end
            if items.size >= 2 then
                return (items[0]["unixtime"]+items[1]["unixtime"]).to_f/2
            end
            raise "fa7e03a4-ce26-40c4-82d5-151f98908dca"
        end
        system('clear')
    end

    # Nx51s::interactivelyDetermineNewItemUnixtime()
    def self.interactivelyDetermineNewItemUnixtime()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("unixtime type", ["manually position", "last (default)"])
        if type.nil? then
            return Time.new.to_f
        end
        if type == "manually position" then
            return Nx51s::interactivelyDetermineNewItemUnixtimeManuallyPosition()
        end
        if type == "last (default)" then
            return Time.new.to_f
        end
        raise "13a8d479-3d49-415e-8d75-7d0c5d5c695e"
    end

    # Nx51s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = LucilleCore::timeStringL22()
        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end
        coreDataId = CoreData::interactivelyCreateANewDataObjectReturnIdOrNull()
        unixtime = Nx51s::interactivelyDetermineNewItemUnixtime()
        Nx51s::commitItemToDisk({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "coreDataId"  => coreDataId,
        })
        Nx51s::getItemByUUIDOrNull(uuid)
    end

    # Nx51s::issueItemUsingText(text, unixtime)
    def self.issueItemUsingText(text, unixtime)
        uuid         = LucilleCore::timeStringL22()
        description  = text.strip.lines.first.strip || "todo text @ #{Time.new.to_s}" 
        coreDataId      = CoreData::issueTextDataObjectUsingText(text)
        Nx51s::commitItemToDisk({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "coreDataId"  => coreDataId,
        })
        Nx51s::getItemByUUIDOrNull(uuid)
    end

    # Nx51s::issueItemUsingLocation(location)
    def self.issueItemUsingLocation(location)
        uuid        = LucilleCore::timeStringL22()
        description = File.basename(location)
        coreDataId = CoreData::issueAionPointDataObjectUsingLocation(location)
        Nx51s::commitItemToDisk({
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "coreDataId"  => coreDataId,
        })
        Nx51s::getItemByUUIDOrNull(uuid)
    end

    # --------------------------------------------------
    # Operations

    # Nx51s::getItemType(item)
    def self.getItemType(item)
        type = KeyValueStore::getOrNull(nil, "bb9de7f7-022c-4881-bf8d-fb749cd2cc77:#{item["uuid"]}")
        return type if type
        type1 = CoreData::contentTypeOrNull(item["coreDataId"])
        type2 = type1 || "line"
        KeyValueStore::set(nil, "bb9de7f7-022c-4881-bf8d-fb749cd2cc77:#{item["uuid"]}", type2)
        type2
    end

    # Nx51s::toString(item)
    def self.toString(item)
        "[nx51] #{item["description"]} (#{Nx51s::getItemType(item)})"
    end

    # Nx51s::toStringForNS19(item)
    def self.toStringForNS19(item)
        "[nx51] #{item["description"]}"
    end

    # Nx51s::toStringForNS16(item, rt)
    def self.toStringForNS16(item, rt)
        "[nx51] (#{"%4.2f" % rt}) #{item["description"]} (#{Nx51s::getItemType(item)})"
    end

    # Nx51s::accessContent(item)
    def self.accessContent(item)
        if item["coreDataId"].nil? then
            puts "description: #{item["description"]}"
            LucilleCore::pressEnterToContinue()
            return
        end
        CoreData::accessWithOptionToEdit(item["coreDataId"])
    end

    # --------------------------------------------------
    # nx16s

    # Nx51s::run(nx51)
    def self.run(nx51)

        system("clear")

        uuid = nx51["uuid"]
        puts "#{Nx51s::toString(nx51)}".green
        puts "Starting at #{Time.new.to_s}"

        nxball = NxBalls::makeNxBall([uuid])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Nx50 item running for more than an hour")
                end
            }
        }

        note = StructuredTodoTexts::getNoteOrNull(uuid)
        if note then
            puts "Note ---------------------"
            puts note.green
            puts "--------------------------"
        end

        Nx51s::accessContent(nx51)

        loop {

            system("clear")

            puts "#{Nx51s::toString(nx51)} (#{NxBalls::runningTimeString(nxball)})".green
            puts "uuid: #{uuid}".yellow
            puts "coreDataId: #{nx51["coreDataId"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx51["uuid"])}".yellow

            note = StructuredTodoTexts::getNoteOrNull(uuid)
            if note then
                puts "Note ---------------------"
                puts note.green
                puts "--------------------------"
            end

            puts "access | note | [] | <datecode> | detach running | pause | pursue | update description | update contents | update unixtime | show json | destroy | exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                Nx51s::accessContent(nx51)
                next
            end

            if command == "note" then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(nx51["uuid"]) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if command == "[]" then
                StructuredTodoTexts::applyT(uuid)
                note = StructuredTodoTexts::getNoteOrNull(uuid)
                if note then
                    puts "Note ---------------------"
                    puts note.green
                    puts "--------------------------"
                end
                next
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(Nx51s::toString(nx51), Time.new.to_i, [uuid])
                break
            end

            if Interpreting::match("pause", command) then
                NxBalls::closeNxBall(nxball, true)
                puts "Starting pause at #{Time.new.to_s}"
                LucilleCore::pressEnterToContinue()
                nxball = NxBalls::makeNxBall([uuid])
                next
            end

            if command == "pursue" then
                # We close the ball and issue a new one
                NxBalls::closeNxBall(nxball, true)
                nxball = NxBalls::makeNxBall([uuid])
                next
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(nx51["description"]).strip
                if description.size > 0 then
                    nx51["description"] = description
                    Nx51s::commitItemToDisk(nx51)
                end
                next
            end

            if Interpreting::match("update contents", command) then
                puts "update contents against the new NxAxiom library is not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if Interpreting::match("update unixtime", command) then
                nx51["unixtime"] = Nx51s::interactivelyDetermineNewItemUnixtime()
                Nx51s::commitItemToDisk(nx51)
                next
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(nx51)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Nx51s::toString(nx51)}' ? ", true) then
                    Nx51s::delete(nx51["uuid"])
                    break
                end
                next
            end
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # Nx51s::ns16OrNull(nx51)
    def self.ns16OrNull(nx51)
        uuid = nx51["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        return nil if !InternetStatus::ns16ShouldShow(uuid)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        note = StructuredTodoTexts::getNoteOrNull(uuid)
        noteStr = note ? " [note]" : ""
        announce = "#{Nx51s::toStringForNS16(nx51, rt)}#{noteStr} (rt: #{rt.round(2)})".gsub("(0.00)", "      ")
        {
            "uuid"     => uuid,
            "announce" => announce,
            "commands"    => ["..", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    Nx51s::run(nx51)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Nx51s::toString(nx51)}' ? ", true) then
                        Nx51s::delete(nx51["uuid"])
                    end
                end
            },
            "run" => lambda {
                Nx51s::run(nx51)
            },
            "rt" => rt,
            "unixtime-bd06fbf9" => nx51["unixtime"]
        }
    end

    # Nx51s::ns16s()
    def self.ns16s()
        LucilleCore::locationsAtFolder("/Users/pascal/Desktop/Work Items (Nx51s)").each{|location|
            puts "[Nx51] #{location}"
            Nx51s::issueItemUsingLocation(location)
            LucilleCore::removeFileSystemLocation(location)
        }
        Nx51s::items()
            .map{|item| Nx51s::ns16OrNull(item) }
            .compact
    end

    # --------------------------------------------------

    # Nx51s::nx19s()
    def self.nx19s()
        Nx51s::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Nx51s::toStringForNS19(item),
                "lambda"   => lambda { Nx51s::run(item) }
            }
        }
    end
end
