# encoding: UTF-8

class NxTasksPositions

    # -------------------------------------------
    # Data: Positions

    # NxTasksPositions::firstPosition()
    def self.firstPosition()
        items = Solingen::mikuTypeItems("NxTask")
        return 1 if items.empty?
        items.map{|item| item["position"]}.min
    end

    # NxTasksPositions::lastPosition()
    def self.lastPosition()
        items = Solingen::mikuTypeItems("NxTask")
        return 1 if items.empty?
        items.map{|item| item["position"]}.max
    end

    # NxTasksPositions::computeThatPosition(positions)
    def self.computeThatPosition(positions)
        return rand if positions.empty?
        if positions.size < 4 then
            return positions.max + 0.5 + rand
        end
        positions # a = [1, 2, 8, 9]
        x = positions.zip(positions.drop(1)) # [[1, 2], [2, 8], [8, nil]]
        x = x.select{|pair| pair[1] } # [[1, 2], [2, 8]
        differences = x.map{|pair| pair[1] - pair[0] } # [1, 7]
        difference_average = differences.inject(0, :+).to_f/differences.size
        x.each{|pair|
            next if (pair[1] - pair[0]) < difference_average
            return pair[0] + rand*(pair[1] - pair[0])
        }
        raise "NxTasksPositions::computeThatPosition failed: positions: #{positions.join(", ")}"
    end

    # NxTasksPositions::slice_positioning1(items, index1, index2)
    def self.slice_positioning1(items, index1, index2)
        positions = items.drop(index1).take(index2-index1).map{|item| item["position"] }
        NxTasksPositions::computeThatPosition(positions)
    end

    # -------------------------------------------

    # NxTasksPositions::interactivelyDecidePositionAtBoardAtTop(board)
    def self.interactivelyDecidePositionAtBoardAtTop(board)
        puts "-- begin-------------".green
        NxPrincipals::boardToNxTasksOrdered(board)
            .take(CommonUtils::screenHeight()-5)
            .each{|item| puts NxTasks::toStringNoEngine(item) }
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        if position == "" then
            position = NxTasksPositions::lastPosition() + 1
            puts "> position: #{position}"
            return position
        end
        position.to_f
    end

    # NxTasksPositions::decideNewPositionAtBoard(board)
    def self.decideNewPositionAtBoard(board)
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["manual positioning", "next (default)"])
        if option == "manual positioning" then
            return NxTasksPositions::interactivelyDecidePositionAtBoardAtTop(board)
        end
        NxTasksPositions::lastPosition() + 0.5 + rand
    end

    # -------------------------------------------

    # NxTasksPositions::interactivelyDecidePositionAtNoBoardAtTop()
    def self.interactivelyDecidePositionAtNoBoardAtTop()
        puts "-- begin-------------".green
        NxTasks::boardlessItems()
            .sort_by{|item| item["position"] }
            .take(CommonUtils::screenHeight()-5)
            .each{|item| puts NxTasks::toStringNoEngine(item) }
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        if position == "" then
            position = NxTasksPositions::lastPosition() + 1
            puts "> position: #{position}"
            return position
        end
        position.to_f
    end

    # NxTasksPositions::slice_positioning2_boardless(index1, index2)
    def self.slice_positioning2_boardless(index1, index2)
        items = NxTasks::boardlessItems()
                    .sort_by{|item| item["position"] }
                    .take(index2)
        NxTasksPositions::slice_positioning1(items, index1, index2)
    end

    # NxTasksPositions::decideNewPositionAtNoBoard()
    def self.decideNewPositionAtNoBoard()
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["stack top", "manual positioning", "automatic positioning (10, 20)", "automatic positioning (50, 100)", "next"])
        if option == "stack top" then
            return NxTasksPositions::firstPosition() - 1
        end
        if option == "manual positioning" then
            return NxTasksPositions::interactivelyDecidePositionAtNoBoardAtTop()
        end
        if option == "automatic positioning (10, 20)" then
            return NxTasksPositions::slice_positioning2_boardless(10, 20)
        end
        if option == "automatic positioning (50, 100)" then
            return NxTasksPositions::slice_positioning2_boardless(50, 100)
        end
        if option == "next" then
            return NxTasksPositions::lastPosition() + 0.5 + rand
        end
        NxTasksPositions::decideNewPositionAtNoBoard()
    end

    # -------------------------------------------

    # NxTasksPositions::decideNewPositionAtThread(thread)
    def self.decideNewPositionAtThread(thread)
        items = NxThreads::threadToItems(thread)
        return 1 if items.size > 0
        items.sort_by{|item|
            puts "#{item["position"]} : #{item["description"]}"
        }
        LucilleCore::askQuestionAnswerAsString("position: ").to_f
    end

    # -------------------------------------------
    # Data: Positions

    # NxTasksPositions::decidePositionAtOptionalBoard(mboard)
    def self.decidePositionAtOptionalBoard(mboard)
        if mboard then
            NxTasksPositions::decideNewPositionAtBoard(mboard)
        else
            NxTasksPositions::decideNewPositionAtNoBoard()
        end
    end
end
