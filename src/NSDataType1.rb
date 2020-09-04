
# encoding: UTF-8

class NSDataType1

    # NSDataType1::issue()
    def self.issue()
        object = {
            "uuid"     => SecureRandom.uuid,
            "nyxNxSet" => "c18e8093-63d6-4072-8827-14f238975d04",
            "unixtime" => Time.new.to_f
        }
        NyxObjects2::put(object)
        object
    end

    # NSDataType1::objects()
    def self.objects()
        NyxObjects2::getSet("c18e8093-63d6-4072-8827-14f238975d04")
    end

    # NSDataType1::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects2::getOrNull(uuid)
    end

    # NSDataType1::toString(node, useCachedValue = true)
    def self.toString(node, useCachedValue = true)
        cacheKey = "645001e0-dec2-4e7a-b113-5c5e93ec0e69:#{node["uuid"]}"
        if useCachedValue then
            str = KeyValueStore::getOrNull(nil, cacheKey)
            return str if str
        end
        objects = Arrows::getTargetsForSource(node)
        if node["description"] then
            str = "[node] [#{node["uuid"][0, 4]}] #{node["description"]}"
            KeyValueStore::set(nil, cacheKey, str)
            return str
        end
        if node["description"].nil? and objects.size > 0 then
            str = "[node] [#{node["uuid"][0, 4]}] #{GenericObjectInterface::toString(objects.first)}"
            KeyValueStore::set(nil, cacheKey, str)
            return str
        end
        if node["description"].nil? and objects.size == 0 then
            str = "[node] [#{node["uuid"][0, 4]}] {no description, no dataline}"
            KeyValueStore::set(nil, cacheKey, str)
            return str
        end
        raise "[error: 2b22ddb3-62c4-4940-987a-7a50330dcd36]"
    end

    # NSDataType1::getReferenceUnixtime(ns)
    def self.getReferenceUnixtime(ns)
        DateTime.parse(GenericObjectInterface::getObjectReferenceDateTime(ns)).to_time.to_f
    end

    # NSDataType1::issueDescriptionInteractivelyOrNothing(point)
    def self.issueDescriptionInteractivelyOrNothing(point)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return if description == ""
        point["description"] = description
        NyxObjects2::put(point)
    end

    # NSDataType1::issueNewNodeInteractivelyOrNull()
    def self.issueNewNodeInteractivelyOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == "" 
        node = NSDataType1::issue()
        puts "node: #{JSON.pretty_generate(node)}"
        node["description"] = description
        NyxObjects2::put(node)
        if LucilleCore::askQuestionAnswerAsBoolean("Create datapoint ? : ") then
            datapoint = NSDataPoint::issueNewPointInteractivelyOrNull()
            if datapoint then
                Arrows::issueOrException(node, datapoint)
            end
        end
        node
    end

    # NSDataType1::destroy(point)
    def self.destroy(point)
        NyxObjects2::destroy(point)
    end

    # ---------------------------------------------

    # NSDataType1::landing(node)
    def self.landing(node)

        loop {

            return if NyxObjects2::getOrNull(node["uuid"]).nil?

            system("clear")

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule()

            puts "[parents]".yellow

            Arrows::getSourcesForTarget(node)
                .each{|o|
                    menuitems.item(
                        "parent: #{GenericObjectInterface::toString(o)}",
                        lambda { GenericObjectInterface::landing(o) }
                    )
                }

            puts ""

            menuitems.item(
                "attach parent node".yellow,
                lambda {
                    n = NSDT1SelectionInterface::sandboxSelectionOfOneExistingOrNewNodeOrNull()
                    return if n.nil?
                    Arrows::issueOrException(n, node)
                }
            )

            menuitems.item(
                "detach parent".yellow,
                lambda {
                    ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("parent", Arrows::getSourcesForTarget(node), lambda{|o| GenericObjectInterface::toString(o) })
                    return if ns.nil?
                    Arrows::unlink(ns, node)
                }
            )

            Miscellaneous::horizontalRule()

            puts "[node]".yellow

            if node["description"] then
                puts "    description: #{node["description"]}"
            end
            puts "    uuid: #{node["uuid"]}".yellow
            puts "    date: #{GenericObjectInterface::getObjectReferenceDateTime(node)}".yellow

            notetext = NSDataTypeXExtended::getLastNoteTextForTargetOrNull(node)
            if notetext and notetext.strip.size > 0 then
                Miscellaneous::horizontalRule()
                puts "Note:"
                puts notetext.strip.lines.map{|line| "    #{line}" }.join()
            end

            puts ""

            menuitems.item(
                "set/update description".yellow,
                lambda{
                    description = Miscellaneous::editTextSynchronously(node["description"] || "").strip
                    return if description == ""
                    node["description"] =  description
                    NyxObjects2::put(node)
                }
            )

            menuitems.item(
                "edit reference datetime".yellow,
                lambda{
                    datetime = Miscellaneous::editTextSynchronously(node["referenceDateTime"] || Time.new.utc.iso8601).strip
                    node["referenceDateTime"] = datetime
                    NyxObjects2::put(node)
                }
            )

            menuitems.item(
                "edit note".yellow,
                lambda{ 
                    text = NSDataTypeXExtended::getLastNoteTextForTargetOrNull(node) || ""
                    text = Miscellaneous::editTextSynchronously(text).strip
                    NSDataTypeXExtended::issueNoteForTarget(node, text)
                }
            )

            menuitems.item(
                "remove [this] as intermediary node".yellow, 
                lambda { 
                    puts "intermediary node removal simulation"
                    Arrows::getSourcesForTarget(node).each{|upstreamnode|
                        puts "upstreamnode   : #{GenericObjectInterface::toString(upstreamnode)}"
                    }
                    Arrows::getTargetsForSource(node).each{|downstreamobject|
                        puts "downstream object: #{GenericObjectInterface::toString(downstreamobject)}"
                    }
                    return if !LucilleCore::askQuestionAnswerAsBoolean("confirm removing as intermediary node ? ")
                    Arrows::getSourcesForTarget(node).each{|upstreamnode|
                        Arrows::getTargetsForSource(node).each{|downstreamobject|
                            Arrows::issueOrException(upstreamnode, downstreamobject)
                        }
                    }
                    NyxObjects2::destroy(node)
                }
            )

            menuitems.item(
                "[sandbox selection]".yellow,
                lambda{ KeyValueStore::set(nil, "d64d6e5e-9cc9-41b4-8c42-6062495ef546", JSON.generate(node)) }
            )

            menuitems.item(
                "destroy [this]".yellow,
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this node ? ") then
                        NSDataType1::destroy(node)
                    end
                }
            )

            Miscellaneous::horizontalRule()

            puts "[children]".yellow

            targets = Arrows::getTargetsForSource(node)
            targets = GenericObjectInterface::applyDateTimeOrderToObjects(targets)
            targets.each{|object|
                menuitems.item(
                    GenericObjectInterface::toString(object, false),
                    lambda{ GenericObjectInterface::landing(object) }
                )
            }

            puts ""

            menuitems.item(
                "issue new datapoint".yellow,
                lambda{
                    datapoint = NSDataPoint::issueNewPointInteractivelyOrNull()
                    return if datapoint.nil?
                    Arrows::issueOrException(node, datapoint)
                    description = LucilleCore::askQuestionAnswerAsString("description: ")
                    if description != "" then
                        datapoint["description"] =  description
                        NyxObjects2::put(datapoint)
                    end
                }
            )

            menuitems.item(
                "attach child node (new)".yellow,
                lambda {
                    o = NSDataType1::issueNewNodeInteractivelyOrNull()
                    return if o.nil?
                    Arrows::issueOrException(node, o)
                }
            )

            menuitems.item(
                "attach child node (chosen from existing nodes)".yellow,
                lambda {
                    o = NSDT1SelectionInterface::sandboxSelectionOfOneExistingOrNewNodeOrNull()
                    return if o.nil?
                    Arrows::issueOrException(node, o)
                }
            )

            menuitems.item(
                "detach child".yellow,
                lambda {
                    targets = Arrows::getTargetsForSource(node)
                    targets = GenericObjectInterface::applyDateTimeOrderToObjects(targets)
                    ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", targets, lambda{|o| GenericObjectInterface::toString(o) })
                    return if ns.nil?
                    Arrows::unlink(node, ns)
                }
            )

            menuitems.item(
                "select children ; move to existing/new node".yellow,
                lambda {
                    return if Arrows::getTargetsForSource(node).size == 0

                    targets = Arrows::getTargetsForSource(node)
                    targets = GenericObjectInterface::applyDateTimeOrderToObjects(targets)

                    # Selecting the nodes to moves
                    selectednodes, _ = LucilleCore::selectZeroOrMore("object", [], targets, lambda{ |o| GenericObjectInterface::toString(o) })
                    return if selectednodes.size == 0

                    # Selecting or creating the node
                    selectTargetNode = lambda { |node|
                        mode = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", ["existing child node", "new child node", "new independant node"])
                        return nil if mode.nil?
                        if mode == "existing child node" then
                            targets = Arrows::getTargetsForSource(node)
                            targets = GenericObjectInterface::applyDateTimeOrderToObjects(targets)
                            return LucilleCore::selectEntityFromListOfEntitiesOrNull("object", targets, lambda{|o| GenericObjectInterface::toString(o) })
                        end
                        if mode == "new child node" then
                            childnode = NSDataType1::issueNewNodeInteractivelyOrNull()
                            return nil if childnode.nil?
                            Arrows::issueOrException(node, childnode)
                            return childnode
                        end
                        if mode == "new independant node" then
                            xnode = NSDataType1::issueNewNodeInteractivelyOrNull()
                            return nil if xnode.nil?
                            return xnode
                        end
                    }

                    targetnode = selectTargetNode.call(node)
                    return if targetnode.nil?

                    # TODO: return if the selected new target is one of the nodes

                    # Moving the selectednodes
                    selectednodes.each{|o|
                        Arrows::issueOrException(targetnode, o)
                    }
                    selectednodes.each{|o|
                        Arrows::unlink(node, o)
                    }
                }
            )

            Miscellaneous::horizontalRule()

            status = menuitems.promptAndRunSandbox()

            break if !status

            break if KeyValueStore::getOrNull(nil, "d64d6e5e-9cc9-41b4-8c42-6062495ef546") # Looks like we were in sandbox mode and something was selected.
        }
    end
end
