#!/usr/bin/ruby

# encoding: UTF-8

require 'json'
# JSON.pretty_generate(object)

require 'date'
require 'colorize'
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'time'

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'find'
require 'drb/drb'
require 'thread'

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/YmirEstate.rb"
=begin
    YmirEstate::ymirFilepathEnumerator(pathToYmir)
    YmirEstate::locationBasenameToYmirLocationOrNull(pathToYmir, basename)
    YmirEstate::makeNewYmirLocationForBasename(pathToYmir, basename)
        # If base name is meant to be the name of a folder then folder itself 
        # still need to be created. Only the parent is created.
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

# --------------------------------------------------------------------

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Starburst/Starburst.rb"

class Starburst

    # Starburst::pathToStarburstFolders()
    def self.pathToStarburstFolders()
        "/Users/pascal/Galaxy/Orbital/Starburst"
    end

    # Starburst::foldernames()
    def self.foldernames()
        Dir.entries(Starburst::pathToStarburstFolders())
            .select{|filename| filename.include?("|") }
            .sort
    end

    # Starburst::folderpaths()
    def self.folderpaths()
        Starburst::foldernames().map{|filename| "#{Starburst::pathToStarburstFolders()}/#{filename}" }
    end

    # Starburst::locationnameToIndexInteger(name_)
    def self.locationnameToIndexInteger(name_)
        name_[0, 3].to_i
    end

    # Starburst::locationToIndexInteger(location)
    def self.locationToIndexInteger(location)
        Starburst::locationnameToIndexInteger(File.basename(location))
    end

    # Starburst::maxIndexAtStarBurstFolder(folderpath)
    def self.maxIndexAtStarBurstFolder(folderpath)
        indices = LucilleCore::locationsAtFolder(folderpath)
            .map{|location| Starburst::locationToIndexInteger(location) }
        indices << 100
        indices.max
    end

    # Starburst::starburstNameToFolderpath(sname)
    def self.starburstNameToFolderpath(sname)
        "#{Starburst::pathToStarburstFolders()}/#{sname}"
    end

    # Starburst::maxIndexAtStarburstName(sname)
    def self.maxIndexAtStarburstName(sname)
        Starburst::maxIndexAtStarBurstFolder(Starburst::starburstNameToFolderpath(sname))
    end

    # Starburst::interactivelyMakeNewFolderReturnFolderpath()
    def self.interactivelyMakeNewFolderReturnFolderpath()
        domain = LucilleCore::selectEntityFromListOfEntitiesOrNull("domain", ["Personal", "The Guardian"])
        if domain.nil? then
            domain = LucilleCore::askQuestionAnswerAsString("domain? : ")
        end
        foldername = LucilleCore::askQuestionAnswerAsString("Foldername? : ")
        foldernamexp = "#{Time.now.utc.iso8601[0,10]} | #{domain} | #{foldername}"
        folderpathxp = "#{Starburst::pathToStarburstFolders()}/#{foldernamexp}"
        FileUtils.mkdir(folderpathxp)
        folderpathxp
    end

end
