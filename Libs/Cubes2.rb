# encoding: UTF-8

class Cubes2

    # Cubes2::itemInit(uuid, mikuType)
    def self.itemInit(uuid, mikuType)
        $DATA_CENTER_DATA["items"][uuid] = {
            "uuid"     => uuid,
            "mikuType" => mikuType
        }
        $DATA_CENTER_UPDATE_QUEUE << {
            "type"     => "item-init",
            "uuid"     => uuid,
            "mikuType" => mikuType
        }
        DataProcessor::processQueue()
    end

    # Cubes2::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        $DATA_CENTER_DATA["items"][uuid]
    end

    # Cubes2::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        if $DATA_CENTER_DATA["items"][uuid].nil? then
            raise "(error: 417a064c-d89b-4d20-ac96-529db96d2c23); uuid: #{uuid}, attrname: #{attrname}, attrvalue: #{attrvalue}"
        end
        $DATA_CENTER_DATA["items"][uuid][attrname] = attrvalue
        $DATA_CENTER_UPDATE_QUEUE << {
            "type"            => "item-attribute-update",
            "iuuid"           => uuid,
            "attribute-name"  => attrname,
            "attribute-value" => attrvalue
        }
        DataProcessor::processQueue()
        nil
    end

    # Cubes2::destroy(uuid)
    def self.destroy(uuid)
        $DATA_CENTER_DATA["items"].delete(uuid)
        $DATA_CENTER_UPDATE_QUEUE << {
            "type" => "item-destroy",
            "uuid" => uuid,
        }
        DataProcessor::processQueue()
    end

    # Cubes2::items()
    def self.items()
        $DATA_CENTER_DATA["items"].values
    end

   # Cubes2::mikuType(mikuType)
    def self.mikuType(mikuType)
        $DATA_CENTER_DATA["items"].values.select{|item| item["mikuType"] == mikuType }
    end
end
