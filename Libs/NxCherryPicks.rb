
class NxCherryPicks

    # NxCherryPicks::items()
    def self.items()
        N3Objects::getMikuType("NxCherryPick")
    end

    # NxCherryPicks::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxCherryPicks::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # NxCherryPicks::interactivelyDecidePosition()
    def self.interactivelyDecidePosition()
        position = LucilleCore::askQuestionAnswerAsString("> position (empty for next): ")
        if position == "" then
            items = NxCherryPicks::items()
            return 1 if items.empty?
            return 1 + items.map{|item| item["position"] }.max
        else
            return position.to_f
        end
    end

    # NxCherryPicks::interactivelyIssue(object, position = nil)
    def self.interactivelyIssue(object, position = nil)
        puts "> cherry picking '#{PolyFunctions::toString(object).green}'"
        position = position || NxCherryPicks::interactivelyDecidePosition()
        item = {
            "uuid"       => SecureRandom.uuid,
            "mikuType"   => "NxCherryPick",
            "unixtime"   => Time.new.to_i,
            "datetime"   => Time.new.utc.iso8601,
            "position"   => position,
            "targetuuid" => object["uuid"]
        }
        puts JSON.pretty_generate(item)
        NxCherryPicks::commit(item)
        item
    end

    # NxCherryPicks::listingItems(board)
    def self.listingItems(board)
        NxCherryPicks::items()
            .select{|item| 
                if board then
                    BoardsAndItems::belongsToThisBoard(item, board)
                else
                    true
                end
            }
            .sort{|i1, i2| i1["position"] <=> i2["position"] }
    end
end