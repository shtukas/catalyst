use serde_json::{Value as JSONValue};
use rusqlite::{Connection, Error};

//#[derive(Serialize, Deserialize)]
#[derive(Debug)]
pub struct Item {
    pub uuid: String,
    pub raw_object: JSONValue
}

fn string_to_json_value(str: &String) -> JSONValue {
    serde_json::from_str(str).expect("error during JSON deserialisation")
}

pub fn get_items(conn: &Connection) -> Result<Vec<Item>, Error> {
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