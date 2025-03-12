use serde_json::{Value as JSONValue};
use rusqlite::{Connection, Error};

mod nxanniversaries;
use nxanniversaries::NxAnniversary;

mod nxfloats;
mod items;
use items::{get_mikuType_partial_items_2, get_partial_items_1, get_partial_items_2, PartialItem};

fn print_listing2(items: Vec<PartialItem>) {
    items.iter().for_each(|item: &PartialItem| {
        println!("Item from the (real) database: {:?}", item)
    });
}

fn main() {
    let mikuType = String::from("NxFloat");
    let items = get_mikuType_partial_items_2(mikuType);
    print_listing2(items);
}
