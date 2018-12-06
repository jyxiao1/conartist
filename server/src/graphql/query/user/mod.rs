//! Holds information about a user and their products, prices, and conventions
use juniper::FieldResult;
use chrono::{DateTime, Utc};

use crate::database::Database;
use crate::database::models::*;

mod product_type;
mod product;
mod price;
mod record;
mod expense;
mod settings;

graphql_object!(User: Database |&self| {
    description: "Holds information about a user and their products, prices, and conventions"

    field id() -> i32 { self.user_id }
    field name() -> &String { &self.name }

    field email(&executor) -> FieldResult<&String> {
        executor.context().protect_me(self.user_id)?;
        Ok(&self.email)
    }

    field keys(&executor) -> FieldResult<i32> {
        executor.context().protect_me(self.user_id)?;
        Ok(self.keys)
    }

    field join_date() -> DateTime<Utc> { DateTime::from_utc(self.join_date, Utc) }

    field product_types(&executor) -> FieldResult<Vec<ProductType>> {
        dbtry! {
            executor
                .context()
                .get_product_types_for_user(Some(self.user_id))
        }
    }

    field products(&executor) -> FieldResult<Vec<ProductWithQuantity>> {
        dbtry! {
            executor
                .context()
                .get_products_for_user(Some(self.user_id))
        }
    }

    field prices(&executor) -> FieldResult<Vec<Price>> {
        dbtry! {
            executor
                .context()
                .get_prices_for_user(Some(self.user_id))
        }
    }

    field conventions(&executor) -> FieldResult<Vec<Convention>> {
        dbtry! {
            executor
                .context()
                .get_conventions_for_user(Some(self.user_id))
        }
    }

    field settings(&executor) -> Settings {
        executor
            .context()
            .get_settings_for_user(Some(self.user_id))
            .unwrap_or(Settings::default(self.user_id))
    }

    field clearance(&executor) -> i32 {
        executor
            .context()
            .get_admin_clearance(Some(self.user_id))
            .unwrap_or(0)
    }
});
