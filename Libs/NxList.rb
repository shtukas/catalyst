
class NxList

    # NxList::dataManagement()
    def self.dataManagement()
        return if !Config::isPrimaryInstance()
        if NxHeads::items().size < 3 then
            item1 = NxTails::getFrontElementOrNull(nil)
            item2 = NxTails::getEndElementOrNull(nil)
            [item1, item2]
                .compact
                .each{|item|
                    puts "Promoting item from tail to top: #{JSON.pretty_generate(item)}"
                    newuuid = SecureRandom.uuid
                    newitem = item.clone
                    newitem["uuid"] = newuuid
                    newitem["mikuType"]  = "NxHead"
                    newitem["position"]  = NxHeads::endPositionNext()
                    newitem["boarduuid"] = nil
                    NxHeads::commit(newitem)
                    control = NxHeads::getItemOfNull(newuuid)
                    if control.nil? then
                        raise "(error: 1731ead9-7ebf-450c-89ba-914c734d4e2c) while processing item: #{JSON.pretty_generate(item)}"
                    end
                    NxTails::destroy(item["uuid"])
                }
        end
    end
end