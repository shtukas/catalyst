
class TxBehaviour

    # TxBehaviour::behaviourToListingPosition(behavior)
    def self.behaviourToListingPosition(behavior)
        if behavior["listing-position"] then
            return behavior["position"]
        end
        return 0
    end

    # TxBehaviour::doneBehaviour(behavior: TxBehaviour) -> TxBehaviour
    def self.doneBehaviour(behavior)
        # {
        #     "btype": "listing-position"
        #     "position": Float
        # }
        if behavior["btype"] == "listing-position" then
            return nil # it's being destroyed
        end
    end

    # TxBehaviour::doneBehaviours(behaviours: Array[TxBehaviour]) -> Array[TxBehaviour]
    def self.doneBehaviours(behaviours)
        behaviours
            .map{|behaviour| TxBehaviour::doneBehaviour(behaviour) }
            .compact
    end
end
