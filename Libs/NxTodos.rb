
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
        "🔺"
    end

    # NxTodos::toString(item, context = nil)
    def self.toString(item, context = nil)
        if context == "listing" then
            return "#{NxTodos::icon(item)} #{item["description"]}"
        end
        "(#{"%7.3f" % (item["global-positioning"] || 0)}) #{NxTodos::icon(item)} #{item["description"]}"
    end

    # ------------------
    # Ops

    # NxTodos::access(item)
    def self.access(item)
        TxPayload::access(item)
    end

    # NxTodos::access(item)
    def self.natural(item)
        NxTodos::access(item)
    end

    # NxTodos::done(item)
    def self.done(item)
        if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
            Cubes2::destroy(item["uuid"])
        end
    end

    # NxTodos::maintenance()
    def self.maintenance()
        Cubes2::mikuType("NxTodo")
            .select{|item| item["parentuuid-0032"] }
            .select{|item| Cubes2::itemOrNull(item["parentuuid-0032"]).nil? }
            .each{|item|
                Cubes2::setAttribute(item["uuid"], "parentuuid-0032", "c1ec1949-5e0d-44ae-acb2-36429e9146c0") # Misc Timecore
            }
    end

    # NxTodos::properlyPositionNewlyCreatedTodo(item)
    def self.properlyPositionNewlyCreatedTodo(item)
        loop {
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["set parent", "in orbital"])
            next if option.nil?
            if option == "set parent" then
                parent = Catalyst::interactivelySelectNodeOrNull()
                next if parent.nil?
                Cubes2::setAttribute(item["uuid"], "parentuuid-0032", parent["uuid"])
                return
            end
            if option == "in orbital" then
                orbital = NxOrbitals::interactivelySelectOneOrNull()
                next if orbital.nil?
                Cubes2::setAttribute(item["uuid"], "parentuuid-0032", orbital["uuid"])
                return
            end
        }
        Catalyst::interactivelySetDonations(item)
    end
end
