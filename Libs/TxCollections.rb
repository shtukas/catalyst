# encoding: UTF-8

class TxCollections

    # TxCollections::setCollection(item, collection)
    def self.setCollection(item, collection)
        Items::setAttribute(item["uuid"], "collection-0901", collection)
    end

    # TxCollections::dropCollection(item)
    def self.dropCollection(item)
        return if item["collection-0901"].nil?
        Items::setAttribute(item["uuid"], "collection-0901", nil)
    end

    # TxCollections::getCollectionsFromItems(items)
    def self.getCollectionsFromItems(items)
        items.map{|item| item["collection-0901"] }.compact.uniq
    end

    # TxCollections::getCollectionItems(collection, items)
    def self.getCollectionItems(collection, items)
        items.select{|item| item["collection-0901"] == collection }
    end

    # TxCollections::listingItems(items)
    def self.listingItems(items)
        TxCollections::getCollectionsFromItems(items)
            .map{|collection|
                {
                    "uuid"     => "8008772b-496a-4ede-97d6-1eb329f9e283",
                    "mikuType" => "TxCollection",
                    "name"     => collection
                }
            }
    end

    # TxCollections::architectNewCollectionOrNull()
    def self.architectNewCollectionOrNull()
        collections = TxCollections::getCollectionsFromItems(Items::items())
        if collections.size > 0 then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("collection", collections)
            return option if option
        end
        collection = LucilleCore::askQuestionAnswerAsString("collection: ")
        return collection if collection.size > 0
        nil
    end

    # TxCollections::toString(txcollection)
    def self.toString(txcollection)
        "#{txcollection["name"]}"
    end

    # TxCollections::access(txcollection)
    def self.access(txcollection)
        l = lambda { TxCollections::getCollectionItems(txcollection["name"], Items::items()) }
        Catalyst::program3(l)
    end
end
