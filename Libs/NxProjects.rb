
class NxProjects

    # NxProjects::icon()
    def self.icon()
        "⛵️"
    end

    # NxProjects::toString(item)
    def self.toString(item)
        "#{NxProjects::icon()} #{item["description"]}#{Parenting::suffix(item)}"
    end
end
