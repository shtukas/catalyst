
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

#[cfg(test)]
mod tests {
    use super::*;

    fn get_default_test_anniversary() -> NxAnniversary {
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

    #[test]
    fn test1() {
        let anniversary = get_default_test_anniversary();
        assert_eq!(anniversary.to_string(), "[NxAnniversary] (incomplete implementation of to_string)")
    }
}