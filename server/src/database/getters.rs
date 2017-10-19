use super::*;

// TODO: do some caching here for efficiency
// TODO: handle errors more properly, returning Result<_, Error> instead of String
//       also update the dbtry! macro to resolve that problem correctly
// TODO: make this somehow typesafe/error safe instead of runtime checked. Use Diesel
impl Database {
    pub fn get_user_for_email(&self, email: &str) -> Result<User, String> {
        let conn = self.pool.get().unwrap();
        for row in &query!(conn, "SELECT * FROM Users WHERE email = $1", email) {
            return User::from(row);
        }
        return Err(format!("No user with email {} exists", email))
    }

    pub fn get_user_by_id(&self, maybe_user_id: Option<i32>) -> Result<User, String> {
        let user_id = self.resolve_user_id(maybe_user_id)?;
        let conn = self.pool.get().unwrap();
        for row in &query!(conn, "SELECT * FROM Users WHERE user_id = $1", user_id) {
            return User::from(row);
        }
        return Err(format!("No user {} exists", user_id))
    }

    pub fn get_product_types_for_user(&self, user_id: i32) -> Result<Vec<ProductType>, String> {
        assert_authorized!(self, user_id);
        let conn = self.pool.get().unwrap();
        Ok (
            query!(conn, "SELECT * FROM ProductTypes WHERE user_id = $1", user_id)
                .iter()
                .filter_map(|row| ProductType::from(row).ok())
                .collect()
        )
    }

    pub fn get_products_for_user(&self, user_id: i32) -> Result<Vec<ProductInInventory>, String> {
        assert_authorized!(self, user_id);
        let conn = self.pool.get().unwrap();
        Ok (
            query!(conn, "
                SELECT *
                FROM Products p INNER JOIN Inventory i ON p.product_id = i.product_id
                WHERE i.user_id = $1
            ", user_id)
                .into_iter()
                .filter_map(|row| ProductInInventory::from(row).ok())
                .collect()
        )
    }

    pub fn get_prices_for_user(&self, user_id: i32) -> Result<Vec<Price>, String> {
        assert_authorized!(self, user_id);
        let conn = self.pool.get().unwrap();
        Ok (
            query!(conn, "SELECT * FROM Prices WHERE user_id = $1", user_id)
                .iter()
                .filter_map(|row| Price::from(row).ok())
                .collect()
        )
    }

    pub fn get_conventions_for_user(&self, user_id: i32) -> Result<Vec<FullUserConvention>, String> {
        assert_authorized!(self, user_id);
        let conn = self.pool.get().unwrap();
        Ok (
            query!(conn, "
                SELECT *
                FROM User_Conventions u INNER JOIN Conventions c ON u.con_id = c.con_id
                WHERE user_id = $1
            ", user_id)
                .iter()
                .filter_map(|row| FullUserConvention::from(row).ok())
                .collect()
        )
    }

    pub fn get_convention_for_user(&self, maybe_user_id: Option<i32>, con_code: &str) -> Result<FullUserConvention, String> {
        let user_id = self.resolve_user_id(maybe_user_id)?;
        let conn = self.pool.get().unwrap();
        query!(conn, "
            SELECT *
            FROM User_Conventions u INNER JOIN Conventions c ON u.con_id = c.con_id
            WHERE user_id = $1
              AND code = $2
        ", user_id, con_code)
            .iter()
            .filter_map(|row| FullUserConvention::from(row).ok())
            .nth(0)
            .ok_or(format!("User {} is not signed up for convention {}", user_id, con_code))
    }

    pub fn get_products_for_user_con(&self, user_id: i32, user_con_id: i32) -> Result<Vec<ProductInInventory>, String> {
        assert_authorized!(self, user_id);
        let conn = self.pool.get().unwrap();
        Ok (
            query!(conn, "
                SELECT *
                FROM Products p INNER JOIN Inventory i ON p.product_id = i.product_id
                WHERE user_con_id = $1
            ", user_con_id)
                .into_iter()
                .filter_map(|row| ProductInInventory::from(row).ok())
                .collect()
        )
    }

    pub fn get_prices_for_user_con(&self, user_id: i32, user_con_id: i32) -> Result<Vec<Price>, String> {
        assert_authorized!(self, user_id);
        let conn = self.pool.get().unwrap();
        Ok (
            query!(conn, "SELECT * FROM Prices WHERE user_con_id = $1", user_con_id)
                .iter()
                .filter_map(|row| Price::from(row).ok())
                .collect()
        )
    }

    pub fn get_records_for_user_con(&self, user_id: i32, user_con_id: i32) -> Result<Vec<Record>, String> {
        assert_authorized!(self, user_id);
        let conn = self.pool.get().unwrap();
        Ok (
            query!(conn, "SELECT * FROM Records WHERE user_con_id = $1", user_con_id)
                .iter()
                .filter_map(|row| Record::from(row).ok())
                .collect()
        )
    }

    pub fn get_expenses_for_user_con(&self, user_id: i32, user_con_id: i32) -> Result<Vec<Expense>, String> {
        assert_authorized!(self, user_id);
        let conn = self.pool.get().unwrap();
        Ok (
            query!(conn, "SELECT * FROM Expenses WHERE user_con_id = $1", user_con_id)
                .iter()
                .filter_map(|row| Expense::from(row).ok())
                .collect()
        )
    }

    pub fn get_conventions_after(&self, date: NaiveDate, exclude_mine: bool) -> Result<Vec<Convention>, String> {
        let conn = self.pool.get().unwrap();
        Ok (
            if exclude_mine {
                query!(conn, "
                    SELECT * FROM Conventions c
                    WHERE start_date > $1
                      AND NOT EXISTS (
                        SELECT 1
                        FROM User_Conventions u
                        WHERE u.user_id = $2
                          AND u.con_id = c.con_id
                      )
                ", date, self.resolve_user_id(None)?)
            } else {
                query!(conn, "SELECT * FROM Conventions WHERE start_date > $1", date)
            }
            .iter()
            .filter_map(|row| Convention::from(row).ok())
            .collect()
        )
    }
}