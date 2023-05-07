# encoding: UTF-8

class NxTasksBoarded

    # NxTasksBoarded::items(board)
    def self.items(board)
        Solingen::mikuTypeItems("NxTask")
            .select{|item| item["boarduuid"] == board["uuid"] }
            .sort_by{|item| item["position"] }
    end


end
