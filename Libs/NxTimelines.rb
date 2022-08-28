
# encoding: UTF-8

class NxTimelines

    # ----------------------------------------------------------------------
    # IO

    # NxTimelines::items()
    def self.items()
        TheIndex::mikuTypeToItems("NxTimeline")
    end

    # NxTimelines::destroy(uuid)
    def self.destroy(uuid)
        DxF1::deleteObjectLogically(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxTimelines::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        DxF1::setAttribute2(uuid, "uuid",        uuid)
        DxF1::setAttribute2(uuid, "mikuType",    "NxTimeline")
        DxF1::setAttribute2(uuid, "unixtime",    unixtime)
        DxF1::setAttribute2(uuid, "datetime",    datetime)
        DxF1::setAttribute2(uuid, "description", description)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: a6cc9094-7100-4aa3-8ebc-1fec0669733e) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxTimelines::toString(item)
    def self.toString(item)
        "(timeline) #{item["description"]}"
    end

    # NxTimelines::landing(item, isSearchAndSelect) # nil or item (if command: result)
    def self.landing(item, isSearchAndSelect)
        loop {

            return nil if item.nil?

            uuid = item["uuid"]

            item = TheIndex::getItemOrNull(uuid)

            return nil if item.nil?

            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            makeFirstLine = lambda{|item|
                if item["mikuType"] == "NxPerson" then
                    return "(#{item["mikuType"].yellow}) #{item["name"]}"
                end
                "(#{item["mikuType"].yellow}) #{item["description"]}"
            }

            puts makeFirstLine.call(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow

            linkeds  = NetworkLinks::linkedEntities(uuid)

            puts "Linked entities: #{linkeds.size} items".yellow

            if linkeds.size <= 200 then
                linkeds
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .first(200)
                    .each{|entity|
                        indx = store.register(entity, false)
                        puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", entity)}"
                    }
            else
                puts "(... many items, use `navigation` ...)"
            end

            puts "commands: iam | <n> | description | datetime | line | text | json | link | unlink | network-migration | navigation | upload | return (within search) | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                result = Landing::landing(entity, isSearchAndSelect)
                if isSearchAndSelect and result then
                    return result
                end
            end

            if Interpreting::match("description", command) then
                if item["mikuType"] == "NxPerson" then
                    name1 = CommonUtils::editTextSynchronously(item["name"]).strip
                    next if name1 == ""
                    DxF1::setAttribute2(item["uuid"], "name", name1)
                else
                    description = CommonUtils::editTextSynchronously(item["description"]).strip
                    next if description == ""
                    DxF1::setAttribute2(item["uuid"], "description", description)
                end
                next
            end

            if Interpreting::match("datetime", command) then
                datetime = CommonUtils::editTextSynchronously(item["datetime"]).strip
                next if !CommonUtils::isDateTime_UTC_ISO8601(datetime)
                DxF1::setAttribute2(item["uuid"], "datetime", datetime)
            end

            if Interpreting::match("iam", command) then
                puts "TODO"
                exit
            end

            if Interpreting::match("line", command) then
                l1 = NxLines::interactivelyIssueNewLineOrNull()
                next if l1.nil?
                puts JSON.pretty_generate(l1)
                NetworkLinks::link(item["uuid"], l1["uuid"])
                next
            end

            if Interpreting::match("text", command) then
                i2 = DxText::interactivelyIssueNew()
                puts JSON.pretty_generate(i2)
                NetworkLinks::link(item["uuid"], i2["uuid"])
                next
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("link", command) then
                Landing::link(item)
            end

            if Interpreting::match("navigation", command) then
                LinkedNavigation::navigate(item)
            end

            if Interpreting::match("unlink", command) then
                Landing::removeConnected(item)
            end

            if Interpreting::match("network-migration", command) then
                NetworkLinks::networkMigration(item)
            end

            if Interpreting::match("upload", command) then
                Upload::interactivelyUploadToItem(item)
            end

            if Interpreting::match("return", command) then
                return item
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy item ? : ") then
                    DxF1::deleteObjectLogically(item["uuid"])
                    break
                end
            end
        }

        nil
    end
end
