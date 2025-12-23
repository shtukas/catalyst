
class NxInProgress

    # NxInProgress::icon()
    def self.icon()
        "⛵️"
    end

    # NxInProgress::toString(item)
    def self.toString(item)
        "#{NxInProgress::icon()} #{item["description"]}"
    end
end
