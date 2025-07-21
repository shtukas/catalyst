
=begin
NxProject:
    - uuid             : String
    - mikuType         : "NxProject"
    - unixtime         : Float
    - datetime         : DateTime Iso 8601 UTC Zulu
    - description      : String
    - project-position : Float
    - commitment-today : NxCommitmentToday

NxCommitmentToday # commitment today 
{
    "date"               : Date,
    "time-left-in-hours" : Float
}
=end

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
        Items::init(uuid)
        payload = UxPayload::makeNewOrNull(uuid)
        Items::setAttribute(uuid, "mikuType", "NxProject")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "project-position", NxProjects::getNextPosition())
        Items::setAttribute(uuid, "commitment-date", nil)
        Items::setAttribute(uuid, "commitment-hours", nil)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Standard Items

    # NxProjects::icon(item)
    def self.icon(item)
        "🔺"
    end

    # NxProjects::toString(item)
    def self.toString(item)
        "#{NxProjects::icon(item)} #{item["description"]} (#{item["project-position"]})"
    end

    # ------------------
    # Ops

end
