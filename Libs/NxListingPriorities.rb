
class NxListingPriorities

    # NxListingPriorities::items()
    def self.items()
        N3Objects::getMikuType("NxListingPriority")
    end

    # NxListingPriorities::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxListingPriorities::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # NxListingPriorities::interactivelyDecidePosition()
    def self.interactivelyDecidePosition()
        position = LucilleCore::askQuestionAnswerAsString("> position (empty for next): ")
        if position == "" then
            items = NxListingPriorities::items()
            return 1 if items.empty?
            return 1 + items.map{|item| item["position"] }.max
        else
            return position.to_f
        end
    end

    # NxListingPriorities::interactivelyIssue(object, position = nil)
    def self.interactivelyIssue(object, position = nil)
        puts "> set listing priority '#{PolyFunctions::toString(object).green}'"
        position = position || NxListingPriorities::interactivelyDecidePosition()
        item = {
            "uuid"       => SecureRandom.uuid,
            "mikuType"   => "NxListingPriority",
            "unixtime"   => Time.new.to_i,
            "datetime"   => Time.new.utc.iso8601,
            "position"   => position,
            "targetuuid" => object["uuid"],
            "boarduuid"  => object["boarduuid"]
        }
        puts JSON.pretty_generate(item)
        NxListingPriorities::commit(item)
        item
    end

    # NxListingPriorities::listingItems(board)
    def self.listingItems(board)
        NxListingPriorities::items()
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