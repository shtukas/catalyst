
class BufferIn

    # BufferIn::uuid()
    def self.uuid()
        "0a8ca68f-d931-4110-825c-8fd290ad7853"
    end

    # BufferIn::listingItems()
    def self.listingItems()
        [Blades::itemOrNull(BufferIn::uuid())]
    end

    # BufferIn::toString(item)
    def self.toString(item)
        "🥐 BufferIn"
    end
end
