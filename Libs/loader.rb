
# encoding: UTF-8

require 'json'
# JSON.pretty_generate(object)

require 'date'
require 'time'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(5) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

require 'colorize'

require 'sqlite3'

require 'find'

require 'thread'

require 'colorize'

require 'drb/drb'

# ------------------------------------------------------------

checkLocation = lambda{|location|
    if !File.exist?(location) then
        puts "I cannot see location: #{location.green}"
        exit
    end
} 

checkLocation.call("#{ENV['HOME']}/x-space/xcache-v1-days")
checkLocation.call("#{ENV['HOME']}/Galaxy/DataBank/Stargate-Config.json")
checkLocation.call("#{ENV['HOME']}/Galaxy/DataHub/Lucille-Ruby-Libraries")

# ------------------------------------------------------------

require_relative "LucilleCore.rb"

require_relative "XCache.rb"
=begin
    XCache::set(key, value)
    XCache::getOrNull(key)
    XCache::getOrDefaultValue(key, defaultValue)
    XCache::destroy(key)

    XCache::setFlag(key, flag)
    XCache::getFlag(key)

    XCache::filepath(key)
=end

require_relative "AionCore.rb"
=begin

The operator is an object that has meet the following signatures

    .putBlob(blob: BinaryData) : Hash
    .filepathToContentHash(filepath) : Hash
    .readBlobErrorIfNotFound(nhash: Hash) : BinaryData
    .datablobCheck(nhash: Hash): Boolean

class Elizabeth

    def initialize()

    end

    def putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        XCache::set("SHA256-#{Digest::SHA256.hexdigest(blob)}", blob)
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = XCache::getOrNull(nhash)
        raise "[Elizabeth error: fc1dd1aa]" if blob.nil?
        blob
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end

end

AionCore::commitLocationReturnHash(operator, location)
AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)

AionFsck::structureCheckAionHashRaiseErrorIfAny(operator, nhash)

=end

require_relative "Config.rb"

# ------------------------------------------------------------

require_relative "Anniversaries.rb"
require_relative "Atlas.rb"

require_relative "Bank.rb"

require_relative "Catalyst.rb"
require_relative "CommonUtils.rb"
require_relative "CatalystSearch.rb"
require_relative "CoreDataRefStrings.rb"
require_relative "Cubes.rb"

require_relative "DoNotShowUntil.rb"
# DoNotShowUntil1::setUnixtime(item["uuid"], unixtime)
# DoNotShowUntil1::isVisible(item)
require_relative "Dx8Units.rb"
require_relative "Desktop"
require_relative "DropBox.rb"
require_relative "Dives.rb"
require_relative "DataCenter.rb"

require_relative "Engined.rb"

require_relative "Fsck.rb"
require_relative "FileSystemReferences.rb"

require_relative "Galaxy.rb"

require_relative "Interpreting.rb"
require_relative "ItemStore.rb"

require_relative "MainUserInterface.rb"
require_relative "CommandsAndInterpreters.rb"

require_relative "InMemoryCache.rb"

require_relative "NxBalls.rb"
require_relative "NxTasks.rb"
require_relative "NxLambdas.rb"
require_relative "NxStrats.rb"
require_relative "NxListings.rb"
require_relative "NxOndate.rb"
require_relative "NxMonitors.rb"
require_relative "NxMissions.rb"
require_relative "NxBackups.rb"

require_relative "Ox1.rb"
require_relative "OpenCycles.rb"

require_relative "ProgrammableBooleans.rb"
require_relative "PolyActions.rb"
require_relative "PolyFunctions.rb"
require_relative "PhysicalTargets.rb"
require_relative "Prefix.rb"

require_relative "SectionsType0141.rb"

require_relative "TmpSkip1.rb"
require_relative "TxCores.rb"
require_relative "Transmutations.rb"
require_relative "TxPayload.rb"

require_relative "Waves.rb"

# ------------------------------------------------------------
