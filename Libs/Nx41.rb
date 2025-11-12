
class Nx41

    # Nx41::listingFirstPosition()
    def self.listingFirstPosition()
        positions = Items::items()
            .select{|item| item["mikuType"] == "NxPolymorph" }
            .map{|item| item["nx41"]["position"] }
            .compact
        return 1 if positions.empty?
        positions.min
    end

    # Nx41::listingNthPosition(n)
    def self.listingNthPosition(n)
        positions = Items::items()
            .select{|item| item["mikuType"] == "NxPolymorph" }
            .select{|item| FrontPage::isVisible(item) }
            .select{|item| item["nx41"] }
            .map{|item| item["nx41"]["position"] }
            .compact
            .sort
        return 1 if positions.empty?
        if positions.size > n then
            return positions.drop(n).first
        end
        positions.max + 1
    end

    # Nx41::decideItemListingPositionOrNull(item) # [position: null or float, item]
    def self.decideItemListingPositionOrNull(item)
        if item["nx41"] then
            return [item["nx41"]["position"], item]
        end
        runningTimespan = (lambda{
            nxball = NxBalls::getNxBallOrNull(item)
            return 0 if nxball.nil?
            NxBalls::ballRunningTime(nxball)
        }).call()
        position = TxBehaviour::decideListingPositionOrNull(item["bx42"], runningTimespan)
        return [nil, item] if position.nil?
        Nx41::setNx41(item, {
            "type"     => "computed",
            "unixtime" => Time.new.to_i,
            "position" => position
        })
        item = Items::itemOrNull(item["uuid"])
        [position, item]
    end

    # Nx41::setNx41(item, nx41)
    def self.setNx41(item, nx41)
        Items::setAttribute(item["uuid"], "nx41", nx41)
    end

    # Nx41::delist(item)
    def self.delist(item)
        Items::setAttribute(item["uuid"], "nx41", nil)
    end
end
