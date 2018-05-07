#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require 'json'

=begin

  -- reading the string and building the object
     dataset = IO.read($dataset_location)
     JSON.parse(dataset)

  -- printing the string
     file.puts JSON.pretty_generate(dataset)

=end

require 'date'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'find'

require_relative "Commons.rb"

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

require "/Galaxy/local-resources/Ruby-Libraries/FIFOQueue.rb"
=begin
    # The set of values that we support is whatever that can be json serialisable.
    FIFOQueue::size(repositorylocation or nil, queueuuid)
    FIFOQueue::values(repositorylocation or nil, queueuuid)
    FIFOQueue::push(repositorylocation or nil, queueuuid, value)
    FIFOQueue::getFirstOrNull(repositorylocation or nil, queueuuid)
    FIFOQueue::takeFirstOrNull(repositorylocation or nil, queueuuid)
=end

require_relative "x-laniakea.rb"

# -------------------------------------------------------------------------------------

# XLaniakeaKiller::getCatalystObjects()

class XLaniakeaKiller
    def self.getCatalystObjects()
        currentCount1 = FIFOQueue::size(nil, "2477F469-6A18-4CAF-838A-E05703585A28")
        KillersCurvesManagement::shiftCurveIfOpportunity("/Galaxy/DataBank/Catalyst/Killers-Curves/XLaniakea", currentCount1)
        curve1 = KillersCurvesManagement::getCurve("/Galaxy/DataBank/Catalyst/Killers-Curves/XLaniakea")
        idealCount1 = KillersCurvesManagement::computeIdealCountFromCurve(curve1)
        metric1 = KillersCurvesManagement::computeMetric(currentCount1, idealCount1) 
        targetobject = XLaniakea::getCatalystObjects().first
        if targetobject then
            targetobject["metric"] = metric1
            targetobject["announce"] = "(x-laniakea killer) #{targetobject["announce"]}"
            [ targetobject ]
        else
            [
                {
                    "uuid" => SecureRandom.hex(4),
                    "metric" => metric1,
                    "announce" => "-> x-laniakea killer could not retrieve a targetuuid",
                    "commands" => [],
                    "command-interpreter" => lambda{|object, command| }
                }
            ]
        end
    end
end

