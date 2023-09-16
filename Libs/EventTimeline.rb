

$liveTrace68be8052a3bf = SecureRandom.hex

class EventTimelineReader

    # EventTimelineReader::eventsTimelineLocation()
    def self.eventsTimelineLocation()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Events/Timeline"
    end

    # EventTimelineReader::firstFilepathOrNull()
    def self.firstFilepathOrNull()
        LucilleCore::locationsAtFolder(EventTimelineReader::eventsTimelineLocation()).sort.each{|locationYear|
            LucilleCore::locationsAtFolder(locationYear).sort.each{|locationMonth|
                LucilleCore::locationsAtFolder(locationMonth).sort.each{|locationDay|
                    LucilleCore::locationsAtFolder(locationDay).sort.each{|locationIndexFolder|
                        LucilleCore::locationsAtFolder(locationIndexFolder).sort.each{|eventfilepath|
                            return eventfilepath
                        }
                        if LucilleCore::locationsAtFolder(locationIndexFolder).empty? then
                            LucilleCore::removeFileSystemLocation(locationIndexFolder)
                        end
                    }
                    if LucilleCore::locationsAtFolder(locationDay).empty? then
                        LucilleCore::removeFileSystemLocation(locationDay)
                    end
                }
                if LucilleCore::locationsAtFolder(locationMonth).empty? then
                    LucilleCore::removeFileSystemLocation(locationMonth)
                end
            }
            if LucilleCore::locationsAtFolder(locationYear).empty? then
                LucilleCore::removeFileSystemLocation(locationYear)
            end
        }
        nil
    end

    # EventTimelineReader::timelineFilepathsEnumerator()
    def self.timelineFilepathsEnumerator()
        Enumerator.new do |filepaths|
            LucilleCore::locationsAtFolder(EventTimelineReader::eventsTimelineLocation()).sort.each{|locationYear|
                LucilleCore::locationsAtFolder(locationYear).sort.each{|locationMonth|
                    LucilleCore::locationsAtFolder(locationMonth).sort.each{|locationDay|
                        LucilleCore::locationsAtFolder(locationDay).sort.each{|locationIndexFolder|
                            LucilleCore::locationsAtFolder(locationIndexFolder).sort.each{|eventfilepath|
                                filepaths << eventfilepath
                            }
                        }
                    }
                }
            }
        end
    end

    # EventTimelineReader::timelineFilepathsReverseEnumerator()
    def self.timelineFilepathsReverseEnumerator()
        Enumerator.new do |filepaths|
            LucilleCore::locationsAtFolder(EventTimelineReader::eventsTimelineLocation()).sort.reverse.each{|locationYear|
                LucilleCore::locationsAtFolder(locationYear).sort.reverse.each{|locationMonth|
                    LucilleCore::locationsAtFolder(locationMonth).sort.reverse.each{|locationDay|
                        LucilleCore::locationsAtFolder(locationDay).sort.reverse.each{|locationIndexFolder|
                            LucilleCore::locationsAtFolder(locationIndexFolder).sort.reverse.each{|eventfilepath|
                                filepaths << eventfilepath
                            }
                        }
                    }
                }
            }
        end
    end

    # EventTimelineReader::snakeMake(cachePrefix, filepathEnumerator) # Array[filepath]
    def self.snakeMake(cachePrefix, filepathEnumerator) # Array[filepath]
        # extractor1 returns the smallest sequence of filepaths such that the
        # first filepath has data recorded against it. Otherwise we return the
        # entire sequence of filepaths.
        # snake: [*][-][-][-][-][-]
        # snake: [-][-][-][-][-][-]
        # snake: (empty)
        filepaths = []
        loop {
            begin 
                filepath = filepathEnumerator.next()
                #puts "cachePrefix: #{cachePrefix} / collecting: #{filepath}".yellow
                data = XCache::getOrNull("#{cachePrefix}:#{filepath}")
                if data then
                    return [filepath] + filepaths
                end
                filepaths = [filepath] + filepaths
            rescue
                return filepaths
            end
        }
    end

    # EventTimelineReader::snakeWalk(cachePrefix, combinator, data, filepaths)
    def self.snakeWalk(cachePrefix, combinator, data, filepaths)
        loop {
            return data if filepaths.empty?
            filepath = filepaths.shift
            event = JSON.parse(IO.read(filepath))
            data = combinator.call(data, event)
            #puts "cachePrefix: #{cachePrefix} / storing data @ #{filepath}".yellow
            XCache::set("#{cachePrefix}:#{filepath}", JSON.generate(data))
        }
    end

    # EventTimelineReader::extract(cachePrefix, unit: lambda: () -> unitdata, combinator)
    # unit: data
    # combinator: (data, event) -> event
    def self.extract(cachePrefix, unit, combinator)
        filepathEnumerator = EventTimelineReader::timelineFilepathsReverseEnumerator()
        filepaths = EventTimelineReader::snakeMake(cachePrefix, filepathEnumerator)
        return unit if filepaths.empty?
        data = XCache::getOrNull("#{cachePrefix}:#{filepaths[0]}")
        if data then
            data = JSON.parse(data)
        else
            data = unit.call()
        end
        EventTimelineReader::snakeWalk(cachePrefix, combinator, data, filepaths)
    end

    # EventTimelineReader::traceForCachingCore()
    def self.traceForCachingCore()
        EventTimelineReader::timelineFilepathsEnumerator()
            .reduce("") {|trace, filepath1|
                Digest::SHA1.hexdigest("#{trace}:#{filepath1}")
            }
    end

    # EventTimelineReader::liveTraceForCaching()
    def self.liveTraceForCaching()
        $liveTrace68be8052a3bf
    end

    # EventTimelineReader::issueNewRandomTraceForCaching()
    def self.issueNewRandomTraceForCaching()
        $liveTrace68be8052a3bf = SecureRandom.hex
    end

    # EventTimelineReader::issueNewFSComputedTraceForCaching()
    def self.issueNewFSComputedTraceForCaching()
        $liveTrace68be8052a3bf = EventTimelineReader::timelineFilepathsEnumerator()
            .reduce("") {|trace, filepath1|
                Digest::SHA1.hexdigest("#{trace}:#{filepath1}")
            }
    end
end

class EventTimelineReducers

    # EventTimelineReducers::doNotShowUntil(data, event)
    def self.doNotShowUntil(data, event)
        if event["eventType"] == "DoNotShowUntil" then
            data[event["targetId"]] = event["unixtime"]
        end
        if event["eventType"] == "DoNotShowUntil2" then
            targetId = event["payload"]["targetId"]
            unixtime = event["payload"]["unixtime"]
            data[targetId] = unixtime
        end
        data
    end

    # EventTimelineReducers::items(data, event)
    def self.items(data, event)
        if event["eventType"] == "ItemInit" then
            uuid = event["payload"]["uuid"]
            mikuType = event["payload"]["mikuType"]
            data[uuid] = {
                "uuid"     => uuid,
                "mikuType" => mikuType
            }
        end
        if event["eventType"] == "ItemAttributeUpdate" then
            itemuuid = event["payload"]["itemuuid"]
            attname  = event["payload"]["attname"]
            attvalue = event["payload"]["attvalue"]
            if data[itemuuid].nil? then
                data[itemuuid] = {
                    "uuid" => itemuuid
                }
            end
            data[itemuuid][attname] = attvalue
        end
        if event["eventType"] == "ItemDestroy" then
            data.delete(event["itemuuid"])
        end
        if event["eventType"] == "ItemDestroy2" then
            data.delete(event["payload"]["uuid"])
        end
        data
    end
end

class EventTimelineDatasets

    # EventTimelineDatasets::doNotShowUntil() # Map[targetId, unixtime]
    def self.doNotShowUntil()
        trace = EventTimelineReader::liveTraceForCaching()
        dataset = InMemoryCache::getOrNull("3e9efc9a-785b-44f7-8b87-7dbe92eee8df:#{trace}")
        if dataset then
            return dataset
        end

        cachePrefix = "DoNotShowUntil-491E-A2AB-6CB93205787C"
        unit = lambda{
            JSON.parse(IO.read("#{Config::pathToGalaxy()}/DataHub/catalyst/Events/Units/DoNotShowUntil.json"))
        }
        combinator = lambda{|data, event| EventTimelineReducers::doNotShowUntil(data, event) }
        dataset = EventTimelineReader::extract(cachePrefix, unit, combinator)

        InMemoryCache::set("3e9efc9a-785b-44f7-8b87-7dbe92eee8df:#{trace}", dataset)
        dataset
    end

    # EventTimelineDatasets::catalystItems() # Map[uuid, item]
    def self.catalystItems()
        trace = EventTimelineReader::liveTraceForCaching()
        dataset = InMemoryCache::getOrNull("140a1b12-9a9e-448f-a5e1-47c1270de830:#{trace}")
        if dataset then
            return dataset
        end

        cachePrefix = "ITEMS-29DCCA9B-6EC4"
        unit = lambda {
            JSON.parse(IO.read("#{Config::pathToGalaxy()}/DataHub/catalyst/Events/Units/Items.json"))
        }
        combinator = lambda{|data, event| EventTimelineReducers::items(data, event) }
        dataset = EventTimelineReader::extract(cachePrefix, unit, combinator)

        InMemoryCache::set("140a1b12-9a9e-448f-a5e1-47c1270de830:#{trace}", dataset)
        dataset
    end
end

class EventTimelineMaintenance

    # EventTimelineMaintenance::getFirstEventOrNull()
    def self.getFirstEventOrNull()
        eventFilepath = EventTimelineReader::firstFilepathOrNull()
        return nil if eventFilepath.nil?
        JSON.parse(IO.read(eventFilepath))
    end

    # EventTimelineMaintenance::shortenOnce()
    def self.shortenOnce()
        return if !Config::isPrimaryInstance()

        eventFilepath = EventTimelineReader::firstFilepathOrNull()
        return if eventFilepath.nil?

        puts "shortening at #{eventFilepath}"
        event = JSON.parse(IO.read(eventFilepath))
        puts "event: #{JSON.pretty_generate(event)}"

        f1 = "#{Config::pathToGalaxy()}/DataHub/catalyst/Events/Units/DoNotShowUntil.json"
        f2 = "#{Config::pathToGalaxy()}/DataHub/catalyst/Events/Units/Items.json"

        # DoNotShowUntil
        data1 = JSON.parse(IO.read(f1))
        data1 = EventTimelineReducers::doNotShowUntil(data1, event)

        # Items
        data2 = JSON.parse(IO.read(f2))
        data2 = EventTimelineReducers::items(data2, event)

        File.open(f1, "w"){|f| f.puts(JSON.pretty_generate(data1))}
        File.open(f2, "w"){|f| f.puts(JSON.pretty_generate(data2))}

        puts "deleting event #{eventFilepath}"
        FileUtils.rm(eventFilepath)
    end

    # EventTimelineMaintenance::publishPing()
    def self.publishPing()
        filepath = "#{Config::pathToGalaxy()}/DataHub/catalyst/Events/Pings/#{Config::thisInstanceId()}.unixtime"
        File.open(filepath, "w"){|f| f.puts(Time.new.to_i) }
    end

    # EventTimelineMaintenance::getLowerPing()
    def self.getLowerPing()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/catalyst/Events/Pings")
            .select{|location| File.basename(location)[-9, 9] == ".unixtime" }
            .map{|filepath| IO.read(filepath).strip.to_i }
            .min
    end

    # EventTimelineMaintenance::shortenToLowerPing()
    def self.shortenToLowerPing()
        return if !Config::isPrimaryInstance()
        loop {
            event = EventTimelineMaintenance::getFirstEventOrNull()
            break if event.nil?
            break if event["unixtime"] > EventTimelineMaintenance::getLowerPing()
            EventTimelineMaintenance::shortenOnce()
        }
    end

    # EventTimelineMaintenance::rewriteHistory()
    def self.rewriteHistory()
        EventTimelineReader::timelineFilepathsEnumerator().reduce("") {|trace, filepath1|
            filecontents = IO.read(filepath1)
            trace = Digest::SHA1.hexdigest("#{trace}:#{filecontents}")
            filename1 = File.basename(filepath1)
            filename2 = "#{filename1[0, 22]}-#{trace}.json"
            filepath2 = "#{File.dirname(filepath1)}/#{filename2}"
            if filepath1 != filepath2 then
                puts filepath1
                puts filepath2
                LucilleCore::pressEnterToContinue()
                FileUtils.mv(filepath1, filepath2)
            end
            trace
        }
    end
end
