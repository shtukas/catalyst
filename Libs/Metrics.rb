
class Metrics

    # Metrics::coreuuid(item)
    def self.coreuuid(item)
        return nil if item["coreuuid"].nil?
        core = DarkEnergy::itemOrNull(item["coreuuid"])
        if core.nil? then
            DarkEnergy::patch(item["uuid"], "coreuuid", nil)
            return nil
        end
        Metrics::item(core)
    end

    # Metrics::sequenceuuid(item)
    def self.sequenceuuid(item)
        return nil if item["sequenceuuid"].nil?
        sequence = DarkEnergy::itemOrNull(item["sequenceuuid"])
        if sequence.nil? then
            DarkEnergy::patch(item["uuid"], "sequenceuuid", nil)
            return nil
        end
        Metrics::item(sequence)
    end

    # Metrics::engineuuid(item)
    def self.engineuuid(item)
        return nil if item["engineuuid"].nil?
        engine = DarkEnergy::itemOrNull(item["engineuuid"])
        if engine.nil? then
            DarkEnergy::patch(item["uuid"], "engineuuid", nil)
            return nil
        end
        Metrics::item(sequence)
    end

    # Metrics::item(item)
    def self.item(item)

        if item["mikuType"] == "NxAnniversary" then
            return 3.0
        end

        if item["mikuType"] == "PhysicalTarget" then
            return 2.5
        end

        if item["mikuType"] == "NxCore" then
            return NxCores::listingmetric(item)
        end

        if item["mikuType"] == "NxBackup" then
            return 2.0
        end

        if item["mikuType"] == "TxEngine" then
            return TxEngines::listingmetric(item)
        end

        if item["mikuType"] == "Wave" then
            return 2.3 if item["interruption"]
            return 1.5
        end

        if item["mikuType"] == "NxOndate" then
            return 1.3
        end

        if item["mikuType"] == "NxSequence" then
            numbers = [
                Metrics::coreuuid(item),
                Metrics::engineuuid(item)
            ].compact
            return (numbers.size > 0 ? (0.5 + 0.5 * numbers.max) : 0.5)
        end

        raise "cannot compute metric for item: #{item}"
    end
end
