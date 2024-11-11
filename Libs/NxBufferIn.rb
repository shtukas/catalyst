
class NxBufferIn

    # ------------------
    # Data

    # NxBufferIn::listingItems()
    def self.listingItems()
        uuid = "df07ca49-34f8-4ded-9682-39a73c3b08a9"
        return [] if Bank1::recoveredAverageHoursPerDay(uuid) > 1
        [
            {
                "uuid" => uuid,
                "mikuType" => "NxBufferIn"
            }
        ]
    end

end
