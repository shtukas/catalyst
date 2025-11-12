
=begin

Nx41
{
    "type"    : "fixed-at-the-top"
    "unixtime": integer
    "position": Float
}
{
    "type"    : "computed"
    "unixtime": Integer
    "position": Float
}

=end

class Nx41

    # Nx41::listingFirstPosition()
    def self.listingFirstPosition()
        positions = Items::items()
            .select{|item| item["mikuType"] == "NxPolymorph" }
            .map{|item| item["listing-position-2141"] }
            .compact
        return 1 if positions.empty?
        positions.min
    end

    # Nx41::listingNthPosition(n)
    def self.listingNthPosition(n)
        positions = Items::items()
            .select{|item| item["mikuType"] == "NxPolymorph" }
            .select{|item| FrontPage::isVisible(item) }
            .map{|item| item["listing-position-2141"] }
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
        if item["listing-position-2141"] then
            return [item["listing-position-2141"], item]
        end
        runningTimespan = (lambda{
            nxball = NxBalls::getNxBallOrNull(item)
            return 0 if nxball.nil?
            NxBalls::ballRunningTime(nxball)
        }).call()
        position = TxBehaviour::decideListingPositionOrNull(item["bx42"], runningTimespan)
        return [nil, item] if position.nil?
        NxPolymorphs::setListingPosition(item, position)
        item = Items::itemOrNull(item["uuid"])
        [position, item]
    end

end
