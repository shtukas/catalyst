
class TimeCommitments

    # TimeCommitments::listingitems()
    def self.listingitems()
        (NxBoards::listingItems() + NxMonitor1s::listingItems())
            .select{|item| TxEngines::completionRatio(item["engine"]) < 1 }
            .sort_by{|item| TxEngines::completionRatio(item["engine"]) }
    end

    # TimeCommitments::activeItems()
    def self.activeItems()
        [
            NxTasks::items()
                .select{|item| item["boarduuid"] }
                .select{|item| NxBalls::itemIsActive(item) },
            NxLongs::items()
                .select{|item| NxBalls::itemIsActive(item) },
            NxTasksBoardless::items()
                .sort_by{|item| item["position"] }
                .first(100)
                .select{|item| NxBalls::itemIsActive(item) }
        ]
            .flatten
    end

    # TimeCommitments::firstItem()
    def self.firstItem()
        active = TimeCommitments::activeItems()
        return active if active.size > 0

        TimeCommitments::listingitems().each{|domain|
            if domain["mikuType"] == "NxBoard" then
                board = domain
                NxBoards::itemsForProgram1(board).each{|item|
                    return [item]
                }
            end
            if domain["mikuType"] == "NxMonitor1" then
                if domain["uuid"] == "347fe760-3c19-4618-8bf3-9854129b5009" then # Long Running Projects
                    NxLongs::items()
                        .select{|item| item["active"] }
                        .sort_by{|item| TxEngines::completionRatio(item["engine"]) }
                        .each{|item|
                            return [item]
                        }
                end
                if domain["uuid"] == "347fe760-3c19-4618-8bf3-9854129b5009" then # NxTasks (boardless)
                    NxTasksBoardless::items()
                        .sort_by{|item| item["position"] }
                        .each{|item|
                            next if NxTasks::completionRatio(item) >= 1
                            return [item]
                        }
                end
            end
        }
    end
end