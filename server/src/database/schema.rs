table! {
    admins (user_id) {
        user_id -> Int4,
        clearance -> Int4,
    }
}

table! {
    conventionextrainfo (con_id, title) {
        con_id -> Int4,
        title -> Varchar,
        info -> Nullable<Json>,
        action -> Nullable<Text>,
        action_text -> Nullable<Text>,
    }
}

table! {
    conventionimages (image_id) {
        image_id -> Int4,
        con_id -> Int4,
        image_uuid -> Bpchar,
        create_date -> Timestamp,
    }
}

table! {
    conventioninforatings (con_info_id, user_id) {
        con_info_id -> Int4,
        user_id -> Int4,
        rating -> Bool,
    }
}

table! {
    conventionratings (con_id, user_id) {
        con_id -> Int4,
        user_id -> Int4,
        rating -> Int4,
        review -> Text,
    }
}

table! {
    conventions (con_id) {
        con_id -> Int4,
        title -> Varchar,
        start_date -> Date,
        end_date -> Date,
        predecessor -> Nullable<Int4>,
    }
}

table! {
    conventionuserinfo (con_info_id) {
        con_info_id -> Int4,
        con_id -> Int4,
        user_id -> Int4,
        information -> Text,
    }
}

table! {
    expenses (expense_id) {
        expense_id -> Int4,
        user_id -> Int4,
        con_id -> Int4,
        price -> Bpchar,
        category -> Varchar,
        description -> Text,
        spend_time -> Text,
        gen_id -> Nullable<Uuid>,
    }
}

table! {
    inventory (inventory_id) {
        product_id -> Int4,
        quantity -> Int4,
        mod_date -> Timestamp,
        inventory_id -> Int4,
    }
}

table! {
    prices (price_id) {
        price_id -> Int4,
        user_id -> Int4,
        type_id -> Int4,
        product_id -> Nullable<Int4>,
        quantity -> Int4,
        price -> Nullable<Bpchar>,
        mod_date -> Timestamp,
    }
}

table! {
    products (product_id) {
        product_id -> Int4,
        type_id -> Int4,
        user_id -> Int4,
        name -> Varchar,
        discontinued -> Bool,
        sort -> Int4,
    }
}

table! {
    producttypes (type_id) {
        type_id -> Int4,
        user_id -> Int4,
        name -> Varchar,
        color -> Nullable<Int4>,
        discontinued -> Bool,
        sort -> Int4,
    }
}

table! {
    records (record_id) {
        record_id -> Int4,
        user_id -> Int4,
        con_id -> Int4,
        price -> Bpchar,
        products -> Array<Int4>,
        info -> Text,
        sale_time -> Text,
        gen_id -> Nullable<Uuid>,
    }
}

table! {
    suggestions (suggestion_id) {
        suggestion_id -> Int4,
        user_id -> Int4,
        suggestion -> Text,
        create_date -> Timestamptz,
        status -> Int4,
    }
}

table! {
    suggestionvotes (suggestion_id, user_id) {
        suggestion_id -> Int4,
        user_id -> Int4,
    }
}

table! {
    user_conventions (user_con_id) {
        user_con_id -> Int4,
        user_id -> Int4,
        con_id -> Int4,
    }
}

table! {
    users (user_id) {
        user_id -> Int4,
        email -> Varchar,
        password -> Varchar,
        keys -> Int4,
        join_date -> Timestamp,
        name -> Varchar,
    }
}

table! {
    usersettings (user_id) {
        user_id -> Int4,
        currency -> Bpchar,
        language -> Bpchar,
    }
}

joinable!(admins -> users (user_id));
joinable!(conventionextrainfo -> conventions (con_id));
joinable!(conventionimages -> conventions (con_id));
joinable!(conventioninforatings -> conventionuserinfo (con_info_id));
joinable!(conventioninforatings -> users (user_id));
joinable!(conventionratings -> conventions (con_id));
joinable!(conventionratings -> users (user_id));
joinable!(conventionuserinfo -> conventions (con_id));
joinable!(conventionuserinfo -> users (user_id));
joinable!(inventory -> products (product_id));
joinable!(prices -> products (product_id));
joinable!(prices -> producttypes (type_id));
joinable!(prices -> users (user_id));
joinable!(products -> producttypes (type_id));
joinable!(products -> users (user_id));
joinable!(producttypes -> users (user_id));
joinable!(suggestions -> users (user_id));
joinable!(suggestionvotes -> suggestions (suggestion_id));
joinable!(suggestionvotes -> users (user_id));
joinable!(user_conventions -> conventions (con_id));
joinable!(user_conventions -> users (user_id));
joinable!(usersettings -> users (user_id));

allow_tables_to_appear_in_same_query!(
    admins,
    conventionextrainfo,
    conventionimages,
    conventioninforatings,
    conventionratings,
    conventions,
    conventionuserinfo,
    expenses,
    inventory,
    prices,
    products,
    producttypes,
    records,
    suggestions,
    suggestionvotes,
    user_conventions,
    users,
    usersettings,
);
