
class TxBehaviour

    # TxBehaviour::behaviourToListingPosition(behavior)
    def self.behaviourToListingPosition(behavior)
        # There should not be negative positions

        # 0.010 -> 0.020 Wave interruption
        # 0.100 -> 0.150 NxEvents
        # 0.160 -> 0.160 NxAwait
        # 0.260 -> 0.280 NxAnniversary
        # 0.280 -> 0.300 NxLambda
        # 0.300 -> 0.320 Wave sticky
        # 0.400 -> 0.450 NxBackup
        # 0.500 -> 0.600 NxOnDate
        # 0.750 -> 0.780 NxProject
        # 0.800 -> 0.880 NxTask
        # 0.390 -> 1.000 Wave (overlay)

        # {
        #     "btype": "listing-position"
        #     "position": Float
        # }
        if behavior["btype"] == "listing-position" then
            return behavior["position"]
        end

        #{
        #    "btype": "NxAwait"
        #    "creationUnixtime": Float
        #}
        if behavior["btype"] == "NxAwait" then
            dx = ListingService::realLineTo01Increasing(behavior["creationUnixtime"] - 1759082216)
            return 0.160 + dx.to_f/1000
        end

        raise "I do not know how to compute listing position for behaviour: #{behaviour}"
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

        #{
        #    "btype": "NxAwait"
        #    "creationUnixtime": Float
        #}
        if behavior["btype"] == "NxAwait" then
            return nil # it's being destroyed
        end

        raise "I do not know how to perform done for behaviour: #{behaviour}"
    end

    # TxBehaviour::doneBehaviours(behaviours: Array[TxBehaviour]) -> Array[TxBehaviour]
    def self.doneBehaviours(behaviours)
        behaviours
            .map{|behaviour| TxBehaviour::doneBehaviour(behaviour) }
            .compact
    end
end
