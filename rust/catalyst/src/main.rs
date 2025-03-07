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

fn print_listing(listing: Vec<NxAnniversary>) {
    listing.iter().for_each(|anniversary: &NxAnniversary| {
        println!("Anniversary from the database: {:?}", anniversary)
    });
}

fn main() {
    let anniversary: NxAnniversary = get_anniversaries_from_database();
    print_listing(vec![anniversary])
}
