
class NxUltraPicks

    # NxUltraPicks::items()
    def self.items()
        N3Objects::getMikuType("NxUltraPick")
    end

    # NxUltraPicks::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxUltraPicks::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # NxUltraPicks::interactivelyDecidePosition()
    def self.interactivelyDecidePosition()
        position = LucilleCore::askQuestionAnswerAsString("> position (empty for next): ")
        if position == "" then
            items = NxUltraPicks::items()
            return 1 if items.empty?
            return 1 + items.map{|item| item["position"] }.max
        else
            return position.to_f
        end
    end

    # NxUltraPicks::interactivelyIssue(object)
    def self.interactivelyIssue(object)
        puts "> cherry picking '#{PolyFunctions::toString(object).green}'"
        position = NxUltraPicks::interactivelyDecidePosition()
        item = {
            "uuid"       => SecureRandom.uuid,
            "mikuType"   => "NxUltraPick",
            "unixtime"   => Time.new.to_i,
            "datetime"   => Time.new.utc.iso8601,
            "position"   => position,
            "targetuuid" => object["uuid"]
        }
        puts JSON.pretty_generate(item)
        NxUltraPicks::commit(item)
        item
    end

    # NxUltraPicks::listingItems()
    def self.listingItems()
        NxUltraPicks::items()
            .sort{|i1, i2| i1["position"] <=> i2["position"] }
    end
end