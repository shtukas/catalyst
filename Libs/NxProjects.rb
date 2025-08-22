
class NxProjects

    # NxProjects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        payload = UxPayload::makeNewOrNull(uuid)
        position = NxProjects::lastPosition() + 1
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "position-1654", position)
        Items::setAttribute(uuid, "mikuType", "NxProject")
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxProjects::toString(item)
    def self.toString(item)
        "🦉 (-> #{"%7.3f" % item["position-1654"]}) #{item["description"]}"
    end

    # NxProjects::firstPosition()
    def self.firstPosition()
        ([0] + Items::mikuType("NxProject").map{|item| item["position-1654"] }).min
    end

    # NxProjects::lastPosition()
    def self.lastPosition()
        ([1] + Items::mikuType("NxProject").map{|item| item["position-1654"] }).max
    end

    # NxProjects::itemsInOrder()
    def self.itemsInOrder()
        Items::mikuType("NxProject").sort_by{|item| item["position-1654"] }
    end

    # NxProjects::listingItems()
    def self.listingItems()
        Items::mikuType("NxProject")
    end

    # NxProjects::position(item) -> [0, 1]
    def self.position(item)
        (2 + Math.atan(item["position-1654"])).to_f/10
    end

    # NxProjects::sort()
    def self.sort()
        items = NxProjects::itemsInOrder()
        selected, _ = LucilleCore::selectZeroOrMore("projects", [], items, lambda{|i| PolyFunctions::toString(i) })
        selected.reverse.each{|item|
            position = NxProjects::firstPosition() - 1
            Items::setAttribute(item["uuid"], "position-1654", position)
        }
    end

    # NxProjects::maintenance()
    def self.maintenance()
        # We ensure that projects have a parent that is a core
        Items::mikuType("NxProject").each{|project|
            next if Parenting::parentOrNull(project["uuid"])
            puts "relocate to new parent: #{PolyFunctions::toString(project)}"
            Operations::relocateToNewParent(project)
        }
    end
end
