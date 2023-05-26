
class NxThreads

    # NxThreads::interactivelyIssueNewOrNull(principal = nil)
    def self.interactivelyIssueNewOrNull(principal = nil)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        datetime = Time.new.utc.iso8601
        uuid = SecureRandom.uuid
        Solingen::init("NxThread", uuid)
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", datetime)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::getItemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxThreads::toString(item)
    def self.toString(item)
        suffix =
            if item["engine"] then
                " #{TxEngines::toString(item["engine"])}"
            else
                ""
            end
        "(thrd) #{item["description"].ljust(30)}#{suffix}"
    end

    # NxThreads::listingItems()
    def self.listingItems()
        Solingen::mikuTypeItems("NxThread")
            .sort_by{|item| item["unixtime"] }
    end

    # NxThreads::tasks(thread)
    def self.tasks(thread)
        Solingen::mikuTypeItems("NxTask")
            .select{|item| item["parentuuid"] == thread["uuid"] }
    end

    # NxThreads::runningThreads()
    def self.runningThreads()
        Solingen::mikuTypeItems("NxThread").select{|item| NxBalls::itemIsActive(item) }
    end

    # NxThreads::children(thread)
    def self.children(thread)
        [
            [
                Solingen::mikuTypeItems("NxBurner"),
                Solingen::mikuTypeItems("NxFire"),
                Solingen::mikuTypeItems("NxOndate"),
                Solingen::mikuTypeItems("Wave"),
            ]
                .flatten
                .select{|item| item["parentuuid"] == thread["uuid"] },

            Solingen::mikuTypeItems("NxTask")
                .select{|item| item["parentuuid"] == thread["uuid"] }
                .sort_by{|item| item["position"] }
        ]
            .flatten
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

            NxThreads::children(thread)
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
        if NxThreads::tasks(thread).size > 0 then
            puts "You cannot delete a thread that has elements in it"
            LucilleCore::pressEnterToContinue()
            return
        end
        Solingen::destroy(uuid)
    end

    # NxThreads::interactivelySelectThreadOrNull()
    def self.interactivelySelectThreadOrNull()
        threads = Solingen::mikuTypeItems("NxThread")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, lambda{|item| PolyFunctions::toString(item) })
    end

    # NxThreads::interactivelySelectThread()
    def self.interactivelySelectThread()
        loop {
            thread = NxThreads::interactivelySelectThreadOrNull()
            return thread if thread
        }
    end

    # NxThreads::interactivelyDecideCoordinates(mikuType) # [thread, position or null]
    def self.interactivelyDecideCoordinates(mikuType)
        thread = NxThreads::interactivelySelectThread()
        if mikuType == "NxTask" then
            position = NxThreads::decideNewPositionAtThread(thread)
            return [thread, position]
        else
            return [thread, nil]
        end
    end

    # NxThreads::coordinatesForVienna()
    def self.coordinatesForVienna()
        thread = Solingen::mikuTypeItems("NxThread").select{|thread| thread["description"] == "Vienna" }.first
        items = NxThreads::tasks(thread)
        position = (items.size > 0) ? (items.map{|item| item["position"]}.max + rand) : 1
        [thread, position]
    end

    # NxThreads::coordinatesForNxTasksBufferIn()
    def self.coordinatesForNxTasksBufferIn()
        thread = Solingen::mikuTypeItems("NxThread").select{|thread| thread["description"] == "NxTasks-BufferIn" }.first
        items = NxThreads::tasks(thread)
        position = (items.size > 0) ? (items.map{|item| item["position"]}.max + rand) : 1
        [thread, position]
    end

    # NxThreads::decideNewPositionAtThread(thread)
    def self.decideNewPositionAtThread(thread)
        items = NxThreads::tasks(thread)
        return 1 if items.size > 0
        items.sort_by{|item|
            puts "#{item["position"]} : #{item["description"]}"
        }
        LucilleCore::askQuestionAnswerAsString("position: ").to_f
    end
end
