
class NxEffects

    # NxEffects::issueWithInit(uuid, description, behaviour, coredataReference)
    def self.issueWithInit(uuid, description, behaviour, coredataReference)
        DataCenter::itemInit(uuid, "NxEffect")
        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "behaviour", behaviour)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::setAttribute(uuid, "field11", coredataReference)
        DataCenter::itemOrNull(uuid)
    end

    # NxEffects::issueWithoutInit(uuid, description, behaviour, coredataReference)
    def self.issueWithoutInit(uuid, description, behaviour, coredataReference)
        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "behaviour", behaviour)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::setAttribute(uuid, "field11", coredataReference)
        DataCenter::itemOrNull(uuid)
    end

    # NxEffects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        NxEffects::interactivelyIssueNewOrNull2(uuid)
    end

    # NxEffects::interactivelyIssueNewOrNull2(uuid)
    def self.interactivelyIssueNewOrNull2(uuid)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        behaviour = TxBehaviours::interactivelyMakeNewOnNull()
        return if behaviour.nil?
        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
        NxEffects::issueWithInit(uuid, description, behaviour, coredataref)
    end

    # ------------------
    # Data

    # NxEffects::toString(item)
    def self.toString(item)
        if item["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            count = LucilleCore::locationsAtFolder("#{Config::userHomeDirectory()}/Galaxy/DataHub/Buffer-In").select{|location| !File.basename(location).start_with?(".") }
            if count then
                return "#{TxBehaviours::toIcon(item["behaviour"])} #{TxBehaviours::toString1(item["behaviour"])} special circusmtances: DataHub/Buffer-In#{TxBehaviours::toString2(item["behaviour"])}"
            end
        end

        "#{TxBehaviours::toIcon(item["behaviour"])} #{TxBehaviours::toString1(item["behaviour"])} #{item["description"]}#{TxBehaviours::toString2(item["behaviour"])}#{CoreDataRefStrings::itemToSuffixString(item).red}"
    end

    # NxEffects::listingItems(selector, order)
    def self.listingItems(selector, order)
        DataCenter::mikuType("NxEffect")
            .select{|item| selector.call(item) }
            .select{|item| TxBehaviours::shouldDisplayInListing(item["behaviour"]) }
            .sort_by{|item| order.call(item) }
    end

    # NxEffects::listingItemsTail()
    def self.listingItemsTail()
        DataCenter::mikuType("NxEffect")
            .select{|item| TxBehaviours::shouldDisplayInListing(item["behaviour"]) }
    end

    # NxEffects::stack(effect)
    def self.stack(effect)
        if effect["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            return DataCenter::mikuType("NxTask")
                    .select{|item| item["stackuuid"].nil? or DataCenter::itemOrNull(item["stackuuid"]).nil? }
        end
        DataCenter::mikuType("NxTask")
            .select{|item| item["stackuuid"] == effect["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxEffects::interactivelySelectOneOrNull(selector)
    def self.interactivelySelectOneOrNull(selector)
        effects = DataCenter::mikuType("NxEffect")
                    .select{|item| selector.call(item) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("effect", effects, lambda{|item| NxEffects::toString(item) })
    end

    # NxEffects::selectZeroOrMore(selector)
    def self.selectZeroOrMore(selector)
        effects = DataCenter::mikuType("NxEffect")
                    .select{|item| selector.call(item) }
        selected, _ = LucilleCore::selectZeroOrMore("effect", [], effects, lambda{|item| NxEffects::toString(item) })
        selected
    end

    # NxEffects::interactivelySelectShipAndAddTo(item)
    def self.interactivelySelectShipAndAddTo(item)
        selector = lambda{|item| item["behaviour"]["type"] == "ship" }
        ship = NxEffects::interactivelySelectOneOrNull(selector)
        return if ship.nil?
        DataCenter::setAttribute(item["uuid"], "stackuuid", ship["uuid"])
    end

    # NxEffects::selectSubsetAndMoveToSelectedShip(items, selector)
    def self.selectSubsetAndMoveToSelectedShip(items, selector)
        selected, _ = LucilleCore::selectZeroOrMore("selection", [], items, lambda{|item| PolyFunctions::toString(item) })
        return if selected.size == 0
        effect = NxEffects::interactivelySelectOneOrNull(lambda{|item| item["behaviour"]["type"] == "ship" })
        return if effect.nil?
        selected.each{|item|
            DataCenter::setAttribute(item["uuid"], "stackuuid", effect["uuid"])
        }
    end

    # NxEffects::topPosition(effect)
    def self.topPosition(effect)
        ([0] + NxEffects::stack(effect).map{|task| task["global-positioning"] || 0 }).min
    end

    # ------------------
    # Ops

    # NxEffects::access(item)
    def self.access(item)
        if item["field11"] then
            answer = LucilleCore::askQuestionAnswerAsBoolean("Would you like to acess the field11 ? ", true)
            if answer then
                CoreDataRefStrings::accessAndMaybeEdit(item["uuid"], item["field11"])
            end
        end
        NxEffects::program1(item)
    end

    # NxEffects::natural(item)
    def self.natural(item)
        NxBalls::start(item)
        if item["field11"] then
            CoreDataRefStrings::accessAndMaybeEdit(item["uuid"], item["field11"])
        end
        if item["behaviour"]["type"] == "ondate" then
            if NxEffects::stack(item).size == 0 then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{NxEffects::toString(item).green}' ? ", true) then
                    DataCenter::destroy(item["uuid"])
                end
            else
                NxEffects::program1(effect)
            end
        end
        if item["behaviour"]["type"] == "ship" then
            if NxEffects::stack(item).size > 0 then
                NxEffects::program1(item)
            end
        end
        if item["behaviour"]["type"] == "sticky" then
            if LucilleCore::askQuestionAnswerAsBoolean("push to tomorrow: '#{NxEffects::toString(item).green}' ? ", true) then
                DoNotShowUntil::setUnixtime(item["uuid"], CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()))
            end
        end
        NxBalls::stop(item)
    end

    # NxEffects::pile(effect)
    def self.pile(effect)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text
            .lines
            .map{|line| line.strip }
            .reverse
            .each{|line|
                task = NxTasks::descriptionToTask1(SecureRandom.hex, line)
                puts JSON.pretty_generate(task)
                DataCenter::setAttribute(task["uuid"], "stackuuid", effect["uuid"])
                DataCenter::setAttribute(task["uuid"], "global-positioning", NxEffects::topPosition(effect) - 1)
            }
    end

    # NxEffects::program1(effect)
    def self.program1(effect)
        loop {

            effect = DataCenter::itemOrNull(effect["uuid"])
            return if effect.nil?

            system("clear")

            store = ItemStore.new()

            puts  ""
            store.register(effect, false)
            puts  Listing::toString2(store, effect)
            puts  ""

            Prefix::prefix(NxEffects::stack(effect))
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::toString2(store, item)
                }

            puts ""
            puts "task | top | pile | sort | move"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                DataCenter::setAttribute(task["uuid"], "stackuuid", effect["uuid"])
                next
            end

            if input == "top" then
                line = LucilleCore::askQuestionAnswerAsString("description: ")
                next if line == ""
                task = NxTasks::descriptionToTask1(SecureRandom.hex, line)
                puts JSON.pretty_generate(task)
                DataCenter::setAttribute(task["uuid"], "stackuuid", effect["uuid"])
                DataCenter::setAttribute(task["uuid"], "global-positioning", NxEffects::topPosition(effect) - 1)
                next
            end

            if input == "pile" then
                NxEffects::pile(effect)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("item", [], NxEffects::stack(effect), lambda{|item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    DataCenter::setAttribute(item["uuid"], "global-positioning", NxEffects::topPosition(effect) - 1)
                }
                next
            end

            if input == "move" then
                NxEffects::selectSubsetAndMoveToSelectedShip(NxEffects::stack(effect), lambda{|item| item["behaviour"]["type"] == "effect" })
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxEffects::program2(effects)
    def self.program2(effects)
        loop {

            effects = effects.map{|item| DataCenter::itemOrNull(item["uuid"]) }.compact
            return if effects.empty?

            system("clear")

            store = ItemStore.new()

            puts  ""

            effects
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::toString2(store, item)
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input.start_with?("..") then
                indx = input[2, 9].strip.to_i
                item = store.get(indx)
                next if item.nil?
                NxEffects::program1(item)
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxEffects::program(selector, order)
    def self.program(selector, order)
        effects = DataCenter::mikuType("NxEffect")
                    .select{|item| selector.call(item) }
                    .sort_by{|item| order.call(item) }
        NxEffects::program2(effects)
    end

    # NxEffects::done(item)
    def self.done(item)
        if item["behaviour"]["type"] == "ondate" and NxEffects::stack(item).size == 0 then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{NxEffects::toString(item).green}' ? ", true) then
                DataCenter::destroy(item["uuid"])
            end
            return
        end
        if item["behaviour"]["type"] == "ondate" and NxEffects::stack(item).size > 0 then
            puts "You cannot done a NxEffect ondate with a non empty stack"
            LucilleCore::pressEnterToContinue()
            return
        end
        if item["behaviour"]["type"] == "ship" then
            return
        end
        if item["behaviour"]["type"] == "sticky" then
            DoNotShowUntil::setUnixtime(item["uuid"], CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()))
            return
        end
        raise "(error: 8e77b5e6-43e7-49ee-a1ac-d76a8c74300d) item: #{item}"
    end
end
