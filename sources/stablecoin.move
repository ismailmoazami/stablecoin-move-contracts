module stablecoin::stablecoin;

use sui::coin::{create_currency};
use sui::coin::{TreasuryCap, Coin};

public struct STABLECOIN has drop {}

fun init(witness: STABLECOIN, ctx: &mut TxContext) {
    let name = b"Stablecoin";
    let symbol = b"STC";
    let decimals = 9;

    let (treasury_cap, token_metadata) = create_currency(
        witness, 
        decimals, 
        symbol, 
        name, 
        b"", 
        option::none(), 
        ctx
    );

    sui::transfer::public_transfer(treasury_cap, ctx.sender());
    sui::transfer::public_freeze_object(token_metadata);

}

public fun mint(treasury_cap: &mut TreasuryCap<STABLECOIN>, amount: u64, to: address, ctx: &mut TxContext) {
    treasury_cap.mint_and_transfer(amount, to, ctx);
}

public fun burn(treasury_cap: &mut TreasuryCap<STABLECOIN>, coin: Coin<STABLECOIN>) {
    treasury_cap.burn(coin);
}