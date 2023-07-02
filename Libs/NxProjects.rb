
class NxProjects

    # NxProjects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxProject", uuid)
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxProjects::toString(item)
    def self.toString(item)
        "⛵️ #{item["description"]}#{CoreData::itemToSuffixString(item)}"
    end

    # NxProjects::projectManagerId()
    def self.projectManagerId()
        "17d908fc-1c65-4c04-8e38-4dc20c8a4ffa"
    end

    # NxProjects::listingItems()
    def self.listingItems()
        # We give two hours per day to projects.
        return [] if Bank::recoveredAverageHoursPerDay(NxProjects::projectManagerId()) >= 2
        projects = DarkEnergy::mikuType("NxProject")
        return [] if projects.empty?
        [projects.sort_by{|project| Bank::recoveredAverageHoursPerDay(project["uuid"]) }.first]
    end
end