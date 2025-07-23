module stablecoin::engine;

// use stablecoin::stablecoin; // Commented out as it's not currently used
use sui::coin::{Coin};
use sui::sui::{SUI};
use sui::table::{Self, Table};
use sui::event; 
use stablecoin::price_feed;

// Types    
public struct Engine has key {
    id: UID,
    deposits: Table<address, Coin<SUI>>,
    minted_amounts: Table<address, u64>
}

// Events
public struct CollateralDeposited has copy, drop {
    sender: address, 
    amount: u64
}

// Errors
const EZeroAmount: u64 = 0;

// Functions
fun init(ctx: &mut TxContext) {
    let deposits = table::new<address, Coin<SUI>>(ctx);
    let minted_amounts = table::new<address, u64>(ctx);
    let engine = Engine{id: object::new(ctx), deposits: deposits, minted_amounts: minted_amounts};

    sui::transfer::share_object(engine);
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

// public fun mint(engine: &mut Engine, amount: u64, ctx: &mut TxContext) {

// } 