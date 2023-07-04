
class NxPages

    # NxPages::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxPage", uuid)
        text = CommonUtils::editTextSynchronously("")
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "text", text)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxPages::interactivelyIssueNewAtParentOrNull(parent)
    def self.interactivelyIssueNewAtParentOrNull(parent)
        tx8 = Tx8s::make(parent["uuid"], 0)

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid
        DarkEnergy::init("NxPage", uuid)
        text = CommonUtils::editTextSynchronously("")
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "text", text)
        DarkEnergy::patch(uuid, "parent", tx8)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxPages::toString(item)
    def self.toString(item)
        "📃 #{item["description"]}"
    end

    # NxPages::toStringForMainListing(item)
    def self.toStringForMainListing(item)
        "📃 #{item["description"]}#{NxCores::coreSuffix(item)}"
    end

    # NxPages::toStringForCoreListing(item)
    def self.toStringForCoreListing(item)
        "📃 #{item["description"]}#{CoreData::itemToSuffixString(item)}"
    end

    # NxPages::access(page)
    def self.access(page)
        puts "accessing page '#{NxPages::toString(page)}' in synchronous edition mode"
        text = CommonUtils::editTextSynchronously(page["text"])
        return if text == page["text"]
        DarkEnergy::patch(page["uuid"], "text", text)
    end

    # NxPages::maintenance()
    def self.maintenance()
        # Ensuring consistency of parenting targets
        DarkEnergy::mikuType("NxPage").each{|project|
            next if project["parent"].nil?
            if DarkEnergy::itemOrNull(project["parent"]["uuid"]).nil? then
                DarkEnergy::patch(uuid, "parent", nil)
            end
        }

        # Move orphan pages to Infinity
        DarkEnergy::mikuType("NxPage").each{|project|
            next if project["parent"]
            parent = DarkEnergy::itemOrNull(NxCores::infinityuuid())
            project["parent"] = Tx8s::make(parent["uuid"], Tx8s::newFirstPositionAtThisParent(parent))
            DarkEnergy::commit(project)
        }
    end

    # NxPages::program2()
    def self.program2()
        loop {
            pages = DarkEnergy::mikuType("NxPage").sort_by{|item| item["description"] }
            page = LucilleCore::selectEntityFromListOfEntitiesOrNull("page", pages, lambda{|page| NxPages::toString(page) })
            return if page.nil?
            NxPages::access(page)
        }
    end
end
