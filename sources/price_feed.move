module stablecoin::price_feed; 

use SupraOracle::SupraSValueFeed::{Self, OracleHolder};
use std::debug;
use sui::vec_map::{Self, VecMap};

public struct PriceFeedHolder has key, store {
    id: UID,
    feeds: VecMap<u32, PriceEntry>,
}

public struct PriceEntry has store, copy, drop {
    value: u128,
    decimal: u16,
    timestamp: u128,
    round: u64,
}  

fun update_price(resource: &mut PriceFeedHolder, pair: u32, value: u128, decimal: u16, timestamp: u128, round: u64) {
    let feeds = resource.feeds;
    if (vec_map::contains(&feeds, &pair)) {
        let feed = vec_map::get_mut(&mut resource.feeds, &pair);
        feed.value = value;
        feed.decimal = decimal;
        feed.timestamp = timestamp;
        feed.round = round;
    } else {
        let entry = PriceEntry { value, decimal, timestamp, round };
        vec_map::insert(&mut resource.feeds, pair, entry);
    };
}

public fun get_sui_price(
    oracle_holder: &OracleHolder,
    resource: &mut PriceFeedHolder,
    pair: u32,
    ctx: &mut TxContext
) {
    let (value, decimal, price, round) = SupraSValueFeed::get_price(oracle_holder, pair);
    debug::print(&value);
    update_price(resource, pair, value, decimal, price, round);
}

public fun get_sui_price_default(
    oracle_holder: &OracleHolder,
    resource: &mut PriceFeedHolder,
    ctx: &mut TxContext
) {
    let sui_usd_pair_id = 90;
    get_sui_price(oracle_holder, resource, sui_usd_pair_id, ctx); // SUI/USD pair ID
}

