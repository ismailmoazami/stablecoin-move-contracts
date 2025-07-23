module stablecoin::price_feed; 

use pyth::{price, pyth, price_identifier, price_info};
use pyth::i64::I64;
use pyth::price_info::{PriceInfoObject};
use sui::clock::{Clock};
use std::debug;

const E_INVALID_ID: u64 = 0;

public fun get_sui_price(
        clock: &Clock,
        price_info_object: &PriceInfoObject,
    ):  (I64, I64) {
        let max_age = 60;

        let price_struct = pyth::get_price_no_older_than(price_info_object,clock, max_age);

        let price_info = price_info::get_price_info_from_price_info_object(price_info_object);
        let price_id = price_identifier::get_bytes(&price_info::get_price_identifier(&price_info));

        let testnet_sui_price_id = x"50c67b3fd225db8912a424dd4baed60ffdde625ed2feaaf283724f9608fea266";
        assert!(price_id == testnet_sui_price_id, E_INVALID_ID);

        let decimal_i64 = price::get_expo(&price_struct);
        let price_i64 = price::get_price(&price_struct);
        
        debug::print(&decimal_i64);
        debug::print(&price_i64);

        (decimal_i64, price_i64)
}
