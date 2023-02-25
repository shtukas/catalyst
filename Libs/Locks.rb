# encoding: UTF-8

class Locks

    # Locks::lock(uuid, domain)
    def self.lock(uuid, domain)
        N2KVStore::set("Locks:#{uuid}", domain)
    end

    # Locks::isLocked(uuid)
    def self.isLocked(uuid)
        !N2KVStore::getOrNull("Locks:#{uuid}").nil?
    end

    # Locks::locknameOrNull(uuid)
    def self.locknameOrNull(uuid)
        N2KVStore::getOrNull("Locks:#{uuid}")
    end

    # Locks::unlock(uuid)
    def self.unlock(uuid)
        N2KVStore::destroy("Locks:#{uuid}")
    end
end
