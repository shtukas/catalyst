
class NxSublines

    # NxSublines::issueNew(line, parentuuid, px36)
    def self.issueNew(line, parentuuid, px36)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", line)
        Items::setAttribute(uuid, "parentuuid", parentuuid)
        Items::setAttribute(uuid, "px36", px36)
        Items::setAttribute(uuid, "mikuType", "NxSubline")
        item = Items::objectOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # NxSublines::toString(item)
    def self.toString(item)
        "-> #{item["description"]}"
    end

    # NxSublines::itemsForParentInOrder(parentuuid)
    def self.itemsForParentInOrder(parentuuid)
        Items::mikuType("NxSubline")
            .select{|item| item["parentuuid"] == parentuuid }
            .sort_by{|item| item["px36"] }
    end

    # NxSublines::firstPositionInParent(parentuuid)
    def self.firstPositionInParent(parentuuid)
        px = Items::mikuType("NxSubline")
            .select{|item| item["parentuuid"] == parentuuid }
            .map{|item| item["px36"] }
        ([0] + px).min
    end

    # NxSublines::lastPositionInParent(parentuuid)
    def self.lastPositionInParent(parentuuid)
        px = Items::mikuType("NxSubline")
            .select{|item| item["parentuuid"] == parentuuid }
            .map{|item| item["px36"] }
        ([0] + px).max
    end

    # NxSublines::insert(parent)
    def self.insert(parent)
        Operations::interactivelyGetLinesUsingTextEditor().each{|line|
            NxSublines::issueNew(line, parent["uuid"], NxSublines::lastPositionInParent(parent["uuid"]) + 1)
        }
    end

    # NxSublines::dive(parent)
    def self.dive(parent)
        loop {
            elements = NxSublines::itemsForParentInOrder(parent["uuid"])
            store = ItemStore.new()
            puts ""
            elements
                .each{|item|
                    store.register(item, FrontPage::canBeDefault(item))
                    puts FrontPage::toString2(store, item)
                    FrontPage::additionalLines(item).each{|line|
                        puts " " * FrontPage::additionalLinesShift(item) + line
                    }
                }
            puts ""
            puts "insert (new subline) | sort"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "insert" then
                line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
                next if line == ""
                NxSublines::issueNew(line, parent["uuid"], NxSublines::lastPositionInParent(parent["uuid"]) + 1)
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], elements, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|item|
                    Items::setAttribute(item["uuid"], "px36", NxSublines::firstPositionInParent(parent["uuid"]) - 1)
                }
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
