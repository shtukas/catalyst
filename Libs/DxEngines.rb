
class DxEngines

    # DxEngines::maintenance()
    def self.maintenance()
        uuids = DarkEnergy::all()
                    .select{|item| item["mikuType"] != "NxCore" }
                    .select{|item| item["engine"] }
                    .map{|item| item["uuid"] }
        CatalystSharedCache::set("53b9de3b-a3d4-4898-9c73-9f84727020eb", uuids)
    end

    # DxEngines::collectFromCache()
    def self.collectFromCache()
        CatalystSharedCache::getOrDefaultValue("53b9de3b-a3d4-4898-9c73-9f84727020eb", [])
            .map{|uuid| DarkEnergy::itemOrNull(uuid)}
            .compact
    end

    # DxEngines::listingItems()
    def self.listingItems()
        DxEngines::collectFromCache()
            .select{|item| TxEngines::compositeCompletionRatio(item["engine"]) < 1 }
    end
end