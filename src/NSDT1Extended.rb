
class NSDataType1PatternSearchLookup

    # NSDataType1PatternSearchLookup::databaseFilepath()
    def self.databaseFilepath()
        "#{Miscellaneous::catalystDataCenterFolderpath()}/NSDataType1PatternSearchLookup.sqlite3"
    end

    # NSDataType1PatternSearchLookup::selectNSDataType1UUIDsByPattern(pattern)
    def self.selectNSDataType1UUIDsByPattern(pattern)
        db = SQLite3::Database.new(NSDataType1PatternSearchLookup::databaseFilepath())
        db.results_as_hash = true
        answer = []
        db.execute( "select * from lookup" , [] ) do |row|
            fragment = row['_fragment_']
            if fragment.downcase.include?(pattern.downcase) then
                answer << row['_objectuuid_']
            end
            
        end
        db.close
        answer.uniq
    end

    # NSDataType1PatternSearchLookup::removeRecordsAgainstNode(objectuuid)
    def self.removeRecordsAgainstNode(objectuuid)
        db = SQLite3::Database.new(NSDataType1PatternSearchLookup::databaseFilepath())
        db.execute "delete from lookup where _objectuuid_=?", [objectuuid]
        db.close
    end

    # NSDataType1PatternSearchLookup::addRecord(objectuuid, fragment)
    def self.addRecord(objectuuid, fragment)
        db = SQLite3::Database.new(NSDataType1PatternSearchLookup::databaseFilepath())
        db.execute "insert into lookup (_objectuuid_, _fragment_) values ( ?, ? )", [objectuuid, fragment]
        db.close
    end

    # NSDataType1PatternSearchLookup::updateLookupForNode(node)
    def self.updateLookupForNode(node)
        NSDataType1PatternSearchLookup::removeRecordsAgainstNode(node["uuid"])
        NSDataType1PatternSearchLookup::addRecord(node["uuid"], node["uuid"])
        NSDataType1PatternSearchLookup::addRecord(node["uuid"], NSDataType1::toString(node))
    end

    # NSDataType1PatternSearchLookup::rebuildLookup()
    def self.rebuildLookup()
        NSDataType1::objects()
        .each{|node|
            puts node["uuid"]
            NSDataType1PatternSearchLookup::updateLookupForNode(node)
        }
    end
end

class NSDT1ExtendedDataLookups

    # NSDT1ExtendedDataLookups::nodeMatchesPattern(point, pattern)
    # Legacy
    def self.nodeMatchesPattern(point, pattern)
        return true if point["uuid"].downcase.include?(pattern.downcase)
        return true if NSDataType1::toString(point).downcase.include?(pattern.downcase)
        return true if Arrows::getTargetsForSource(point).any?{|child| GenericObjectInterface::toString(child).downcase.include?(pattern.downcase) }
        false
    end

    # NSDT1ExtendedDataLookups::selectNodesPerPattern_v1(pattern)
    # Legacy
    def self.selectNodesPerPattern_v1(pattern)
        # 2020-08-15
        # This is a legacy function that I keep for sentimental reasons,
        # The direct look up using NSDT1ExtendedDataLookups::nodeMatchesPattern has been replace by NSDT1ExtendedDataLookups
        NSDataType1::objects()
            .select{|point| NSDT1ExtendedDataLookups::nodeMatchesPattern(point, pattern) }
    end

    # NSDT1ExtendedDataLookups::selectNodesPerPattern_v2(pattern)
    def self.selectNodesPerPattern_v2(pattern)
        NSDataType1PatternSearchLookup::selectNSDataType1UUIDsByPattern(pattern)
            .map{|uuid| NSDataType1::getOrNull(uuid) }
            .compact
    end

    # NSDT1ExtendedDataLookups::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        NSDT1ExtendedDataLookups::selectNodesPerPattern_v2(pattern)
            .map{|node|
                {
                    "description"   => NSDataType1::toString(node),
                    "referencetime" => NSDataType1::getReferenceUnixtime(node),
                    "dive"          => lambda{ NSDataType1::landing(node) }
                }
            }
    end
end

class NSDT1ExtendedUserInterface

    # NSDT1ExtendedUserInterface::interactiveSearch(): Array[Nodes]
    def self.interactiveSearch()

        Curses::init_screen
        # Initializes a standard screen. At this point the present state of our terminal is saved and the alternate screen buffer is turned on

        Curses::noecho
        # Disables characters typed by the user to be echoed by Curses.getch as they are typed.

        win1 = Curses::Window.new(1, Miscellaneous::screenWidth(), 0, 0)
        win2 = Curses::Window.new(1, Miscellaneous::screenWidth(), 1, 0)
        win3 = Curses::Window.new(Miscellaneous::screenHeight()-2, Miscellaneous::screenWidth(), 2, 0)

        win1.refresh
        win2.refresh
        win3.refresh

        win1_display_string = ""
        search_string       = nil # string or nil
        search_string_last_time_update = nil

        selected_objects    = []

        display_search_string = lambda {
            win1.setpos(0,0)
            win1.deleteln()
            win1 << ("-> " + (win1_display_string || ""))
            win1.refresh
        }

        display_searching_on = lambda {
            win2.setpos(0,0)
            win2.deleteln()
            win2 << "searching..."
            win2.refresh
        }
        display_searching_off = lambda {
            win2.setpos(0,0)
            win2.deleteln()
            win2.refresh
        }

        thread4 = Thread.new {
            loop {

                sleep 0.01

                next if search_string.nil?
                next if search_string_last_time_update.nil?
                next if (Time.new.to_f - search_string_last_time_update) < 1

                pattern = search_string
                search_string = nil

                display_searching_on.call()
                selected_objects = GenericObjectInterface::applyDateTimeOrderToObjects(NSDT1ExtendedDataLookups::selectNodesPerPattern_v2(pattern))

                win3.setpos(0,0)
                selected_objects.first(Miscellaneous::screenHeight()-3).each{|object|
                    win3.deleteln()
                    win3 << "#{NSDataType1::toString(object)}\n"
                }
                (win3.maxy - win3.cury).times {win3.deleteln()}
                win3.refresh

                display_searching_off.call()
                display_search_string.call()
            }
        }

        display_search_string.call()

        loop {

            char = win1.getch.to_s # Reads and return a character non blocking

            next if char.size == 0

            if char == '127' then
                # delete
                next if win1_display_string.length == 0
                win1_display_string = win1_display_string[0, win1_display_string.length-1]
                search_string = win1_display_string
                search_string_last_time_update = Time.new.to_f
                display_search_string.call()
                next
            end

            if char == '10' then
                # enter
                break
            end

            win1_display_string << char
            search_string = win1_display_string
            search_string_last_time_update = Time.new.to_f
            display_search_string.call()
        }

        Thread.kill(thread4)

        win1.close
        win2.close
        win3.close

        Curses::close_screen # this method restore our terminal's settings

        return (selected_objects || [])
    end

    # NSDT1ExtendedUserInterface::selectExistingType1InteractivelyOrNull()
    def self.selectExistingType1InteractivelyOrNull()
        nodes = NSDT1ExtendedUserInterface::interactiveSearch()
        return nil if nodes.empty?
        system("clear")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|node| NSDataType1::toString(node) })
    end

    # NSDT1ExtendedUserInterface::selectNodeSpecialWeaponsAndTactics()
    def self.selectNodeSpecialWeaponsAndTactics()
        KeyValueStore::destroy(nil, "d64d6e5e-9cc9-41b4-8c42-6062495ef546")
        NSDT1ExtendedUserInterface::nodeFocusAndReturnOrSelectExistingOrMakeNewNodeOrNullSandbox()
    end

    # NSDT1ExtendedUserInterface::nodeFocusAndReturnOrSelectExistingOrMakeNewNodeOrNullSandbox(focusnode = nil)
    def self.nodeFocusAndReturnOrSelectExistingOrMakeNewNodeOrNullSandbox(focusnode = nil)
        if focusnode then
            system("clear")
            puts "[selection sandbox] selected: #{NSDataType1::toString(focusnode)}"
            puts ""
            ops = [
                "select node out of sandbox", 
                "node landing",
                "reset sandbox",
                "return null from sandbox"
            ]
            op = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ops)
            if op.nil? then
                return NSDT1ExtendedUserInterface::nodeFocusAndReturnOrSelectExistingOrMakeNewNodeOrNullSandbox(focusnode)
            end
            if op == "select node out of sandbox" then
                return focusnode
            end
            if op == "node landing" then
                NSDataType1::landing(focusnode)
                selection = KeyValueStore::getOrNull(nil, "d64d6e5e-9cc9-41b4-8c42-6062495ef546")
                if selection then
                    node = JSON.parse(selection)
                    return NSDT1ExtendedUserInterface::nodeFocusAndReturnOrSelectExistingOrMakeNewNodeOrNullSandbox(node)
                else
                    return NSDT1ExtendedUserInterface::nodeFocusAndReturnOrSelectExistingOrMakeNewNodeOrNullSandbox(focusnode)
                end
            end
            if op == "reset sandbox" then
                return NSDT1ExtendedUserInterface::nodeFocusAndReturnOrSelectExistingOrMakeNewNodeOrNullSandbox()
            end
            if op == "return null from sandbox" then
                return nil
            end
        else
            system("clear")
            puts "You are in the selection sandbox. First, Going to try and make you select an existing node"
            LucilleCore::pressEnterToContinue()
            node = NSDT1ExtendedUserInterface::selectExistingType1InteractivelyOrNull()
            if node then
                return NSDT1ExtendedUserInterface::nodeFocusAndReturnOrSelectExistingOrMakeNewNodeOrNullSandbox(node)
            else
                system("clear")
                puts "[selection sandbox] no selection"
                puts ""
                ops = [
                    "make new node", 
                    "return null from sandbox"
                ]
                op = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ops)
                if op.nil? then
                    return NSDT1ExtendedUserInterface::nodeFocusAndReturnOrSelectExistingOrMakeNewNodeOrNullSandbox()
                end
                if op == "make new node" then
                    node = NSDataType1::issueNewNodeInteractivelyOrNull()
                    if node then
                        return NSDT1ExtendedUserInterface::nodeFocusAndReturnOrSelectExistingOrMakeNewNodeOrNullSandbox(node)
                    else
                        return NSDT1ExtendedUserInterface::nodeFocusAndReturnOrSelectExistingOrMakeNewNodeOrNullSandbox()
                    end
                end
                if op == "return null from sandbox" then
                    return nil
                end
            end
        end
    end

    # NSDT1ExtendedUserInterface::interactiveSearchAndExplore()
    def self.interactiveSearchAndExplore()
        nodes = NSDT1ExtendedUserInterface::interactiveSearch()
        return if nodes.empty?
        loop {
            nodes = nodes.select{|o| NSDataType1::getOrNull(o["uuid"]) } # In case a node has been deleted in the previous loop
            system("clear")
            node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node",  nodes, lambda{|node| NSDataType1::toString(node) })
            break if node.nil?
            NSDataType1::landing(node)
        }
    end
end
