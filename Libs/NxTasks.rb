

class NxTasks

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Cubes2::itemInit(uuid, "NxTask")
        payload = TxPayload::interactivelyMakeNew(uuid)
        payload.each{|k, v| Cubes2::setAttribute(uuid, k, v) }
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # NxTasks::urlToTask(url)
    def self.urlToTask(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid
        Cubes2::itemInit(uuid, "NxTask")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::setAttribute(uuid, "url-e88a", url)
        Cubes2::itemOrNull(uuid)
    end

    # NxTasks::bufferInLocationToTask(location)
    def self.bufferInLocationToTask(location)
        description = "(buffer-in) #{File.basename(location)}"
        uuid = SecureRandom.uuid
        Cubes2::itemInit(uuid, "NxTask")
        aionreferences = AionCore::commitLocationReturnHash(Elizabeth.new(uuid), location)
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::setAttribute(uuid, "aion-point-7c758c", aionreferences)
        Cubes2::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask1(uuid, description)
    def self.descriptionToTask1(uuid, description)
        Cubes2::itemInit(uuid, "NxTask")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        icon = (lambda {|item|
            if NxTasks::isOrphan(item) then
                return "◽️"
            end
            "🔹"
        }).call(item)
        "#{icon} #{item["description"]}"
    end

    # NxTasks::engined()
    def self.engined()
        Cubes2::mikuType("NxTask")
            .select{|item| item["engine-0020"] }
    end

    # NxTasks::getParentOrNull(item)
    def self.getParentOrNull(item)
        return nil if item["parentuuid-0032"].nil?
        Cubes2::itemOrNull(item["parentuuid-0032"])
    end

    # NxTasks::isOrphan(item)
    def self.isOrphan(item)
        NxTasks::getParentOrNull(item).nil?
    end
end
