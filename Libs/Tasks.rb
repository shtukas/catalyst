
# encoding: UTF-8

class Tasks

    # Tasks::lastTaskPosition()
    def self.lastTaskPosition()
        Items::mikuType("NxPolymorph")
            .select{|item| item["bx42"]["btype"] == "task" }
            .sort_by{|item| item["unixtime"] }
            .map{|item| item["nx41"]["position"] }
            .max
    end
end
