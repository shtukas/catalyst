

$trace68be8052a3bf = nil

class EventTimelineReader

    # EventTimelineReader::eventsTimeline()
    def self.eventsTimeline()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Events/Timeline"
    end

    # EventTimelineReader::timelineFilepathsReverseEnumerator()
    def self.timelineFilepathsReverseEnumerator()
        Enumerator.new do |filepaths|
            LucilleCore::locationsAtFolder(EventTimelineReader::eventsTimeline()).sort.reverse.each{|locationYear|
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

    # EventTimelineReader::snakeMaker(cachePrefix, filepathEnumerator) # Array[filepath]
    def self.snakeMaker(cachePrefix, filepathEnumerator) # Array[filepath]
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
                puts "snakeMaker: cachePrefix: #{cachePrefix} / collecting: #{filepath}".yellow
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

    # EventTimelineReader::snakeMarker(cachePrefix, combinator, data, filepaths)
    def self.snakeMarker(cachePrefix, combinator, data, filepaths)
        loop {
            return data if filepaths.empty?
            filepath = filepaths.shift
            event = JSON.parse(IO.read(filepath))
            data = combinator.call(data, event)
            puts "snakeMarker: cachePrefix: #{cachePrefix} / storing data @ #{filepath}".yellow
            XCache::set("#{cachePrefix}:#{filepath}", JSON.generate(data))
        }
    end

    # EventTimelineReader::extract(cachePrefix, unit, combinator)
    # unit: data
    # combinator: (data, event) -> event
    def self.extract(cachePrefix, unit, combinator)
        filepathEnumerator = EventTimelineReader::timelineFilepathsReverseEnumerator()
        filepaths = EventTimelineReader::snakeMaker(cachePrefix, filepathEnumerator)
        return unit if filepaths.empty?
        data = XCache::getOrNull("#{cachePrefix}:#{filepaths[0]}")
        if data then
            data = JSON.parse(data)
        else
            data = unit
        end
        EventTimelineReader::snakeMarker(cachePrefix, combinator, data, filepaths)
    end

    # EventTimelineReader::lastTraceForCaching()
    def self.lastTraceForCaching()
        begin
            if $trace68be8052a3bf.nil? then
                $trace68be8052a3bf = EventTimelineReader::timelineFilepathsReverseEnumerator().next()
            end
            $trace68be8052a3bf
        rescue
            "967016d2-d506-44e9-986b-bf7f91971009"
        end
    end
end
