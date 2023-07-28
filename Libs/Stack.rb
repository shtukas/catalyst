
# encoding: UTF-8

class Stack

    # Stack::add(item)
    def self.add(item)
        uuids = JSON.parse(XCache::getOrDefaultValue("e4c5c8fb-ef80-4ff3-9ddd-a69304e1ec27", "[]"))
        uuids << item["uuid"]
        XCache::set("e4c5c8fb-ef80-4ff3-9ddd-a69304e1ec27", JSON.generate(uuids))
    end

    # Stack::items()
    def self.items()
        JSON.parse(XCache::getOrDefaultValue("e4c5c8fb-ef80-4ff3-9ddd-a69304e1ec27", "[]"))
            .map{|uuid| BladesGI::itemOrNull(uuid) }
            .compact
    end

    # Stack::flush()
    def self.flush()
        XCache::set("e4c5c8fb-ef80-4ff3-9ddd-a69304e1ec27", "[]")
    end

    # Stack::unstackItemsOntoParent(items, parent)
    def self.unstackItemsOntoParent(items, parent)
        items.reverse.each{|item|
            tx8 = Tx8s::make(parent["uuid"], Tx8s::newFirstPositionAtThisParent(parent))
            BladesGI::setAttribute2(item["uuid"], "parent", tx8)
        }
        Stack::flush()
    end

    # Stack::unstackOntoParentAttempt(parent)
    def self.unstackOntoParentAttempt(parent)
        items = Stack::items()
        return if items.empty?
        puts "stack:"
        items.each{|item|
            puts "- #{PolyFunctions::toString(item)}"
        }
        status = LucilleCore::askQuestionAnswerAsBoolean("confirm unstack into: #{PolyFunctions::toString(parent)} ")
        return if !status
        Stack::unstackItemsOntoParent(items, parent)
    end
end
