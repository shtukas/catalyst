
class NxThreads

    # NxThreads::interactivelyIssueNewOrNull(principal = nil)
    def self.interactivelyIssueNewOrNull(principal = nil)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        datetime = Time.new.utc.iso8601
        principal = NxPrincipals::interactivelySelectOnePrincipal()
        active = LucilleCore::askQuestionAnswerAsBoolean("active ?: ")
        uuid = SecureRandom.uuid
        Solingen::init("NxThread", uuid)
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", datetime)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "parentuuid", principal["uuid"])
        Solingen::setAttribute2(uuid, "active", active)
        Solingen::getItemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxThreads::toString(item)
    def self.toString(item)
        parent = Solingen::getItemOrNull(item["parentuuid"])
        "(thrd) #{item["description"]} (#{parent["description"]})"
    end

    # NxThreads::listingItems()
    def self.listingItems()
        Solingen::mikuTypeItems("NxThread")
            .sort_by{|item| item["unixtime"] }
    end

    # NxThreads::items(thread)
    def self.items(thread)
        Solingen::mikuTypeItems("NxTask")
            .select{|item| item["parentuuid"] == thread["uuid"] }
    end

    # NxThreads::runningThreads()
    def self.runningThreads()
        Solingen::mikuTypeItems("NxThread").select{|item| NxBalls::itemIsActive(item) }
    end

    # ------------------
    # Ops

    # NxThreads::program(thread)
    def self.program(thread)
        loop {

            thread = Solingen::getItemOrNull(thread["uuid"])
            return if thread.nil?

            system("clear")

            puts ""

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            store = ItemStore.new()

            store.register(thread, false)
            spacecontrol.putsline(Listing::itemToListingLine(store: store, item: thread))
            spacecontrol.putsline ""

            NxThreads::items(thread)
                .sort_by{|item| item["position"] }
                .each{|item|
                    store.register(item, Listing::canBeDefault(item)) 
                    status = spacecontrol.putsline(Listing::itemToListingLine(store: store, item: item))
                    break if !status
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end

    # NxThreads::access(thread)
    def self.access(thread)
        NxThreads::program(thread)
    end

    # NxThreads::destroy(uuid)
    def self.destroy(uuid)
        thread = Solingen::getItemOrNull(uuid)
        return if thread.nil?
        if NxThreads::items(thread).size > 0 then
            puts "You cannot delete a thread that has elements in it"
            LucilleCore::pressEnterToContinue()
            return
        end
        Solingen::destroy(uuid)
    end

    # NxThreads::interactivelySelectThreadAtBoardOrNull(board)
    def self.interactivelySelectThreadAtBoardOrNull(board)
        threads = Solingen::mikuTypeItems("NxThread")
                    .select{|item| item["parentuuid"] == board["uuid"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, lambda{|item| PolyFunctions::toString(item) })
    end

    # NxThreads::architectThreadAtBoard(board)
    def self.architectThreadAtBoard(board)
        if NxPrincipals::threads(board).empty? then
            loop {
                thread = NxThreads::interactivelyIssueNewOrNull(board)
                return thread if thread
            }
        end
        thread = NxThreads::interactivelySelectThreadAtBoardOrNull(board)
        return thread if thread
        puts "You did not select a thread. Select follow up action"
        action = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("action", ["select one of the existing threads", "make a new thread"])
        if action == "select one of the existing threads" then
            loop {
                thread = NxThreads::interactivelySelectThreadAtBoardOrNull(board)
                return thread if thread
            }
        end
        if action == "make a new thread" then
            loop {
                thread = NxThreads::interactivelyIssueNewOrNull(board)
                return thread if thread
            }
        end
    end

    # NxThreads::decideNewPositionAtThread(thread)
    def self.decideNewPositionAtThread(thread)
        items = NxThreads::items(thread)
        return 1 if items.size > 0
        items.sort_by{|item|
            puts "#{item["position"]} : #{item["description"]}"
        }
        LucilleCore::askQuestionAnswerAsString("position: ").to_f
    end
end
