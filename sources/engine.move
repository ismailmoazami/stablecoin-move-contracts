module stablecoin::engine;

use stablecoin::stablecoin; 
use sui::coin::{Coin};
use sui::sui::{SUI};
use sui::table::{Self, Table};
use sui::event; 
use std::u64::pow;
use sui::coin::{TreasuryCap};
use stablecoin::price_feed::{Self, PriceFeedHolder};
use SupraOracle::SupraSValueFeed::OracleHolder;
// Types    
public struct Engine has key {
    id: UID,
    deposits: Table<address, Coin<SUI>>,
    minted_amounts: Table<address, u64>,
}

public struct Minter has key {
    id: UID,
    treasury: TreasuryCap<stablecoin::STABLECOIN>
}

// Events
public struct CollateralDeposited has copy, drop {
    sender: address, 
    amount: u64
}

// Errors
const EZeroAmount: u64 = 0;
const EHealthFactorTooLow: u64 = 1;

// Constants 
const LIQUIDATION_THRESHOLD: u64 = 50; // 50%
const THRESHOLD_PRECISION: u64 = 100; // 100%
const MIN_HEALTH_FACTOR: u64 = 1000000000;

// Functions
fun init(ctx: &mut TxContext) {
    let deposits = table::new<address, Coin<SUI>>(ctx);
    let minted_amounts = table::new<address, u64>(ctx);
    let engine = Engine{id: object::new(ctx), deposits: deposits, minted_amounts: minted_amounts};

    sui::transfer::share_object(engine);
}

public fun init_minter(treasury: TreasuryCap<stablecoin::STABLECOIN>, ctx: &mut TxContext) {
    
    let minter = Minter{id: object::new(ctx), treasury: treasury};

    sui::transfer::share_object(minter);
}

public fun deposit_collateral(engine: &mut Engine, coin: Coin<SUI>, ctx: &mut TxContext) {
    let value: u64 = coin.value();
    assert!(value > 0, EZeroAmount);

    if(engine.deposits.contains(ctx.sender())) {
        engine.deposits.borrow_mut(ctx.sender()).join(coin);
    } else {
        engine.deposits.add(ctx.sender(), coin);
    };

    event::emit(CollateralDeposited{
        sender: ctx.sender(),
        amount: value
    });

}

public fun mint(oracle_holder: &OracleHolder, resource: &mut PriceFeedHolder, minter: &mut Minter, engine: &mut Engine, amount: u64, ctx: &mut TxContext) {
    if(!engine.minted_amounts.contains(ctx.sender())) {
        engine.minted_amounts.add(ctx.sender(), 0);
    };
    
    let minted_amounts_by_user = engine.minted_amounts.borrow_mut(ctx.sender());
    *minted_amounts_by_user = *minted_amounts_by_user + amount;
    
    let health_factor = get_user_health_factor(oracle_holder, resource, engine, ctx);
    assert!(health_factor > MIN_HEALTH_FACTOR, EHealthFactorTooLow);
    stablecoin::mint(&mut minter.treasury, amount, ctx.sender(), ctx);
} 

fun get_collateral_value(oracle_holder: &OracleHolder, resource: &mut PriceFeedHolder, amount: u64): u64 {
    let (sui_price, decimal) = price_feed::get_sui_price_default(oracle_holder, resource);
    let value = amount * (sui_price as u64);
    value / pow(10, decimal as u8)
}

fun get_user_collateral_amount(engine: &Engine, address: address): u64 {
    let coin = engine.deposits.borrow(address);
    coin.value()
}

fun get_user_minted_amount(engine: &Engine, address: address): u64 {
    let amount = engine.minted_amounts.borrow(address);
    *amount 
}

fun get_user_health_factor(oracle_holder: &OracleHolder, resource: &mut PriceFeedHolder, engine: &Engine, ctx: &TxContext): u64 {
    let total_minted = get_user_minted_amount(engine, ctx.sender());
    let total_collateral_amount = get_user_collateral_amount(engine, ctx.sender());
    let total_collateral_value = get_collateral_value(oracle_holder, resource, total_collateral_amount);
    
    let collateral_adjusted_value = total_collateral_value * THRESHOLD_PRECISION / LIQUIDATION_THRESHOLD;
    collateral_adjusted_value / total_minted    
}
