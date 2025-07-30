module stablecoin::engine;

use stablecoin::stablecoin; 
use stablecoin::price_feed;
use SupraOracle::SupraSValueFeed::OracleHolder;
use sui::coin::{Coin};
use sui::sui::{SUI};
use sui::table::{Self, Table};
use sui::event; 
use std::u64::pow;
use sui::coin::{TreasuryCap};

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

public struct CollateralWithdrawn has copy, drop {
    sender: address,
    amount: u64
}

public struct Minted has copy, drop {
    sender: address,
    amount: u64
}

public struct Burned has copy, drop {
    sender: address,
    amount: u64
}

public struct Liquidated has copy, drop {
    liquidator: address,
    user: address,
    collateral_amount: u64,
    stablecoin_amount: u64
}

// Errors
const EZeroAmount: u64 = 0;
const EHealthFactorTooLow: u64 = 1;
const ENoMintedAmount: u64 = 2;
const EHealthFactorOk: u64 = 3;
const EHealthFactorNotImproved: u64 = 4; 

// Constants 
const LIQUIDATION_THRESHOLD: u64 = 50; // 50%
const THRESHOLD_PRECISION: u64 = 100; // 100%
const MIN_HEALTH_FACTOR: u64 = 1000000000;
const LIQUIDIATION_BONUS: u64 = 10;
const PERCICION: u64 = 1000000000;

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


public fun withdraw_collateral(engine: &mut Engine, oracle_holder: &OracleHolder, amount: u64,ctx: &mut TxContext) {
    
    withdraw_user_collateral(engine, oracle_holder, amount, ctx.sender(), ctx.sender(), ctx);
}

#[allow(lint(self_transfer))]
fun withdraw_user_collateral(engine: &mut Engine, oracle_holder: &OracleHolder, amount: u64, from: address, to: address,ctx: &mut TxContext) {
    assert!(amount > 0, EZeroAmount);
    let coin = engine.deposits.borrow_mut(from);
    let new_coin = sui::coin::split(coin, amount, ctx);

    sui::transfer::public_transfer(new_coin, to);

    let health_factor = get_user_health_factor(oracle_holder, engine, from);
    assert!(health_factor > MIN_HEALTH_FACTOR, EHealthFactorTooLow);

    event::emit(CollateralWithdrawn{
        sender: from,
        amount: amount
    });
}

public fun mint(oracle_holder: &OracleHolder, minter: &mut Minter, engine: &mut Engine, amount: u64, ctx: &mut TxContext) {
    if(!engine.minted_amounts.contains(ctx.sender())) {
        engine.minted_amounts.add(ctx.sender(), 0);
    };
    
    let minted_amounts_by_user = engine.minted_amounts.borrow_mut(ctx.sender());
    *minted_amounts_by_user = *minted_amounts_by_user + amount;
    
    let health_factor = get_user_health_factor(oracle_holder, engine, ctx.sender());
    assert!(health_factor > MIN_HEALTH_FACTOR, EHealthFactorTooLow);
    
    event::emit(Minted{
        sender: ctx.sender(),
        amount: amount
    });
    
    stablecoin::mint(&mut minter.treasury, amount, ctx.sender(), ctx);
} 

public fun burn(engine: &mut Engine, minter: &mut Minter, oracle_holder: &OracleHolder, coin: Coin<stablecoin::STABLECOIN>, ctx: &mut TxContext) {
    burn_stablecoin(engine, minter, oracle_holder, coin, ctx.sender(), ctx);
}

fun burn_stablecoin(engine: &mut Engine, minter: &mut Minter, oracle_holder: &OracleHolder, coin: Coin<stablecoin::STABLECOIN>, on_behalf_of: address, ctx: &TxContext) {
    let minted_amounts_by_user = engine.minted_amounts.borrow_mut(on_behalf_of);
    let amount = coin.value();
    assert!(*minted_amounts_by_user > 0, ENoMintedAmount);
    assert!(*minted_amounts_by_user >= amount, ENoMintedAmount);
    *minted_amounts_by_user = *minted_amounts_by_user - amount; 

    stablecoin::burn(&mut minter.treasury, coin);

    let health_factor = get_user_health_factor(oracle_holder, engine, ctx.sender());
    assert!(health_factor > MIN_HEALTH_FACTOR, EHealthFactorTooLow);

    event::emit(Burned{
        sender: ctx.sender(),
        amount: amount
    });
}

public fun liquidate(engine: &mut Engine, minter: &mut Minter, oracle_holder: &OracleHolder, user: address, coin: Coin<stablecoin::STABLECOIN>, ctx: &mut TxContext) {
    let starting_health_factor = get_user_health_factor(oracle_holder, engine, user);
    assert!(starting_health_factor < MIN_HEALTH_FACTOR, EHealthFactorOk);
    let debt_amount = coin.value();
    let token_amount_from_collateral = get_token_amount_from_usd(oracle_holder, debt_amount);
    let bonus_collateral = ((token_amount_from_collateral as u128) * (LIQUIDIATION_BONUS as u128)) / (THRESHOLD_PRECISION as u128);
    let total_collateral_amount = debt_amount + (bonus_collateral as u64);
    
    withdraw_user_collateral(engine, oracle_holder, total_collateral_amount, user, ctx.sender(), ctx);
    burn_stablecoin(engine, minter, oracle_holder, coin, user, ctx);
    
    event::emit(Liquidated{
        liquidator: ctx.sender(),
        user: user,
        collateral_amount: total_collateral_amount,
        stablecoin_amount: debt_amount
    });

    let ending_health_factor = get_user_health_factor(oracle_holder, engine, user);
    assert!(ending_health_factor > MIN_HEALTH_FACTOR, EHealthFactorTooLow); 
    assert!(ending_health_factor > starting_health_factor, EHealthFactorNotImproved);
}

fun get_collateral_value(oracle_holder: &OracleHolder, amount: u64): u64 {
    let (sui_price, decimal) = price_feed::get_sui_price_default(oracle_holder);
    
    // Handle the u128 price properly to avoid overflow
    let value = (amount as u128) * sui_price;
    let result = value / (pow(10, decimal as u8) as u128);
    (result as u64)
}

fun get_user_collateral_amount(engine: &Engine, address: address): u64 {
    let coin = engine.deposits.borrow(address);
    coin.value()
}

fun get_user_minted_amount(engine: &Engine, address: address): u64 {
    let amount = engine.minted_amounts.borrow(address);
    *amount 
}

fun get_user_health_factor(oracle_holder: &OracleHolder, engine: &Engine, user: address): u64 {
    let total_minted = get_user_minted_amount(engine, user);
    // Prevent division by zero
    assert!(total_minted > 0, ENoMintedAmount);
      
    let total_collateral_amount = get_user_collateral_amount(engine, user);
    let total_collateral_value = get_collateral_value(oracle_holder, total_collateral_amount);
    
    let collateral_adjusted_value = total_collateral_value * LIQUIDATION_THRESHOLD / THRESHOLD_PRECISION;
    (collateral_adjusted_value * PERCICION) / total_minted   
}

fun get_token_amount_from_usd(oracle_holder: &OracleHolder, usd_amount: u64): u64 {
    let (sui_price, decimal) = price_feed::get_sui_price_default(oracle_holder);
    
    let usd_amount_scaled = (usd_amount as u128) * (pow(10, decimal as u8) as u128);
    let sui_tokens_18_decimals = usd_amount_scaled / sui_price;
    (sui_tokens_18_decimals / (pow(10, 9) as u128)) as u64
}