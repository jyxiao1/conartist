//! The Product and Inventory tables
use chrono::NaiveDateTime;
use super::super::schema::*;

#[derive(Queryable, Clone)]
pub struct InventoryItem {
    pub inventory_id: i32,
    pub product_id: i32,
    pub quantity: i32,
    pub mod_date: NaiveDateTime,
}

#[derive(Queryable, Clone)]
pub struct Product {
    pub product_id: i32,
    pub type_id: i32,
    pub user_id: i32,
    pub name: String,
    pub discontinued: bool,
}

impl Product {
    pub fn with_quantity(self, quantity: i64) -> ProductWithQuantity {
        ProductWithQuantity {
            product_id: self.product_id,
            type_id: self.type_id,
            user_id: self.user_id,
            name: self.name,
            discontinued: self.discontinued,
            quantity
        }
    }
}

#[derive(Queryable, Clone)]
pub struct ProductWithQuantity {
    pub product_id: i32,
    pub type_id: i32,
    pub user_id: i32,
    pub name: String,
    pub discontinued: bool,
    pub quantity: i64,
}

#[derive(AsChangeset)]
#[table_name="products"]
pub struct ProductChanges {
    pub name: Option<String>,
    pub discontinued: Option<bool>,
}