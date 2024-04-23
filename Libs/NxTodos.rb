
class NxTodos

    # NxTodos::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Cubes2::itemInit(uuid, "NxTodo")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # NxTodos::descriptionToTask1(uuid, description)
    def self.descriptionToTask1(uuid, description)
        Cubes2::itemInit(uuid, "NxTodo")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxTodos::icon(item)
    def self.icon(item)
        Catalyst::children(item).empty? ? "🔹" : "🔺"
    end

    # NxTodos::isOrphan(item)
    def self.isOrphan(item)
        item["parentuuid-0032"].nil? or Cubes2::itemOrNull(item["parentuuid-0032"]).nil?
    end

    # NxTodos::listingRatio(item)
    def self.listingRatio(item)
        hours = item["hours"] || 1
        [Bank2::recoveredAverageHoursPerDay(item["uuid"]), 0].max.to_f/(hours.to_f/7)
    end

    # NxTodos::performance(item)
    def self.performance(item)
        hours = item["hours"] || 1
        "(#{"%6.2f" % (100 * NxTodos::listingRatio(item))} %; #{"%5.2f" % hours} h/w)".yellow
    end

    # NxTodos::toString(item)
    def self.toString(item)
        "(#{"%7.3f" % (item["global-positioning"] || 0)}) #{NxTodos::icon(item)} #{item["description"]}"
    end

    # NxTodos::orphans()
    def self.orphans()
        Cubes2::mikuType("NxTodo")
            .select{|item| NxTodos::isOrphan(item) }
            .sort_by{|item| item["unixtime"] }
    end

    # NxTodos::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = NxTodos::orphans().sort_by{|item| NxTodos::listingRatio(item) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", items, lambda{|item| PolyFunctions::toString(item, "icon+performance+description") })
    end

    # NxTodos::muiItems()
    def self.muiItems()
        NxTodos::orphans()
            .sort_by{|item| NxTodos::listingRatio(item) }
            .select{|item| NxTodos::listingRatio(item) < 1 }
    end
end
