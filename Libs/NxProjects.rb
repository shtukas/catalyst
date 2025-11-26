
class NxProjects

    # NxProjects::printLevelDescriptions()
    def self.printLevelDescriptions()
        [
            "3: high priority (to be done today)",
            "2: to be worked on seriously (deadlined)",
            "1: medium priority",
            "0: low priority"
        ].each{ |line|
            puts line
        }
    end

    # NxProjects::interactivelyDecidePriority()
    def self.interactivelyDecidePriority()
        NxProjects::printLevelDescriptions()
        LucilleCore::askQuestionAnswerAsString("priority ? : ").to_i
    end

    # NxProjects::interactivelyIssueNewProjectOrNull()
    def self.interactivelyIssueNewProjectOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "payload-uuid-1141", UxPayloads::interactivelyIssueNewGetReferenceOrNull())
        Items::setAttribute(uuid, "px21", NxProjects::interactivelyDecidePriority())
        Items::setAttribute(uuid, "mikuType", "NxProject")
        item = Items::objectOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # NxProjects::icon()
    def self.icon()
        "⛵️"
    end

    # NxProjects::toString(item)
    def self.toString(item)
        prioritystring = "[#{item["px21"]}]".yellow
        rts = "(rt: #{BankDerivedData::recoveredAverageHoursPerDay(item["uuid"]).round(2)})".yellow
        "#{NxProjects::icon()} #{prioritystring} #{item["description"]} #{rts}"
    end

    # NxProjects::computeListingPosition(item)
    def self.computeListingPosition(item)
        basePositions = {
            3 => 0.2,
            2 => 0.3,
            1 => 0.5,
            0 => 0.8
        }
        hours = BankDerivedData::recoveredAverageHoursPerDay(item["uuid"])
        basePosition = basePositions[item["px21"]]
        basePosition + hours.to_f/2
    end

    # NxProjects::interactivelySelectProjectOrNull()
    def self.interactivelySelectProjectOrNull()
        items = Items::mikuType("NxProject").sort_by{|item| item["px21"] }.reverse
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", items, lambda{|item| PolyFunctions::toString(item) })
    end

    # -------------------------------------
    # Ops

    # NxProjects::program()
    def self.program()
        loop {
            elements = Items::mikuType("NxProject")
                            .sort_by{|item| NxProjects::computeListingPosition(item) }
            store = ItemStore.new()
            puts ""
            NxProjects::printLevelDescriptions()
            elements
                .each{|item|
                    store.register(item, true)
                    puts FrontPage::toString2(store, item)
                }
            puts ""
            puts "project management"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""
            if input == "project management" then
                priority = NxProjects::interactivelyDecidePriority()
                projects, _ = LucilleCore::selectZeroOrMore("projects", [], Items::mikuType("NxProject"), lambda{|item| PolyFunctions::toString(item) })
                projects.each{|project|
                    Items::setAttribute(project["uuid"], "px21", priority)
                }
                next
            end
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

end
