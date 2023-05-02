
=begin
Blades
    Blades::init(mikuType, uuid)
    Blades::tokenToFilepathOrNull(token)
    Blades::setAttribute(token, attribute_name, value)
    Blades::getAttributeOrNull(token, attribute_name)
    Blades::getMandatoryAttribute(token, attribute_name)
    Blades::addToSet(token, set_id, element_id, value)
    Blades::removeFromSet(token, set_id, element_id)
    Blades::putDatablob(token, key, datablob)
    Blades::getDatablobOrNull(token, key)
=end

=begin
MikuTypes
    MikuTypes::mikuTypeUUIDsCached(mikuType) # Cached
    MikuTypes::uuidEnumeratorForMikuTypeFromDisk(mikuType)
=end

class BladeAdaptation

    # BladeAdaptation::readFileAsItemOrError(filepath)
    def self.readFileAsItemOrError(filepath)
        raise "(error: 5d519cf9-680a-4dab-adda-6fa160ef9f47)" if !File.exist?(filepath)
        mikuType = Blades::getMandatoryAttribute(filepath, "mikuType")
        if mikuType == "NxAnniversary" then
            item = {}
            item["uuid"] = Blades::getMandatoryAttribute(filepath, "uuid")
            item["mikuType"] = mikuType
            item["unixtime"] = Blades::getMandatoryAttribute(filepath, "unixtime")
            item["datetime"] = Blades::getMandatoryAttribute(filepath, "datetime")
            item["description"] = Blades::getMandatoryAttribute(filepath, "description")
            item["doNotShowUntil"] = Blades::getAttributeOrNull(filepath, "doNotShowUntil")
            item["startdate"] = Blades::getMandatoryAttribute(filepath, "startdate")
            item["repeatType"] = Blades::getMandatoryAttribute(filepath, "repeatType")
            item["lastCelebrationDate"] = Blades::getMandatoryAttribute(filepath, "lastCelebrationDate")
            return item
        end
        raise "(error: 17844ff9-8aa1-4cc7-a477-a4479a8a74ac)"
    end

    # BladeAdaptation::uuidToItemOrNull(uuid)
    def self.uuidToItemOrNull(uuid)
        filepath = Blades::tokenToFilepathOrNull(uuid)
        return nil if filepath.nil?
        begin
            return BladeAdaptation::readFileAsItemOrError(filepath)
        rescue
        end
        nil
    end
end
