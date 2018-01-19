use postgres::types::{FromSql, ToSql, BPCHAR, Type, IsNull};
use juniper::Value;
use std::error::Error;
use std::str::FromStr;
use money::Money;
use error::MoneyError;

graphql_scalar!(Money {
    // TODO: improve when proper currency support is added
    description: "Represents a monetary value and a currency as a string, such as CAD150 for $1.50 in CAD"

    resolve(&self) -> Value {
        Value::string(self.to_string())
    }

    from_input_value(v: &InputValue) -> Option<Money> {
        v   .as_string_value()
            .and_then(|s| FromStr::from_str(&s).ok())
    }
});

impl Into<i64> for Money {
    fn into(self) -> i64 {
        self.amt()
    }
}

impl FromSql for Money {
    fn from_sql(_: &Type, raw: &[u8]) -> Result<Money, Box<Error + Sync + Send>> {
        <String as FromSql>::from_sql(&BPCHAR, raw).and_then(|s| FromStr::from_str(&s).map_err(|e: MoneyError| Box::new(e).into()))
    }

    accepts!(BPCHAR);
}

impl ToSql for Money {
    fn to_sql(&self, _: &Type, out: &mut Vec<u8>) -> Result<IsNull, Box<Error + 'static + Sync + Send>> {
        self.to_string().to_sql(&BPCHAR, out)
    }

    accepts!(BPCHAR);

    to_sql_checked!();
}
