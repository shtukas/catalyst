
#[derive(Debug)]
pub struct NxFloat {
    pub uuid: String,
    pub mikuType: String,
    pub unixtime: i64,
    pub datetime: String,
    pub description: String,
}

impl NxFloat {
    fn to_string(&self) -> String {
        format!("[NxFloat] {}", self.description)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test1() {
        let float = NxFloat {
            uuid: "283b363f-f375-41bc-bcf3-94a9be193bf9".into(),
            mikuType: "NxFloat".into(),
            unixtime: 1741778973.into(),
            datetime: "2025-03-12T11:29:50Z".into(),
            description: "testing floats".into()
        };
        assert_eq!(float.to_string(), "[NxFloat] testing floats")
    }
}