
class EventTimelineReducer

    # EventTimelineReducer::root()
    def self.root()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Events"
    end

    # EventTimelineReducer::timelineFilepathsReverseEnumerator()
    def self.timelineFilepathsReverseEnumerator()
        Enumerator.new do |filepaths|
            LucilleCore::locationsAtFolder(EventTimelineReducer::root()).sort.reverse.each{|locationYear|
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

    # EventTimelineReducer::extractor1(cachePrefix, filepathEnumerator, filepaths)
    def self.extractor1(cachePrefix, filepathEnumerator, filepaths)
        # extractor1 returns the smallest sequence of filepaths such that the first filepath
        # has data recorded against it. Otherwise we return the entire sequence of filepaths
        begin 
            filepath = filepathEnumerator.next()
        rescue
            return filepaths
        end
        data = XCache::getOrNull("#{cachePrefix}:#{filepath}")
        if data then
            return [filepath] + filepaths
        end
        return EventTimelineReducer::extractor1(cachePrefix, filepathEnumerator, [filepath] + filepaths)
    end

    # EventTimelineReducer::reducer1(cachePrefix, combinator, data, filepaths)
    def self.reducer1(cachePrefix, combinator, data, filepaths)
        return data if filepaths.empty?
        filepaths = filepaths.clone
        filepath = filepaths.shift()
        event = JSON.parse(IO.read(filepath))
        data = combinator.call(data, event)
        XCache::set("#{cachePrefix}:#{filepath}", JSON.generate(data))
        EventTimelineReducer::reducer1(cachePrefix, combinator, data, filepaths)
    end

    # EventTimelineReducer::extract(cachePrefix, unit, combinator)
    # unit: data
    # combinator: (data, event) -> event
    def self.extract(cachePrefix, unit, combinator)
        filepathEnumerator = EventTimelineReducer::timelineFilepathsReverseEnumerator()
        filepaths = EventTimelineReducer::extractor1(cachePrefix, filepathEnumerator, [])
        return unit if filepaths.empty?
        data = XCache::getOrNull("#{cachePrefix}:#{filepaths[0]}")
        if data then
            EventTimelineReducer::reducer1(cachePrefix, combinator, data, filepaths)
        else
            EventTimelineReducer::reducer1(cachePrefix, combinator, unit, filepaths)
        end
    end
end
