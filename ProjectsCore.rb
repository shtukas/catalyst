
# encoding: UTF-8

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

# -------------------------------------------------------------

# Collections was born out of what was originally known as Threads and Projects

# -------------------------------------------------------------
# Utils

# ProjectsCore::projectsUUIDs()
# ProjectsCore::projectUUID2NameOrNull(projectuuid)

# -------------------------------------------------------------
# creation

# ProjectsCore::createNewProject(projectname)

# -------------------------------------------------------------
# projects uuids

# ProjectsCore::addCatalystObjectUUIDToProject(objectuuid, projectuuid)
# ProjectsCore::addObjectUUIDToProjectInteractivelyChosen(objectuuid, projectuuid)
# ProjectsCore::projectCatalystObjectUUIDs(projectuuid)
# ProjectsCore::projectCatalystObjectUUIDs(projectuuid)

# -------------------------------------------------------------
# Time Structue

# ProjectsCore::setTimeStructure(projectuuid, timeUnitInDays, timeCommitmentInHours)

# -------------------------------------------------------------
# Misc

# ProjectsCore::transform()
# ProjectsCore::deleteProject2(uuid)

# -------------------------------------------------------------
# User Interface

# ProjectsCore::interactivelySelectProjectUUIDOrNUll()
# ProjectsCore::ui_projectsDive()
# ProjectsCore::ui_projectDive(projectuuid)
# ProjectsCore::deleteProject2(projectuuid)

# -------------------------------------------------------------

class ProjectsCore
    # ---------------------------------------------------
    # Utils

    def self.fs_location2UUID(location)
        if File.directory?(location) then
            uuidFilepath = "#{location}/.uuid"
            if !File.exists?(uuidFilepath) then
                File.open(uuidFilepath, "w"){|f| f.write(SecureRandom.hex(4)) }
            end
            IO.read(uuidFilepath).strip
        else
            Digest::SHA1.hexdigest("3fa3a298-8941-4c9e-8b59-f1bc867e517d:#{location}")[0,8]
        end
    end

    def self.fs_locations()
        Dir.entries("/Galaxy/Projects")
            .select{|filename| (filename[0,1] != ".") and (filename != 'Icon'+["0D"].pack("H*")) }
            .map{|filename| "/Galaxy/Projects/#{filename}" }
    end

    def self.fs_uuidIsFileSystemProject(uuid)
        ProjectsCore::fs_locations()
            .any?{|location| uuid == ProjectsCore::fs_location2UUID(location) }
    end

    def self.projectsUUIDs()
        uuids1 = JSON.parse(FKVStore::getOrDefaultValue(CATALYST_COMMON_PROJECTS_UUIDS_LOCATION, "[]"))
        uuids2 = ProjectsCore::fs_locations()
            .map{|location| ProjectsCore::fs_location2UUID(location) }
        uuids1 + uuids2
    end

    def self.projectUUID2NameOrNull(projectuuid)
        ProjectsCore::fs_locations()
            .select{|location| projectuuid == ProjectsCore::fs_location2UUID(location) }
            .each{|location|
                return File.basename(location)
            }
        FKVStore::getOrNull("AE2252BF-4915-4170-8435-C8C05EA4283C:#{projectuuid}")
    end

    # ---------------------------------------------------
    # creation

    def self.setProjectName(projectuuid, projectname)
        FKVStore::set("AE2252BF-4915-4170-8435-C8C05EA4283C:#{projectuuid}", projectname)
    end

    def self.createNewProject(projectname)
        projectuuid = SecureRandom.hex(4)
        FKVStore::set(CATALYST_COMMON_PROJECTS_UUIDS_LOCATION, JSON.generate(ProjectsCore::projectsUUIDs()+[projectuuid]))
        ProjectsCore::setProjectName(projectuuid, projectname)
        projectuuid
    end

    # ---------------------------------------------------
    # projects objects

    def self.addCatalystObjectUUIDToProject(objectuuid, projectuuid)
        uuids = ( ProjectsCore::projectCatalystObjectUUIDs(projectuuid) + [objectuuid] ).uniq
        FKVStore::set("C613EA19-5BC1-4ECB-A5B5-BF5F6530C05D:#{projectuuid}", JSON.generate(uuids))
    end

    def self.addObjectUUIDToProjectInteractivelyChosen(objectuuid)
        projectuuid = ProjectsCore::interactivelySelectProjectUUIDOrNUll()
        if projectuuid.nil? then
            if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Would you like to create a new project ? ") then
                projectname = LucilleCore::askQuestionAnswerAsString("project name: ")
                projectuuid = ProjectsCore::createNewProject(projectname)
            else
                return
            end
        end
        ProjectsCore::addCatalystObjectUUIDToProject(objectuuid, projectuuid)
        projectuuid
    end

    def self.projectCatalystObjectUUIDs(projectuuid)
        JSON.parse(FKVStore::getOrDefaultValue("C613EA19-5BC1-4ECB-A5B5-BF5F6530C05D:#{projectuuid}", "[]"))
            .select{|objectuuid| TheFlock::getObjectByUUIDOrNull(objectuuid) }
    end

    def self.projectCatalystObjects(projectuuid)
        JSON.parse(FKVStore::getOrDefaultValue("C613EA19-5BC1-4ECB-A5B5-BF5F6530C05D:#{projectuuid}", "[]"))
            .map{|objectuuid| TheFlock::getObjectByUUIDOrNull(objectuuid) }
            .compact
    end

    # ---------------------------------------------------
    # Time Struture (2)
    # The time structure against projects
    # TimeStructure: { "time-unit-in-days"=> Float, "time-commitment-in-hours" => Float }

    def self.setTimeStructure(projectuuid, timeUnitInDays, timeCommitmentInHours)
        timestructure = { "time-unit-in-days"=> timeUnitInDays, "time-commitment-in-hours" => timeCommitmentInHours }
        FKVStore::set("02D6DCBC-87BD-4D4D-8F0B-411B7C06B972:#{projectuuid}", JSON.generate(timestructure))
        timestructure
    end

    def self.getTimeStructureOrNull(projectuuid)
        timestructure = FKVStore::getOrNull("02D6DCBC-87BD-4D4D-8F0B-411B7C06B972:#{projectuuid}")
        return nil if timestructure.nil?
        JSON.parse(timestructure)
    end

    def self.getTimeStructureAskIfAbsent(projectuuid)
        timestructure = ProjectsCore::getTimeStructureOrNull(projectuuid)
        if timestructure.nil? then
            puts "Setting Time Structure for project '#{ProjectsCore::projectUUID2NameOrNull(projectuuid)}'"
            timeUnitInDays = LucilleCore::askQuestionAnswerAsString("Time unit in days: ").to_f
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("Time commitment in hours: ").to_f
            timestructure = ProjectsCore::setTimeStructure(projectuuid, timeUnitInDays, timeCommitmentInHours)
        end
        timestructure
    end

    def self.liveRatioDoneOrNull(projectuuid)
        timestructure = ProjectsCore::getTimeStructureAskIfAbsent(projectuuid)
        return nil if timestructure["time-commitment-in-hours"]==0
        100*(Chronos::summedTimespansWithDecayInSecondsLiveValue(projectuuid, timestructure["time-unit-in-days"]).to_f/3600).to_f/timestructure["time-commitment-in-hours"]
    end

    def self.metric(projectuuid)
        timestructure = ProjectsCore::getTimeStructureAskIfAbsent(projectuuid)
        # { "time-unit-in-days"=> Float, "time-commitment-in-hours" => Float }
        timeUnitMultiplier = 0.99 + 0.01*Math.exp(-timestructure["time-unit-in-days"])
        timeCommitmentMultiplier = 0.99 + 0.01*Math.atan(timestructure["time-commitment-in-hours"])
        metric = Chronos::metric3(projectuuid, 0.1, 0.8, timestructure["time-unit-in-days"], timestructure["time-commitment-in-hours"]) * timeUnitMultiplier * timeCommitmentMultiplier
        metric + CommonsUtils::traceToMetricShift(projectuuid)
    end

    # ---------------------------------------------------
    # Misc

    def self.transform()
        uuids = ProjectsCore::projectsUUIDs()
            .map{|projectuuid| ProjectsCore::projectCatalystObjectUUIDs(projectuuid) }
            .flatten
        TheFlock::flockObjects().each{|object|
            if uuids.include?(object["uuid"]) then
                object["metric"] = 0
                TheFlock::addOrUpdateObject(object)
            end
        }
    end

    def self.deleteProject2(projectuuid)
        if ProjectsCore::projectCatalystObjectUUIDs(projectuuid).size>0 then
            puts "You cannot complete this project because it has objects"
            LucilleCore::pressEnterToContinue()
            return
        end
        if ProjectsCore::fs_uuidIsFileSystemProject(projectuuid) then
            puts "You cannot complete this project because it is a file system based project"
            LucilleCore::pressEnterToContinue()
            return
        end
        projectuuids = ( ProjectsCore::projectsUUIDs() - [projectuuid] ).uniq
        FKVStore::set(CATALYST_COMMON_PROJECTS_UUIDS_LOCATION, JSON.generate(projectuuids))
    end

    # ---------------------------------------------------
    # User Interface

    def self.ui_projectTimeStructureAsStringContantLength(projectuuid)
        timestructure = ProjectsCore::getTimeStructureAskIfAbsent(projectuuid)
        # TimeStructure: { "time-unit-in-days"=> Float, "time-commitment-in-hours" => Float }
        "#{"%4.2f" % timestructure["time-commitment-in-hours"]} hours, #{"%4.2f" % (timestructure["time-unit-in-days"])} days"
    end

    def self.ui_projectDive(projectuuid)
        puts "-> #{ProjectsCore::projectUUID2NameOrNull(projectuuid)}"
        loop {
            catalystobjects = ProjectsCore::projectCatalystObjectUUIDs(projectuuid)
                .map{|objectuuid| TheFlock::flockObjects().select{|object| object["uuid"]==objectuuid }.first }
                .compact
                .sort{|o1,o2| o1['metric']<=>o2['metric'] }
                .reverse
            menuItem3 = "operation : set name" 
            menuItem4 = "operation : set time structure"  
            menuItem5 = "operation : destroy"            
            menuStringsOrCatalystObjects = catalystobjects
            menuStringsOrCatalystObjects = menuStringsOrCatalystObjects + [ menuItem3, menuItem4, menuItem5 ]
            toStringLambda = lambda{ |menuStringOrCatalystObject|
                # Here item is either one of the strings or an object
                # We return either a string or one of the objects
                if menuStringOrCatalystObject.class.to_s == "String" then
                    string = menuStringOrCatalystObject
                    string
                else
                    object = menuStringOrCatalystObject
                    "object    : #{CommonsUtils::object2Line_v0(object)}"
                end
            }
            menuChoice = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("menu", menuStringsOrCatalystObjects, toStringLambda)
            break if menuChoice.nil?
            if menuChoice == menuItem3 then
                ProjectsCore::setProjectName(
                    projectuuid, 
                    LucilleCore::askQuestionAnswerAsString("Name: "))
                next
            end
            if menuChoice == menuItem4 then
                ProjectsCore::setTimeStructure(
                        projectuuid, 
                        LucilleCore::askQuestionAnswerAsString("Time unit in days: ").to_f, 
                        LucilleCore::askQuestionAnswerAsString("Time commitment in hours: ").to_f)
                next
            end
            if menuChoice == menuItem5 then
                if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Are you sure you want to destroy this project ? ") then
                    ProjectsCore::ui_deleteProject1(projectuuid)
                end
                next
            end
            # By now, menuChoice is a catalyst object
            object = menuChoice
            CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
        }
    end

    def self.projectTimePoints(projectuuid)
        TimePointsCore::getTimePoints().select{|timepoint| timepoint["domain"]==projectuuid }
    end

    def self.projectToDueTimeInHours(projectuuid)
        ProjectsCore::projectTimePoints(projectuuid)
            .map{|timepoint| TimePointsCore::timepointToDueTimeinHoursUpToDate(timepoint) }
            .inject(0, :+)
    end

    def self.ui_projectsDive()
        loop {
            toString = lambda{ |projectuuid| 
                "#{ProjectsCore::fs_uuidIsFileSystemProject(projectuuid) ? "fs" : "  " } | #{ProjectsCore::ui_projectTimeStructureAsStringContantLength(projectuuid)} | #{ProjectsCore::liveRatioDoneOrNull(projectuuid) ? ("%6.2f" % ProjectsCore::liveRatioDoneOrNull(projectuuid)) + " %" : "        "} | #{ProjectsCore::projectUUID2NameOrNull(projectuuid)}" 
            }
            projectuuid = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("projects", ProjectsCore::projectsUUIDs().sort{|projectuuid1, projectuuid2| ProjectsCore::metric(projectuuid1) <=> ProjectsCore::metric(projectuuid2) }.reverse, toString)
            break if projectuuid.nil?
            ProjectsCore::ui_projectDive(projectuuid)
        }
    end

    def self.interactivelySelectProjectUUIDOrNUll()
        LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("project", ProjectsCore::projectsUUIDs(), lambda{ |projectuuid| ProjectsCore::projectUUID2NameOrNull(projectuuid) })
    end

    def self.ui_deleteProject1(projectuuid)
        if ProjectsCore::projectCatalystObjectUUIDs(projectuuid).size>0 then
            puts "You now need to destroy all the objects"
            LucilleCore::pressEnterToContinue()
            loop {
                objects = projectCatalystObjectUUIDs(projectuuid)
                break if objects.size==0
                objects.each{|object|
                        CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
                    }
            }
        end
        puts "ProjectsCore::deleteProject2"
        ProjectsCore::deleteProject2(projectuuid)
    end
end