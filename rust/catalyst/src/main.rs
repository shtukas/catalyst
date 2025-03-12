use serde_json::{Value as JSONValue};
use rusqlite::{Connection, Error};

mod nxanniversaries;
use nxanniversaries::NxAnniversary;

mod nxfloats;
mod items;
use items::{get_partial_items_1, get_partial_items_2, PartialItem};

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

fn print_listing1(listing: Vec<NxAnniversary>) {
    listing.iter().for_each(|anniversary: &NxAnniversary| {
        println!("Anniversary from the database: {:?}", anniversary)
    });
}

fn print_listing2(items: Vec<PartialItem>) {
    items.iter().for_each(|item: &PartialItem| {
        println!("Item from the (real) database: {:?}", item)
    });
}

fn main() {
    let anniversary: NxAnniversary = get_anniversaries_from_database();
    print_listing1(vec![anniversary]);


    let items = get_partial_items_2();
    print_listing2(items);
}
