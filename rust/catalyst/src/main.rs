use serde_json::{Value as JSONValue};

use rusqlite::{Connection, Error};

#[derive(Debug)]
struct NxAnniversary {
    uuid: String,
    mikuType: String,
    unixtime: i64,
    datetime: String,
    startdate: String,
    repeatType: String,
    next_celebration: String,
}

//#[derive(Serialize, Deserialize)]
#[derive(Debug)]
struct Item {
    uuid: String,
    raw_object: JSONValue
}

fn get_anniversaries_from_database() -> NxAnniversary {
    return NxAnniversary {
        uuid: "c117cc81-6c05-4dc2-9594-2d044b9e05a5".into(),
        mikuType: "NxAnniversary".into(),
        unixtime: 1741335180,
        datetime: "2025-03-07T08:14:15Z".into(),
        startdate: "2025-03-01".into(),
        repeatType: "montly".into(),
        next_celebration: "2025-04-01".into(),
    };
}

fn string_to_json_value(str: &String) -> JSONValue {
    serde_json::from_str(str).expect("error during JSON deserialisation")
}

fn get_items(conn: &Connection) -> Result<Vec<Item>, Error> {
    let mut stmt = conn.prepare("select _uuid_, _item_ from Items")?;
    let rows = stmt.query_map([], |row| {
        // Items (_uuid_ string primary key, _mikuType_ string, _item_ string)
        let uuid: String = row.get(0).unwrap();
        let item: String = row.get(1).unwrap();
        Ok((uuid, item))
    })?;
    let mut answer = Vec::new();
    for element in rows {
        let tuple = element.unwrap();
        answer.push(
            Item{
                uuid: tuple.0,
                raw_object: string_to_json_value(&tuple.1)
            }
        );
    }
    Ok(answer)
}

fn print_listing1(listing: Vec<NxAnniversary>) {
    listing.iter().for_each(|anniversary: &NxAnniversary| {
        println!("Anniversary from the database: {:?}", anniversary)
    });
}

fn print_listing2(items: Vec<Item>) {
    items.iter().for_each(|item: &Item| {
        println!("Item from the (real) database: {:?}", item)
    });
}

fn main() {
    let anniversary: NxAnniversary = get_anniversaries_from_database();
    print_listing1(vec![anniversary]);

    let conn = Connection::open("/Users/pascal/Galaxy/DataHub/Catalyst/data/Items/20240607-155704-609823.sqlite3").unwrap();
    let items = get_items(&conn).unwrap();
    print_listing2(items);
}
