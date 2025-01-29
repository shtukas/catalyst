
class Precomputations

    # Precomputations::general_key_prefix()
    def self.general_key_prefix()
        prefix = XCache::getOrNull("e2bfa276-0f40-4ed1-90c9-7bd158c236e1")
        return prefix if prefix
        prefix = SecureRandom.hex
        XCache::set("e2bfa276-0f40-4ed1-90c9-7bd158c236e1", prefix)
        prefix
    end

    # Precomputations::getDataOrNull(datasetname)
    def self.getDataOrNull(datasetname)
        data = XCache::getOrNull("#{Precomputations::general_key_prefix()}:980ac3ff-09e7-4785-8301-66a0a05ce883:#{CommonUtils::today()}:#{datasetname}")
        return nil if data.nil?
        JSON.parse(data)
    end

    # Precomputations::setData(datasetname, data)
    def self.setData(datasetname, data)
        XCache::set("#{Precomputations::general_key_prefix()}:980ac3ff-09e7-4785-8301-66a0a05ce883:#{CommonUtils::today()}:#{datasetname}", JSON.generate(data))
    end

    # Precomputations::anniversariesForListing()
    def self.anniversariesForListing()
        data = Precomputations::getDataOrNull("31621733-d3a2")
        return data if data
        data = Anniversaries::listingItems()
        Precomputations::setData("31621733-d3a2", data)
        data
    end

    # Precomputations::backupsForListing()
    def self.backupsForListing()
        data = Precomputations::getDataOrNull("ca55d2d7-185f")
        return data if data
        data = NxBackups::listingItems()
        Precomputations::setData("ca55d2d7-185f", data)
        data
    end

    # Precomputations::datedForListing()
    def self.datedForListing()
        data = Precomputations::getDataOrNull("62d3a24d-1d27")
        return data if data
        data = NxDateds::listingItems()
        Precomputations::setData("62d3a24d-1d27", data)
        data
    end

    # Precomputations::floatsForListing()
    def self.floatsForListing()
        data = Precomputations::getDataOrNull("8395caee-8bec")
        return data if data
        data = NxFloats::listingItems()
        Precomputations::setData("8395caee-8bec", data)
        data
    end

    # Precomputations::coresForListing()
    def self.coresForListing()
        data = Precomputations::getDataOrNull("32549c3f-a0fd")
        return data if data
        data = NxCores::listingItems()
        Precomputations::setData("32549c3f-a0fd", data)
        data
    end

    # Precomputations::activeItems()
    def self.activeItems()
        data = Precomputations::getDataOrNull("cf5c5bb0-f247")
        return data if data
        data = NxTasks::activeItems()
        Precomputations::setData("cf5c5bb0-f247", data)
        data
    end

    # Precomputations::wavesForListing()
    def self.wavesForListing()
        data = Precomputations::getDataOrNull("2fec40e1-c6f4")
        return data if data
        data = Waves::listingItems()
        Precomputations::setData("2fec40e1-c6f4", data)
        data
    end

    # Precomputations::itemToListingToString2(store, item)
    def self.itemToListingToString2(store, item)
        line = Precomputations::getDataOrNull("d56f0928-e8e1:#{item["uuid"]}")
        return line if line
        line = Listing::toString2(store, item)
        Precomputations::setData("d56f0928-e8e1:#{item["uuid"]}", line)
        line
    end

    # Precomputations::listingMetricOrNull(item)
    def self.listingMetricOrNull(item)
        data = Precomputations::getDataOrNull("30b80539-628d:#{item["uuid"]}")
        return data if data
        data = ListingMetric::metricOrNull(item)
        Precomputations::setData("30b80539-628d:#{item["uuid"]}", data)
        data
    end

    # Precomputations::addPrefix(items)
    def self.addPrefix(items)
        key = items.map{|item| "7525b281-22bf:#{item["uuid"]}" }.join(':')
        is = Precomputations::getDataOrNull(key)
        return is if is
        items = Prefix::addPrefix(items)
        Precomputations::setData(key, items)
        items
    end

    # Precomputations::itemHasBeenUpdatedNotMikuType(item)
    def self.itemHasBeenUpdatedNotMikuType(item)

    end

    # Precomputations::mikuTypeHasBeenUpdated()
    def self.mikuTypeHasBeenUpdated()
        XCache::set("e2bfa276-0f40-4ed1-90c9-7bd158c236e1", SecureRandom.hex)
    end
end
