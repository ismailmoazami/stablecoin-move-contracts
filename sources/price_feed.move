module stablecoin::price_feed; 

use SupraOracle::SupraSValueFeed::{Self, OracleHolder};
use sui::event; 

public struct LatestPrice has copy, drop {
    value: u128,
    decimal: u16,
    timestamp: u128,
    round: u64,
}

public fun get_asset_price(
    oracle_holder: &OracleHolder,
    pair: u32
): (u128, u16) {
    let (value, decimal, timestamp, round) = SupraSValueFeed::get_price(oracle_holder, pair);
     
    event::emit(LatestPrice { value, decimal, timestamp, round });
    (value, decimal)
}

public fun get_sui_price_default(
    oracle_holder: &OracleHolder
): (u128, u16) {
    let sui_usd_pair_id = 90;
    get_asset_price(oracle_holder, sui_usd_pair_id) // SUI/USD pair ID
}

