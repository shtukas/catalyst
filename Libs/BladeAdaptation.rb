
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
            item["startdate"] = Blades::getMandatoryAttribute(filepath, "startdate")
            item["repeatType"] = Blades::getMandatoryAttribute(filepath, "repeatType")
            item["lastCelebrationDate"] = Blades::getMandatoryAttribute(filepath, "lastCelebrationDate")
        end

        if mikuType == "NxBoard" then
            item = {}
            item["uuid"] = Blades::getMandatoryAttribute(filepath, "uuid")
            item["mikuType"] = mikuType
            item["unixtime"] = Blades::getMandatoryAttribute(filepath, "unixtime")
            item["datetime"] = Blades::getMandatoryAttribute(filepath, "datetime")
            item["description"] = Blades::getMandatoryAttribute(filepath, "description")
            item["engine"] = Blades::getMandatoryAttribute(filepath, "engine")
        end

        if item then
            item["field11"] = Blades::getAttributeOrNull(filepath, "field11")
            item["boarduuid"] = Blades::getAttributeOrNull(filepath, "boarduuid")
            item["doNotShowUntil"] = Blades::getAttributeOrNull(filepath, "doNotShowUntil")
            item["note"] = Blades::getAttributeOrNull(filepath, "note")
            item["tmpskip1"] = Blades::getAttributeOrNull(filepath, "tmpskip1")
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

    # BladeAdaptation::commitItemToExistingBlade(item)
    def self.commitItemToExistingBlade(item)
        filepath = Blades::tokenToFilepathOrNull(item["uuid"])
        if filepath.nil? then
            raise "(error: 22a3cfc8-7325-4a3e-b9e2-7f12cf22d192) Could not determine filepath of assumed blade for item: #{item}"
        end

        puts "updating blade: #{filepath}"

        Blades::setAttribute(filepath, "field11", item["field11"])
        Blades::setAttribute(filepath, "boarduuid", item["boarduuid"])
        Blades::setAttribute(filepath, "doNotShowUntil", item["doNotShowUntil"])
        Blades::setAttribute(filepath, "note", item["note"])
        Blades::setAttribute(filepath, "tmpskip1", item["tmpskip1"])

        if item["mikuType"] == "NxAnniversary" then
            # We do not need to (re)set the uuid
            Blades::setAttribute(filepath, "mikuType", item["mikuType"])
            Blades::setAttribute(filepath, "unixtime", item["unixtime"])
            Blades::setAttribute(filepath, "datetime", item["datetime"])
            Blades::setAttribute(filepath, "description", item["description"])
            Blades::setAttribute(filepath, "startdate", item["startdate"])
            Blades::setAttribute(filepath, "repeatType", item["repeatType"])
            Blades::setAttribute(filepath, "lastCelebrationDate", item["lastCelebrationDate"])
            return
        end

        if item["mikuType"] == "NxBoard" then
            # We do not need to (re)set the uuid
            Blades::setAttribute(filepath, "mikuType", item["mikuType"])
            Blades::setAttribute(filepath, "unixtime", item["unixtime"])
            Blades::setAttribute(filepath, "datetime", item["datetime"])
            Blades::setAttribute(filepath, "description", item["description"])
            Blades::setAttribute(filepath, "engine", item["engine"])
            return
        end
        raise "(error: b90c4fc6-0096-469c-8a04-3b224283f80d) unsopported mikuType"
    end

    # BladeAdaptation::items(mikuType) # Array[Items]
    def self.items(mikuType)
        MikuTypes::mikuTypeUUIDsCached(mikuType)
            .map{|uuid| BladeAdaptation::uuidToItemOrNull(uuid) }
            .compact
    end
end
