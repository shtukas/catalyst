
class NxProjects

    # NxProjects::interactivelyIssueNewProjectOrNull()
    def self.interactivelyIssueNewProjectOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "payload-uuid-1141", UxPayloads::interactivelyIssueNewGetReferenceOrNull())
        Items::setAttribute(uuid, "lx56", NxProjects::highestOrdinal() + 1)
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
        rts = "(rt: #{BankDerivedData::recoveredAverageHoursPerDay(item["uuid"]).round(2)})".yellow
        "#{NxProjects::icon()} #{item["description"]} #{rts}"
    end

    # NxProjects::computeListingPosition(item)
    def self.computeListingPosition(item)
        0.2 + 0.001*item["lx56"] + 0.8 * BankDerivedData::recoveredAverageHoursPerDay("projects-25806839").to_f/5
    end

    # NxProjects::interactivelySelectProjectOrNull()
    def self.interactivelySelectProjectOrNull()
        items = Items::mikuType("NxProject").sort_by{|item| item["lx56"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", items, lambda{|item| PolyFunctions::toString(item) })
    end

    # NxProjects::lowestOrdinal()
    def self.lowestOrdinal()
        ([0] + Items::mikuType("NxProject").map{|item| item["lx56"] }).min
    end

    # NxProjects::highestOrdinal()
    def self.highestOrdinal()
        ([0] + Items::mikuType("NxProject").map{|item| item["lx56"] }).max
    end

    # -------------------------------------
    # Ops

    # NxProjects::alignLx56()
    def self.alignLx56()
        Items::mikuType("NxProject")
            .sort_by{|item| item["lx56"]}
            .each_with_index{|item, indx|
                Items::setAttribute(item["uuid"], "lx56", indx)
            }
    end

    # NxProjects::program()
    def self.program()
        loop {
            elements = Items::mikuType("NxProject").sort_by{|item| item["lx56"]}
            store = ItemStore.new()
            puts ""
            elements
                .each{|item|
                    store.register(item, true)
                    puts FrontPage::toString2(store, item)
                }
            puts ""
            puts "sort"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""
            if input == "sort" then
                projects, _ = LucilleCore::selectZeroOrMore("projects", [], Items::mikuType("NxProject"), lambda{|item| PolyFunctions::toString(item) })
                projects.reverse.each{|project|
                    Items::setAttribute(project["uuid"], "lx56", NxProjects::lowestOrdinal() - 1)
                }
                NxProjects::alignLx56()
                Items::mikuType("NxProject").each{|item|
                    Items::setAttribute(item["uuid"], "nx41", nil)
                }
                next
            end
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

end
