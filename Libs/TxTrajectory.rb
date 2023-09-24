
class TxTrajectory

    # TxTrajectory::ratio(trajectory)
    def self.ratio(trajectory)
        daysSinceStart = (Time.new.to_i - trajectory["start"]).to_f/86400
        daysSinceStart.to_f/trajectory["horizonInDays"]
    end

    # TxTrajectory::interactivelyMakeOrNull()
    def self.interactivelyMakeOrNull()
        horizon = LucilleCore::askQuestionAnswerAsString("horizonInDays: ").to_f
        {
            "start"         => Time.new.to_f,
            "horizonInDays" => horizon
        }
    end

    # TxTrajectory::prefix(item)
    def self.prefix(item)
        return "" if item["traj-2349"].nil?
        "(trajec: #{"%5.2f" % (100*TxTrajectory::ratio(item["traj-2349"]))} %) ".green
    end
end
