class Focus24
    # Focus24::interactivelyDecideFocus()
    def self.interactivelyDecideFocus()
        types = [
            "priority",
            "happening",
            "today",
            "task:todo-within-days",
            "task:todo-within-a-week",
            "task:todo-within-weeks",
            "task:todo-within-a-month",
            "project:run-with-deadline",
            "project:short-run",
            "project:long-run"
        ]
        type = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("focus", types)
        if type == "priority" then
            return {
                "type"  => "priority"
            }
        end
        if type == "happening" then
            return {
                "type"  => "happening"
            }
        end
        if type == "today" then
            return {
                "type"  => "today",
                "unixtime" => Time.new.to_f
            }
        end
        if type == "task:todo-within-days" then
            return {
                "type"  => "task:todo-within-days",
                "start" => Time.new.to_s
            }
        end
        if type == "task:todo-within-a-week" then
            return {
                "type"  => "task:todo-within-a-week",
                "start" => Time.new.to_s
            }
        end
        if type == "task:todo-within-weeks" then
            return {
                "type"  => "task:todo-within-weeks",
                "start" => Time.new.to_s
            }
        end
        if type == "task:todo-within-a-month" then
            return {
                "type"  => "task:todo-within-a-month",
                "start" => Time.new.to_s
            }
        end
        if type == "project:run-with-deadline" then
            return {
                "type"     => "project:run-with-deadline",
                "deadline" => (lambda{
                    loop {
                        datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCodeOrNull()
                        return datetime if datetime
                    }
                }).call()
            }
        end
        if type == "project:short-run" then
            return {
                "type"     => "project:short-run",
                "unixtime" => Time.new.to_f
            }
        end
        if type == "project:long-run" then
            return {
                "type"     => "project:long-run",
                "unixtime" => Time.new.to_f
            }
        end
        raise "(error: 3c474905) unsupported type: #{type}"
    end

    # Focus24::interactivelyUpdateItemWithNewFocus(item)
    def self.interactivelyUpdateItemWithNewFocus(item)
        focus = Focus24::interactivelyDecideFocus()
        Items::setAttribute(item["uuid"], "focus-24", focus)
        Items::itemOrNull(item["uuid"])
    end

    # Focus24::interactivelyUpdateFocus24AsPartOfDismissalOrNothing(item)
    def self.interactivelyUpdateFocus24AsPartOfDismissalOrNothing(item)
        focus = item["focus-24"]
    end

    # Focus24::toString(focus)
    def self.toString(focus)
        focus["type"]
    end

    # Focus24::suffix(item)
    def self.suffix(item)
        return "" if item["focus-24"].nil?
        " [#{Focus24::toString(item["focus-24"])}]".yellow
    end
end
