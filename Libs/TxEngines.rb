# encoding: UTF-8

class TxEngines

    # TxEngines::makeEngine(estimatedDurationInHours, deadlineInRelativeDays)
    def self.makeEngine(estimatedDurationInHours, deadlineInRelativeDays)
        {
            "uuid"                        => SecureRandom.uuid,
            "mikuType"                    => "TxEngine",
            "start-unixtime"              => Time.new.to_i,
            "estimated-duration-in-hours" => estimatedDurationInHours,
            "deadline-in-relative-days"   => deadlineInRelativeDays
        }
    end

    # TxEngines::interactivelyMakeEngine()
    def self.interactivelyMakeEngine()
        uuid = SecureRandom.uuid
        estimatedDurationInHours = LucilleCore::askQuestionAnswerAsString("estimated duration in hours: ").to_f
        deadlineInRelativeDays = LucilleCore::askQuestionAnswerAsString("deadline in relative days: ").to_f
        TxEngines::makeEngine(estimatedDurationInHours, deadlineInRelativeDays)
    end

    # TxEngines::setItemEngine(item) # item (updated)
    def self.setItemEngine(item)
        engine = TxEngines::interactivelyMakeEngine()
        DarkEnergy::patch(item["uuid"], "engine", engine)
        item["engine"] = engine
        item
    end

    # TxEngines::metric(engine)
    def self.metric(engine)
        t1 = engine["start-unixtime"]
        t2 = Time.new.to_i
        t3 = t2 + engine["estimated-duration-in-hours"]*3600 - Bank::getValue(engine["uuid"])
        t4 = t1 + engine["deadline-in-relative-days"]*86400
        return 2.2 if (t2 >= t4) # engine passed deadline
        return 1.4 if (engine["estimated-duration-in-hours"]*3600 <= Bank::getValue(engine["uuid"])) # meaning t3 <= t2
        0.5 * (t3 - t2).to_f/(t4 - t2)
    end

    # TxEngines::engineSuffix(item)
    def self.engineSuffix(item)
        Memoize::evaluate(
            "da4568a3-3bdf-4466-b502-0f60c963e76a:#{item["uuid"]}",
            lambda { 
                return "" if item["engine"].nil?
                engine = item["engine"]

                left = engine["estimated-duration-in-hours"]*3600 - Bank::getValue(engine["uuid"])
                timeToDeadline = (engine["start-unixtime"] + engine["deadline-in-relative-days"]*86400) - Time.new.to_i

                " (🚗, metric: #{TxEngines::metric(engine).round(2)}; #{(left.to_f/3600).round(2)} hours left over #{(timeToDeadline.to_f/86400).round(2)} days)"
            },
            600
        )
    end

    # TxEngines::items_with_an_engine()
    def self.items_with_an_engine()
        Catalyst::catalystItems()
            .select{|item| item["engine"] }
    end

    # TxEngines::listingItems()
    def self.listingItems()
        items = Memoize::evaluate(
            "8cf20b38-ab0d-4bab-b541-07fe27950d2c",
            lambda { 
                    TxEngines::items_with_an_engine()
                        .sort{|item| 
                            Memoize::evaluate(
                                "034c49e8-5b41-48d9-af73-bfbdd2bbdbbe:#{item["engine"]["uuid"]}",
                                lambda { TxEngines::metric(item["engine"]) },
                                600
                            )
                        }
                        .first(10)
            },
            3600
        ).map{|item| DarkEnergy::itemOrNull(item["uuid"]) }

        items
            .sort{|item| 
                Memoize::evaluate(
                    "034c49e8-5b41-48d9-af73-bfbdd2bbdbbe:#{item["engine"]["uuid"]}",
                    lambda { TxEngines::metric(item["engine"]) },
                    600
                )
            }
    end
end
