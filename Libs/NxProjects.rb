
class NxProjects

    # NxProjects::interactivelyDecidePriority()
    def self.interactivelyDecidePriority()
        [
            "3: high priority (to be done today)",
            "2: to be worked on seriously (deadlined)",
            "1: medium priority",
            "0: low priority"
        ].each{ |line|
            puts line
        }
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
        Items::setAttribute(uuid, "payload-uuid-1141", UxPayload::interactivelyIssueNewGetReferenceOrNull())
        Items::setAttribute(uuid, "px21", NxProjects::interactivelyDecidePriority())
        Items::setAttribute(uuid, "mikuType", "NxProject")
        item = Items::itemOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # NxProjects::icon()
    def self.icon()
        "⛵️"
    end

    # Projects::timeCommitmentToString(timeCommitment)
    def self.timeCommitmentToString(timeCommitment)
        if timeCommitment["type"] == "day" then
            return "(day: #{timeCommitment["hours"]} hours)"
        end
        if timeCommitment["type"] == "week" then
            return "(week: #{timeCommitment["hours"]} hours)"
        end
        if timeCommitment["type"] == "presence" then
            return "(presence)"
        end
        ""
    end

    # NxProjects::listingPosition(item)
    def self.listingPosition(item)
        position = 1 + NxProjects::ratio(item)
    end

    # NxProjects::toString(item)
    def self.toString(item)
        ratio = NxProjects::ratio(item)
        prioritystring = "(priority: #{item["px21"]})".yellow
        ratiostring = "(ratio: #{ratio.round(3)})".yellow
        "#{NxProjects::icon()} #{item["description"]} #{prioritystring} #{ratiostring}"
    end

    # NxProjects::listingItems()
    def self.listingItems()
        [3, 2, 1, 0].each{|priority|
            items = Items::mikuType("NxProject")
                .select{|item| (item["px21"] || 0) => priority }
                .select{|item| FrontPage::isVisible(item) }
            return items if !items.empty?
        }
        []
    end

    # NxProjects::program()
    def self.program()
        loop {
            elements = Items::mikuType("NxProject")
                            .sort_by{|item| (item["px21"] || 0) - NxProjects::ratio(item) }
                            .reverse
            store = ItemStore.new()
            puts ""
            elements
                .each{|item|
                    store.register(item, FrontPage::canBeDefault(item))
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
