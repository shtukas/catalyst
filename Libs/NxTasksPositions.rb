# encoding: UTF-8

class NxTasksPositions

    # NxTasksPositions::interactivelyDecidePositionAtBoardAtTop(board)
    def self.interactivelyDecidePositionAtBoardAtTop(board)
        NxBoards::boardToItemsOrdered(board)
            .take(CommonUtils::screenHeight()-5)
            .each{|item| puts NxTasks::toString(item) }
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        if position == "" then
            return NxTasks::lastPosition() + 1
        end
        position.to_f
    end

    # NxTasksPositions::thatPosition(positions)
    def self.thatPosition(positions)
        return rand if positions.empty?
        if positions.size < 4 then
            return positions.max + 0.5 + rand
        end
        positions # a = [1, 2, 8, 9]
        x = positions.zip(positions.drop(1)) # [[1, 2], [2, 8], [8, nil]]
        x = x.select{|pair| pair[1] } # [[1, 2], [2, 8]
        differences = x.map{|pair| pair[1] - pair[0] } # [1, 7]
        difference_average = differences.inject(0, :+).to_f/differences.size
        differences.each{|pair|
            next if (pair[1] - pair[0]) < difference_average
            return pair[0] + rand*(pair[1] - pair[0])
        }
        raise "NxTasksPositions::thatPosition failed: positions: #{positions.join(", ")}"
    end

    # NxTasksPositions::computeThatPositionAtBoard(board)
    def self.computeThatPositionAtBoard(board)
        NxTasksPositions::thatPosition(NxBoards::boardToItemsOrdered(board).map{|item| item["position"]})
    end

    # NxTasksPositions::decideNewPositionAtBoard(board)
    def self.decideNewPositionAtBoard(board)
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["among top positions", "that position"])
        if option == "among top positions" then
            return NxTasksPositions::interactivelyDecidePositionAtBoardAtTop(board)
        end
        if option == "that position" then
            return NxTasksPositions::computeThatPositionAtBoard(board)
        end
        raise "(error: 1296193b-555c-466c-89c9-5958bb4f2cab)"
    end

    # NxTasksPositions::interactivelyDecidePositionAtNoBoardAtTop()
    def self.interactivelyDecidePositionAtNoBoardAtTop()
        NxTasks::boardlessItems()
            .sort_by{|item| item["position"] }
            .take(CommonUtils::screenHeight()-5)
            .each{|item| puts NxTasks::toString(item) }
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        if position == "" then
            return NxTasks::lastPosition() + 1
        end
        position.to_f
    end

    # NxTasksPositions::computeThatPositionAtNoBoard()
    def self.computeThatPositionAtNoBoard()
        NxTasksPositions::thatPosition(NxTasks::boardlessItems().map{|item| item["position"]})
    end

    # NxTasksPositions::decideNewPositionAtNoBoard()
    def self.decideNewPositionAtNoBoard()
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["among top positions", "that position"])
        if option == "among top positions" then
            return NxTasksPositions::interactivelyDecidePositionAtNoBoardAtTop()
        end
        if option == "that position" then
            return NxTasksPositions::computeThatPositionAtNoBoard()
        end
        raise "(error: 38d52e7c-0db1-4f39-8e53-eb3bb6f536d9)"
    end

    # NxTasksPositions::decidePositionAtOptionalBoard(mboard)
    def self.decidePositionAtOptionalBoard(mboard)
        if mboard then
            NxTasksPositions::decideNewPositionAtBoard(mboard)
        else
            NxTasksPositions::decideNewPositionAtNoBoard()
        end
    end

end
