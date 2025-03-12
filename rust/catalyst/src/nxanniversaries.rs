
#[derive(Debug)]
pub struct NxAnniversary {
    pub uuid: String,
    pub mikuType: String,
    pub unixtime: i64,
    pub datetime: String,
    pub startdate: String,
    pub repeatType: String,
    pub next_celebration: String,
}

impl NxAnniversary {
    fn to_string(&self) -> String {
       String::from("[NxAnniversary] (incomplete implementation of to_string)")
    }
}
