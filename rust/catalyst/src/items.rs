use serde_json::{Value as JSONValue};
use rusqlite::{Connection, Error};

//#[derive(Serialize, Deserialize)]
#[derive(Debug)]
pub struct PartialItem {
    pub uuid: String,
    pub mikuType: String,
    pub json_value: JSONValue
}

fn string_to_json_value(str: &String) -> JSONValue {
    serde_json::from_str(str).expect("error during JSON deserialisation")
}

pub fn get_partial_items_1(conn: &Connection) -> Result<Vec<PartialItem>, Error> {
    let mut stmt = conn.prepare("select _uuid_, _mikuType_, _item_ from Items")?;
    let elements = stmt.query_map([], |row| {
        // Items (_uuid_ string primary key, _mikuType_ string, _item_ string)
        let uuid: String = row.get(0).unwrap();
        let mikuType = row.get(1).unwrap();
        let item_as_json_string: String = row.get(2).unwrap();
        Ok((uuid, mikuType, item_as_json_string))
    })?;
    let mut answer: Vec<PartialItem> = Vec::new();
    for element in elements {
        let tuple = element.unwrap();
        answer.push(
            PartialItem{
                uuid: tuple.0,
                mikuType: tuple.1,
                json_value: string_to_json_value(&tuple.2)
            }
        );
    }
    Ok(answer)
}

pub fn get_partial_items_2() -> Vec<PartialItem> {
    let conn = Connection::open("/Users/pascal/Galaxy/DataHub/Catalyst/data/Items/20240607-155704-609823.sqlite3").unwrap();
    get_partial_items_1(&conn).unwrap()
}
