
# encoding: UTF-8

class TopLevel

    # ----------------------------------------------------------------------
    # Objects Management

    # TopLevel::items()
    def self.items()
        Fx256WithCache::mikuTypeToItems("TopLevel")
    end

    # TopLevel::interactivelyIssueNew()
    def self.interactivelyIssueNew()
        uuid = SecureRandom.uuid
        text = CommonUtils::editTextSynchronously("")
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        Fx18Attributes::setJsonEncoded(uuid, "uuid", uuid)
        Fx18Attributes::setJsonEncoded(uuid, "mikuType", "TopLevel")
        Fx18Attributes::setJsonEncoded(uuid, "unixtime", unixtime)
        Fx18Attributes::setJsonEncoded(uuid, "datetime", datetime)
        Fx18Attributes::setJsonEncoded(uuid, "text", text)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        Fx256::broadcastObjectEvents(uuid)
        item = Fx256::getProtoItemOrNull(uuid)
        if item.nil? then
            raise "(error: d794e690-2b62-46a1-822b-c8f60d7b4075) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # TopLevel::getFirstLineOrNull(item)
    def self.getFirstLineOrNull(item)
        text = item["text"]
        return nil if text.nil?
        return nil if text == ""
        text.lines.first.strip
    end

    # TopLevel::toString(item)
    def self.toString(item)
        firstline = TopLevel::getFirstLineOrNull(item)
        return "(toplevel) (no text)" if firstline.nil?
        "(toplevel) #{firstline}"
    end

    # TopLevel::items()
    def self.items()
        Fx256WithCache::mikuTypeToItems("TopLevel")
    end

    # ----------------------------------------------------------------------
    # Operations

    # TopLevel::landing(uuid)
    def self.landing(uuid)
        loop {
            system("clear")
            item = Fx256::getAliveProtoItemOrNull(uuid)
            puts TopLevel::toString(item)
            operations = [
                "access/edit",
                "destroy"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "access/edit" then
                text = item["text"]
                text = CommonUtils::editTextSynchronously(text)
                Fx18Attributes::setJsonEncoded(uuid, "text", text)
            end
            if operation == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("confirm destroy of '#{TopLevel::toString(item).green}' ? ") then
                    Fx256::deleteObjectLogically(uuid)
                    break
                end
            end
        }
    end
end
