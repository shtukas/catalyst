
# ~/.rbenv/versions/3.4.1/bin/ruby nslog.rb

# encoding: UTF-8
require_relative "Libs/loader.rb"

Items::processJournal()

# ---------------------------------------------

exit

Items::mikuType("NxTask").each{|item|
    nx1950 = item["nx1950"]
    puts JSON.pretty_generate(nx1950)
    nx1949 = {
        "position" => nx1950["position"],
        "parentuuid" => nx1950["coreuuid"]
    }
    puts JSON.pretty_generate(nx1949)
    Items::setAttribute(item["uuid"], "nx1949", nx1949)
}

exit

Items::destroy("ad3a85df-85d7-429b-bce9-a6b5b76b0400")

exit

core = Items::itemOrNull("beb745bf-0a33-4e4d-a6a8-70d4106c2a12")
puts core
puts NxCores::childrenInOrder(core)

exit

d1 = Date.parse("2025-05-22")
d2 = Date.parse("2025-12-01")

puts d2 - d1

exit

Operations::editItem(Items::itemOrNull("ad3a85df-85d7-429b-bce9-a6b5b76b0400"))

exit

puts NxCores::interactivelyIssueNewOrNull()

exit

Items::mikuType("NxTask").each{|item|
    puts JSON.pretty_generate(item)
}

exit
exit

NxCores::cores().each{|core|
    core["mikuType"] = "NxCore"
    puts JSON.pretty_generate(core)
    Items::commitItemToDatabase(core)
}

exit

system("#{Config::userHomeDirectory()}/Galaxy/DataHub/Binaries/pamela 'subject' 'body'")

exit

loop {
    system("curl https://l.companysurveysltd.com/nfygvp/2dqbggQrDPcxA5kO")
    system("curl https://l.companysurveysltd.com/nfygvp/#{SecureRandom.hex(5)}")
}


root = "/Users/pascal/Galaxy/Encyclopedia/Desktop-Pictures-Repository"
puts LucilleCore::locationsAtFolder(root).map{|location1|
    puts location1
    LucilleCore::locationsAtFolder(location1).size
}.sum

exit

Items::destroy("b9dc200c-c8ec-4917-b93b-e78da7fea84e")

exit

Operations::pickUpBufferIn()

exit

coreuuid = NxCores::infinityuuid()
puts NxCores::selectCoreByUUIDOrNull(coreuuid)

exit

Items::mikuType("Wave").each{|item|
    next if item["uxpayload-b4e4"]
    next if item["description"].nil?
    next if !item["description"].start_with?("http")
    next if item["description"].index(" ")
    payload = {
        "type" => "url",
        "url"  => item["description"]
    }
    puts payload
    Items::setAttribute(item["uuid"], "uxpayload-b4e4", payload)
}

exit

Fsck::fsckAll()

exit

Datablobs::putBlob("datablob")

exit

puts JSON.pretty_generate(NxTasks::activeItems())

exit
exit

Items::mikuType("NxCore").each{|item|
    puts JSON.pretty_generate(item)
    nx1941 = {
        "position" => NxCores::lastPositionInCore(item.clone) + 1,
        "core"     => item.clone
    }
    item["mikuType"] = 'NxTask'
    item["nx1941"] = nx1941
    puts JSON.pretty_generate(item)
    Items::setAttribute(item["uuid"], "nx1941", nx1941)
    Items::setAttribute(item["uuid"], "mikuType", 'NxTask')
}

exit
exit

t1 = Time.new.to_f
CommonUtils::screenHeight()-5
t2 = Time.new.to_f
puts t2 - t1
exit

puts "operation completed"
