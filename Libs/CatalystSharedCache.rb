# encoding: utf-8

=begin
    CatalystSharedCache::set(key, value)
    CatalystSharedCache::getOrNull(key)
    CatalystSharedCache::getOrDefaultValue(key, defaultValue)
    CatalystSharedCache::destroy(key)

    CatalystSharedCache::setFlag(key, flag)
    CatalystSharedCache::getFlag(key)
=end

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf(dir)

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

require 'json'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'find'

# -----------------------------------------------------------------------------------

class CatalystSharedCache

    # CatalystSharedCache::filepath(key)
    def self.filepath(key)
        "#{ENV['HOME']}/Galaxy/DataHub/catalyst/shared-cache/#{Digest::SHA1.hexdigest(key)}.data"
    end

    # CatalystSharedCache::set(key, value)
    def self.set(key, value)
        filepath = CatalystSharedCache::filepath(key)
        File.open(filepath, 'w'){|f| f.puts(JSON.generate(value))}
    end

    # CatalystSharedCache::getOrNull(key)
    def self.getOrNull(key)
        filepath = CatalystSharedCache::filepath(key)
        return nil if !File.exist?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # CatalystSharedCache::getOrDefaultValue(key, defaultValue)
    def self.getOrDefaultValue(key, defaultValue)
        maybevalue = CatalystSharedCache::getOrNull(key)
        if maybevalue.nil? then
            defaultValue
        else
            maybevalue
        end
    end

    # CatalystSharedCache::destroy(key)
    def self.destroy(key)
        filepath = CatalystSharedCache::filepath(key)
        return if !File.exist?(filepath)
        FileUtils.rm(filepath)
    end

    # -----------------------------------------------------

    # CatalystSharedCache::setFlag(key, flag)
    def self.setFlag(key, flag)
        CatalystSharedCache::set(key, flag ? "true" : "false")
    end

    # CatalystSharedCache::getFlag(key)
    def self.getFlag(key)
        CatalystSharedCache::getOrNull(key) == "true"
    end
end
