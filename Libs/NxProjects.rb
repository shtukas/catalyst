
class NxProjects

    # NxProjects::interactivelyDecideProjectPosition()
    def self.interactivelyDecideProjectPosition()
        projects = Index1::mikuTypeItems("NxProject")
        projects = projects.sort_by{|item| item["project-position"] }
        puts "project:"
        projects.each{|project|
            puts "(#{project["project-position"]}) #{item["description"]}"
        }
        LucilleCore::askQuestionAnswerAsString("position: ").to_f
    end

    # NxProjects::getNextPosition()
    def self.getNextPosition()
        ([0] + Index1::mikuTypeItems("NxProject").map{|project| project["project-position"] }).max + 1
    end

    # NxProjects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        commitment = LucilleCore::askQuestionAnswerAsString("hours today (default to zero): ")
        if commitment != "" then
            commitment = commitment.to_f
        else
            commitment = 0
        end
        Items::init(uuid)
        payload = UxPayload::makeNewOrNull(uuid)
        Items::setAttribute(uuid, "mikuType", "NxProject")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "project-position", NxProjects::getNextPosition())
        Items::setAttribute(uuid, "commitment-date", CommonUtils::today())
        Items::setAttribute(uuid, "commitment-hours", commitment)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxProjects::icon(item)
    def self.icon(item)
        "🔺"
    end

    # NxProjects::toString(item)
    def self.toString(item)
        "#{NxProjects::icon(item)} #{item["description"]} (#{item["project-position"]})"
    end

    # NxProjects::isStillUpToday(item)
    def self.isStillUpToday(item)
        b1 = (item["commitment-date"] == CommonUtils::today())
        b2 = (Bank1::getValueAtDate(item["uuid"], CommonUtils::today()) < item["commitment-hours"]*3600)
        b1 and b2
    end

    # NxProjects::projectsInOrder()
    def self.projectsInOrder()
        Index1::mikuTypeItems("NxProject")
            .sort_by{|item| item["project-position"] }
    end

    # NxProjects::listingItems()
    def self.listingItems()
        Index1::mikuTypeItems("NxProject")
            .select{|item| NxProjects::isStillUpToday(item) }
    end

    # NxProjects::allSetForToday()
    def self.allSetForToday()
        Index1::mikuTypeItems("NxProject").all?{|item| item["commitment-date"] == CommonUtils::today() }
    end

    # ------------------
    # Ops

    # NxProjects::interativelyDecideTodayProjectsCommitments()
    def self.interativelyDecideTodayProjectsCommitments()
        puts "Select projects you want to do today"
        projects = Index1::mikuTypeItems("NxProject").sort_by{|item| item["project-position"] }
        projects.each{|item| Index0::removeEntry(item["uuid"]) }
        selected, unselected = LucilleCore::selectZeroOrMore("", [], projects, lambda { |item| PolyFunctions::toString(item) })
        selected.each{|item|
            hours = LucilleCore::askQuestionAnswerAsString("commitment for '#{PolyFunctions::toString(item).green}' in hours: ").to_f
            Items::setAttribute(item["uuid"], "commitment-date", CommonUtils::today())
            Items::setAttribute(item["uuid"], "commitment-hours", hours)
            item = Items::itemOrNull(item["uuid"])
            Index0::ensureThatItemIsListedIfListable(item)
        }
        unselected.each{|item|
            Items::setAttribute(item["uuid"], "commitment-date", CommonUtils::today())
            Items::setAttribute(item["uuid"], "commitment-hours", 0)
        }
    end
end
