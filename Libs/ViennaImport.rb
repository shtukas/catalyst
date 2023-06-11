
VIENNA_PATH_TO_DATA = "#{Config::userHomeDirectory()}/Library/Application Support/Vienna/messages.db"

# select link from messages where read_flag=0;
# update messages set read_flag=1 where link="https://www.schneier.com/blog/archives/2018/04/security_vulner_14.html"

class ViennaLinkFeeder
    def initialize()
        @links = []
    end
    def next()
        if @links.empty? then
            query = "select link from messages where read_flag=0;"
            @links = `sqlite3 '#{VIENNA_PATH_TO_DATA}' '#{query}'`.lines.map{|line| line.strip }
        end
        @links[0]
    end
    def links()
        @links
    end
    def done(link)
        query = "update messages set read_flag=1 where link=\"#{link}\""
        system("sqlite3 '#{VIENNA_PATH_TO_DATA}' '#{query}'")
        @links.shift
    end
    def count()
       query = "select link from messages where read_flag=0;"
       `sqlite3 '#{VIENNA_PATH_TO_DATA}' '#{query}'`.lines.count
    end
end

class ViennaImport
    # ViennaImport::import()
    def self.import()
        return if !Config::isPrimaryInstance()
        viennaLinkFeeder = ViennaLinkFeeder.new()
        loop {
            link = viennaLinkFeeder.next()
            break if link.nil?
            puts "vienna: #{link}"
            item = NxTasks::viennaUrl(link)
            puts JSON.pretty_generate(item)
            viennaLinkFeeder.done(link)
            sleep 0.1
        }
    end
end
