
class Focus23

    # Focus23::interactivelyDecideFocus23OrNull()
    def self.interactivelyDecideFocus23OrNull()
        options = [
            "priority",
            "happening",
            "today",
            "short-run-with-deadline",
            "short-run",
            "long-run"
        ]
        LucilleCore::selectEntityFromListOfEntitiesOrNull("focus", options)
    end

    # Focus23::interactivelySetFocus23OrNothing(item)
    def self.interactivelySetFocus23OrNothing(item)
        focus = Focus23::interactivelyDecideFocus23OrNull()
        return item if focus.nil?
        Items::setAttribute(item["uuid"], "focus-23", focus)
        Items::itemOrNull(item["uuid"])
    end

    # Focus23::suffix(item)
    def self.suffix(item)
        return "" if item["focus-23"].nil?
        " [#{item["focus-23"]}]".red
    end
end
