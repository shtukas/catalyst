
# encoding: UTF-8

=begin

Blades are the file where we store catalyst items data

create table version (version INTEGER primary key);
create table attributes (key TEXT primary key, value TEXT); # values are always JSON encoded
create table datablobs (nhash TEXT primary key, data BLOB);

There must at least be 
    - one attribute called uuid that is the unique identifier of the item
    - one attribute called mikuType
    - one attribute called unixtime (unixtime)

=end

class Blades

    # -------------------------------------
    # Private

    # Blades::repository_path()
    def self.repository_path()
        "#{Config::pathToCatalystDataRepository()}/blades"
    end

    # Blades::ensure_canonical_path(filepath)
    def self.ensure_canonical_path(filepath)
        return if !File.exist?(filepath)
        canonical_filename = "#{Digest::SHA1.file(filepath).hexdigest}.blade.sqlite3"
        canonical_filepath = "#{Blades::repository_path()}/#{canonical_filename[0, 2]}/#{canonical_filename}"
        return if filepath == canonical_filepath
        if !File.exist?(File.dirname(canonical_filepath)) then
            FileUtils.mkdir(File.dirname(canonical_filepath))
        end
        FileUtils.mv(filepath, canonical_filepath)
        canonical_filepath
    end

    # -------------------------------------
    # Public interface

    # Blades::init(uuid, mikuType)
    def self.init(uuid, mikuType)
        # create a new blade

        filepath = "#{Blades::repository_path()}/#{SecureRandom.hex}.blade.sqlite3"

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("create table version (version INTEGER primary key)", [])
        db.execute("insert into version (version) values (?)", [1])
        db.execute("create table attributes (key TEXT primary key, value TEXT)", [])
        db.execute("insert into attributes (key, value) values (?, ?)", ["uuid", JSON.generate(uuid)])
        db.execute("insert into attributes (key, value) values (?, ?)", ["mikuType", JSON.generate(mikuType)])
        db.execute("insert into attributes (key, value) values (?, ?)", ["unixtime", JSON.generate(Time.new.to_i)])
        db.execute("create table datablobs (nhash TEXT primary key, data BLOB)", [])
        db.commit
        db.close

        Blades::ensure_canonical_path(filepath)
    end
end
