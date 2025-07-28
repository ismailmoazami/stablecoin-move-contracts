module stablecoin::price_feed; 

use SupraOracle::SupraSValueFeed::{Self, OracleHolder};
use sui::vec_map::{Self, VecMap};
use sui::event; 

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

public struct LatestPrice has copy, drop {
    value: u128,
    decimal: u16,
    timestamp: u128,
    round: u64,
}

fun init(ctx: &mut TxContext) {
    let resource = PriceFeedHolder {
        id: object::new(ctx),
        feeds: vec_map::empty<u32, PriceEntry>(),
    };
    sui::transfer::public_share_object(resource); 
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
    pair: u32
): (u128, u16){
    let (value, decimal, price, round) = SupraSValueFeed::get_price(oracle_holder, pair);
     
    event::emit(LatestPrice { value, decimal, timestamp: price, round });
    update_price(resource, pair, value, decimal, price, round);
    (value, decimal)
}

public fun get_sui_price_default(
    oracle_holder: &OracleHolder,
    resource: &mut PriceFeedHolder
): (u128, u16) {
    let sui_usd_pair_id = 90;
    let (value, decimal) = get_sui_price(oracle_holder, resource, sui_usd_pair_id); // SUI/USD pair ID
    (value, decimal)
}

