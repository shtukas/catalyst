
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

# -----------------------------------------------------------------

class StartlightNodes

    # StartlightNodes::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Starlight/nodes"
    end

    # StartlightNodes::save(node)
    def self.save(node)
        filepath = "#{StartlightNodes::path()}/#{node["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(node)) }
    end

    # StartlightNodes::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{StartlightNodes::path()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # StartlightNodes::nodes()
    def self.nodes()
        Dir.entries(StartlightNodes::path())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{StartlightNodes::path()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationTimestamp"]<=>i2["creationTimestamp"] }
    end

    # StartlightNodes::makeNodeInteractivelyOrNull()
    def self.makeNodeInteractivelyOrNull()
        node = {
            "uuid" => SecureRandom.uuid,
            "creationTimestamp" => Time.new.to_f,
            "name" => LucilleCore::askQuestionAnswerAsString("nodename: ")
        }
        StartlightNodes::save(node)
        puts JSON.pretty_generate(node)
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to give a parent to this new node ? ") then
            xnodes = StartlightNodes::nodes().reject{|n| n["uuid"] == node["uuid"] }
            xnode = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", xnodes, lambda {|node| StartlightNodes::nodeToString(node) })
            if xnode then
                StartlightPaths::makePathFromFirstNodeToSecondNode(xnode, node)
            end
        end
        node
    end

    # StartlightNodes::nodeToString(node)
    def self.nodeToString(node)
        "[starlight node] #{node["name"]} (#{node["uuid"][0, 4]})"
    end

    # StartlightNodes::selectNodeOrNull()
    def self.selectNodeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("node", StartlightNodes::nodes(), lambda {|node| StartlightNodes::nodeToString(node) })
    end

    # StartlightNodes::selectNodePossiblyMakeANewOneOrNull()
    def self.selectNodePossiblyMakeANewOneOrNull()
        node = StartlightNodes::selectNodeOrNull()
        return node if node
        StartlightNodes::makeNodeInteractivelyOrNull()
    end

    # StartlightNodes::nodeManagement(node)
    def self.nodeManagement(node)
        loop {
            puts JSON.pretty_generate(node)
            operations = [
                "rename"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "rename" then
                node["description"] = CatalystCommon::editTextUsingTextmate(node["description"]).strip
                StartlightNodes::save(node)
            end
        }
    end

    # StartlightNodes::nodeDive(node)
    def self.nodeDive(node)
        loop {
            puts JSON.pretty_generate(node)
            puts StartlightNodes::nodeToString(node).green
            puts "Network:"

            puts "    Parents"
            StarlightNavigation::getStarlightNetworkParentNodes(node).each{|n|
                puts "        #{StartlightNodes::nodeToString(n)}"
            }

            puts "    Children"
            StarlightNavigation::getStarlightNetworkChildNodes(node).each{|n|
                puts "        #{StartlightNodes::nodeToString(n)}"
            }
            operations = [
                "node management"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "node management" then
                StartlightNodes::nodeManagement(node)
            end
        }
    end

    # StartlightNodes::nodesDive()
    def self.nodesDive()
        puts "StartlightNodes::nodesDive() not implemented yet"
        LucilleCore::pressEnterToContinue()
    end
end

class StartlightPaths

    # StartlightPaths::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Starlight/paths"
    end

    # StartlightPaths::save(path)
    def self.save(path)
        filepath = "#{StartlightPaths::path()}/#{path["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(path)) }
    end

    # StartlightPaths::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{StartlightPaths::path()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # StartlightPaths::paths()
    def self.paths()
        Dir.entries(StartlightPaths::path())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{StartlightPaths::path()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationTimestamp"]<=>i2["creationTimestamp"] }
    end

    # StartlightPaths::makePathInteractivelyOrNull()
    def self.makePathInteractivelyOrNull()
        {
            "uuid"        => SecureRandom.uuid,
            "creationTimestamp" => Time.new.to_f,
            "sourceuuid"  => LucilleCore::askQuestionAnswerAsString("sourceuuid: "),
            "targetuuid"  => LucilleCore::askQuestionAnswerAsString("targetuuid: ")
        }
    end

    # StartlightPaths::makePathFromFirstNodeToSecondNode(node1, node2)
    def self.makePathFromFirstNodeToSecondNode(node1, node2)
        {
            "uuid"        => SecureRandom.uuid,
            "creationTimestamp" => Time.new.to_f,
            "sourceuuid"  => node1["uuid"],
            "targetuuid"  => node2["uuid"]
        }
    end

    # StartlightPaths::getPathsWithGivenTarget(targetuuid)
    def self.getPathsWithGivenTarget(targetuuid)
        StartlightPaths::paths()
            .select{|path| path["targetuuid"] == targetuuid }
    end

    # StartlightPaths::getPathsWithGivenSource(sourceuuid)
    def self.getPathsWithGivenSource(sourceuuid)
        StartlightPaths::paths()
            .select{|path| path["sourceuuid"] == sourceuuid }
    end

    # StartlightPaths::pathToString(path)
    def self.pathToString(path)
        "[starlight path] #{path["sourceuuid"]} -> #{path["targetuuid"]}"
    end
end

class StarlightDataClaims

    # StarlightDataClaims::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Starlight/dataclaims"
    end

    # StarlightDataClaims::save(dataclaim)
    def self.save(dataclaim)
        filepath = "#{StarlightDataClaims::path()}/#{dataclaim["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(dataclaim)) }
    end

    # StarlightDataClaims::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{StarlightDataClaims::path()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # StarlightDataClaims::dataclaims()
    def self.dataclaims()
        Dir.entries(StarlightDataClaims::path())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{StarlightDataClaims::path()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationTimestamp"]<=>i2["creationTimestamp"] }
    end

    # StarlightDataClaims::makeClaimInteractivelyOrNull()
    def self.makeDataClaimInteractivelyOrNull()
        {
            "uuid"       => SecureRandom.uuid,
            "creationTimestamp" => Time.new.to_f,
            "nodeuuid"   => LucilleCore::askQuestionAnswerAsString("nodeuuid: "),
            "pointuuid"  => LucilleCore::askQuestionAnswerAsString("pointuuid: ")
        }
    end

    # StarlightDataClaims::makeClaimGivenNodeAndDataPoint(node, datapoint)
    def self.makeClaimGivenNodeAndDataPoint(node, datapoint)
        {
            "uuid"       => SecureRandom.uuid,
            "creationTimestamp" => Time.new.to_f,
            "nodeuuid"   => node["uuid"],
            "pointuuid"  => datapoint["uuid"]
        }
    end

    # StarlightDataClaims::dataclaimToString(dataclaim)
    def self.dataclaimToString(dataclaim)
        "[starlight dataclaim] #{dataclaim["nodeuuid"]} -> #{dataclaim["pointuuid"]}"
    end

    # StarlightDataClaims::getDataPointsForNode(node)
    def self.getDataPointsForNode(node)
        StarlightDataClaims::dataclaims()
            .select{|claim| claim["nodeuuid"] == node["uuid"] }
            .map{|claim| DataPoints::getOrNull(claim["pointuuid"]) }
            .compact
    end

    # StarlightDataClaims::getNodesForDataPoint(datapoint)
    def self.getNodesForDataPoint(datapoint)
        StarlightDataClaims::dataclaims()
            .select{|claim| claim["pointuuid"] == datapoint["uuid"] }
            .map{|claim| StartlightNodes::getOrNull(claim["nodeuuid"]) }
            .compact
    end

end

class StarlightNavigation

    # StarlightNavigation::getStarlightNetworkParentNodes(node)
    def self.getStarlightNetworkParentNodes(node)
        StartlightPaths::getPathsWithGivenTarget(node["uuid"])
            .map{|path| StartlightNodes::getOrNull(path["sourceuuid"]) }
            .compact
    end

    # StarlightNavigation::getStarlightNetworkChildNodes(node)
    def self.getStarlightNetworkChildNodes(node)
        StartlightPaths::getPathsWithGivenSource(node["uuid"])
            .map{|path| StartlightNodes::getOrNull(path["targetuuid"]) }
            .compact
    end

    # StarlightNavigation::nagivateNode(node)
    def self.nagivateNode(node)
        loop {
            system("clear")
            puts "Starlight Node Navigation"
            puts "Location: #{StartlightNodes::nodeToString(node)}"
            items = []
            StarlightNavigation::getStarlightNetworkChildNodes(node)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|n| items << ["network child : #{StartlightNodes::nodeToString(n)}", lambda{ StarlightNavigation::nagivateNode(n) }] }

            items << nil
            StarlightDataClaims::getDataPointsForNode(node)
                .sort{|p1, p2| p1["creationTimestamp"] <=> p2["creationTimestamp"] }
                .each{|datapoint| items << ["datapoint     : #{DataPoints::datapointToString(datapoint)}", lambda{ StarlightNavigation::nagivateDataPoint(datapoint) }] }

            items << nil
            StarlightNavigation::getStarlightNetworkParentNodes(node)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|n| items << ["network parent: #{StartlightNodes::nodeToString(n)}", lambda{ StarlightNavigation::nagivateNode(n) }] }
            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
            break if !status
        }
    end

    # StarlightNavigation::nagivateDataPoint(datapoint)
    def self.nagivateDataPoint(datapoint)
        loop {
            system("clear")
            puts "Starlight DataPoint Navigation"

            items = []
            items << ["datapoint dive", lambda{ DataPoints::pointDive(datapoint) }]
            items << nil

            datapoint["targets"]
                .each{|target| items << ["catalyst standard target: #{CatalystStandardTargets::targetToString(target)}", lambda{ CatalystStandardTargets::targetDive(target)}] }

            items << nil
            StarlightDataClaims::getNodesForDataPoint(datapoint)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|n| items << ["node owner    : #{StartlightNodes::nodeToString(n)}", lambda{ StarlightNavigation::nagivateNode(n) }] }

            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
            break if !status
        }
    end
end

class StarlightUserInterfaceRoots

    # StarlightUserInterfaceRoots::navigation()
    def self.navigation()
        loop {
            system("clear")
            puts "Starlight Navigation (root)"
            operations = [
                "navigate from Guardian (temporary)",
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "navigate from Guardian (temporary)" then
                node = StartlightNodes::getOrNull("0d23dbf7-2527-4f28-98fa-33e03ab9668d")
                StarlightNavigation::nagivateNode(node)
            end
        }
    end

    # StarlightUserInterfaceRoots::management()
    def self.management()
        loop {
            system("clear")
            puts "Starlight Management (root)"
            operations = [
                "make starlight node",
                "make starlight path"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "make starlight node" then
                node = StartlightNodes::makeNodeInteractivelyOrNull()
                puts JSON.pretty_generate(node)
                StartlightNodes::save(node)
            end
            if operation == "make starlight path" then
                node1 = StartlightNodes::selectNodeOrNull()
                next if node1.nil?
                node2 = StartlightNodes::selectNodeOrNull()
                next if node2.nil?
                path = StartlightPaths::makePathFromFirstNodeToSecondNode(node1, node2)
                puts JSON.pretty_generate(path)
                StartlightPaths::save(path)
            end
        }
    end
end

