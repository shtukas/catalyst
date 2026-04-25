class GlobalPositioning

    # GlobalPositioning::first_position()
    def self.first_position()
        ([1] + Items::items().map{|item| item["global-pos-07"] || 0 }).min
    end

    # GlobalPositioning::last_position()
    def self.last_position()
        ([1] + Items::items().map{|item| item["global-pos-07"] || 0 }).max
    end

    # GlobalPositioning::insert_first(item)
    def self.insert_first(item)
        Items::setAttribute(item["uuid"], "global-pos-07", GlobalPositioning::first_position() - 1)
        Items::itemOrNull(item["uuid"])
    end

    # GlobalPositioning::insert_last(item)
    def self.insert_last(item)
        Items::setAttribute(item["uuid"], "global-pos-07", GlobalPositioning::last_position() + 1)
        Items::itemOrNull(item["uuid"])
    end
end