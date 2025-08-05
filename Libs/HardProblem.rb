class HardProblem

    # HardProblem::item_attribute_has_been_updated(uuid, attribute, value)
    def self.item_attribute_has_been_updated(uuid, attribute, value)
        ListingDatabase::evaluate(uuid)
    end

    # HardProblem::item_has_been_destroyed(uuid)
    def self.item_has_been_destroyed(uuid)
        Parenting::removeIdentifierFromDatabase(uuid)
        ListingDatabase::removeEntry(uuid)
    end

    # HardProblem::item_could_not_be_found_on_disk(uuid)
    def self.item_could_not_be_found_on_disk(uuid)
        Parenting::removeIdentifierFromDatabase(uuid)
    end

    # HardProblem::item_is_being_destroyed(item)
    def self.item_is_being_destroyed(item)
        Parenting::removeIdentifierFromDatabase(item["uuid"])
        
        # Version 1
        # This synchronous processing was taking too long, so we are doing version 2
        # Datablocks::removeUUID(item["uuid"])

        # Version 2
        filepath = "#{Config::pathToCatalystDataRepository()}/items-destroyed/#{(Time.new.to_f * 1000).to_i}.txt"
        File.open(filepath, "w") {|f| f.puts(item["uuid"]) }
    end
end
