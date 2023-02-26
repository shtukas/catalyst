
class NxProjects

    # NxProjects::items()
    def self.items()
        N3Objects::getMikuType("NxProject")
    end

    # NxProjects::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxProjects::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # NxProjects::interactivelyIssueNullOrNull()
    def self.interactivelyIssueNullOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxProject",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "active"      => false
        }
        puts JSON.pretty_generate(item)
        NxProjects::commit(item)
        item
    end

    # NxProjects::toString(item)
    def self.toString(item)
        "(project) #{item["description"]}"
    end

    # NxProjects::listingItems()
    def self.listingItems()
        items = NxProjects::items()
        return [] if items.empty?
        return[items.first] if items.size == 1
        if items.select{|item| item["active"] }.size == 0 then
            puts "> We have no active NxProjects. Let's activate one"
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("project", items, lambda{|item| NxProjects::toString(item) })
            return [] if item.nil?
            item["active"] = true
            NxProjects::commit(item)
            return [item]
        end
        if items.select{|item| item["active"] }.size >= 2 then
            puts "> We have more than one active project."
            puts "> resetting all projects."
            items.each{|item|
                item["active"] = false
                NxProjects::commit(item)
            }
            puts "> We have no active NxProjects. Let's activate one"
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("project", items, lambda{|item| NxProjects::toString(item) })
            return [] if item.nil?
            item["active"] = true
            NxProjects::commit(item)
            return [item]
        end
        items.select{|item| item["active"] } # there should only be one
    end

    # NxProjects::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end