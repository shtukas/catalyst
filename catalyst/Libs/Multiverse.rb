
# encoding: UTF-8

class Multiverse

    # Multiverse::universes()
    def self.universes()
        ["backlog", "work"]
    end

    # Multiverse::interactivelySelectUniverseOrNull()
    def self.interactivelySelectUniverseOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("universe", Multiverse::universes())
    end

    # Multiverse::interactivelySelectUniverse()
    def self.interactivelySelectUniverse()
        universe = LucilleCore::selectEntityFromListOfEntitiesOrNull("universe", Multiverse::universes())
        return Multiverse::interactivelySelectUniverse() if universe.nil?
        universe
    end
end

class UniverseStorage

    # UniverseStorage::setUniverse(universe or null)
    def self.setUniverse(universe)
        if universe.nil? then
            XCache::destroy("5117D42F-8542-4D74-A219-47AF3C58F22B")
            return
        end
        XCache::set("5117D42F-8542-4D74-A219-47AF3C58F22B", universe)
    end

    # UniverseStorage::getUniverseOrNull()
    def self.getUniverseOrNull()
        XCache::getOrNull("5117D42F-8542-4D74-A219-47AF3C58F22B")
    end

    # UniverseStorage::interactivelySetUniverse()
    def self.interactivelySetUniverse()
        universe = Multiverse::interactivelySelectUniverse()
        UniverseStorage::setUniverse(universe)
    end
end

class UniverseMonitor

    # UniverseMonitor::naturalUniverseForThisTime()
    def self.naturalUniverseForThisTime()
        if [1, 2, 3, 4, 5].include?(Time.new.wday) and Time.new.hour >= 9 and Time.new.hour < 16 then
            "work"
        else
            "backlog"
        end
    end

    # UniverseMonitor::switchProcessor()
    def self.switchProcessor()
        natural = UniverseMonitor::naturalUniverseForThisTime()
        if UniverseStorage::getUniverseOrNull() != natural then
            UniverseStorage::setUniverse(natural)
        end
    end
end
