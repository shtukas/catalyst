
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

    # NxCherryPicks::interactivelyIssueNullOrNull(object)
    def self.interactivelyIssueNullOrNull(object)
        puts "> cherry picking '#{PolyFunctions::toString(object).green}'"
        position = LucilleCore::askQuestionAnswerAsString("> position: ").to_f
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

    # NxCherryPicks::listingItems()
    def self.listingItems()
        NxCherryPicks::items()
            .select{|item| item["datetime"][0, 10] == CommonUtils::today() }
            .sort{|i1, i2| i1["position"] <=> i2["position"] }
    end

    # NxCherryPicks::dataManagement()
    def self.dataManagement()
        N3Objects::getMikuType("NxCherryPick")
            .each{|item|
                if item["datetime"][0, 10] != CommonUtils::today() then
                    N3Objects::destroy(item["uuid"])
                end
            }
    end
end