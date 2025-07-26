module stablecoin::price_feed; 

use stork::state::StorkState;
use stork::stork::get_temporal_numeric_value_unchecked;
use std::debug;

// SUI/USD feed ID from Stork - using the correct byte array format
const SUI_USD_FEED_ID: vector<u8> = b"0xa24cc95a4f3d70a0a2f7ac652b67a4a73791631ff06b4ee7f729097311169b81"

public fun get_sui_price(
        feed_id: vector<u8>,
        stork_state: &StorkState
    ):  (u64, bool) {
        let price = get_temporal_numeric_value_unchecked(stork_state, feed_id);
        let i128value = price.get_quantized_value(); 

        let magnitude = i128value.get_magnitude();
        let negative = i128value.is_negative();

        debug::print(&magnitude);
        debug::print(&negative);

        (magnitude as u64, negative)
} 

// Helper function to get SUI price using the default feed ID
public fun get_sui_price_default(stork_state: &StorkState): (u64, bool) {
    get_sui_price(SUI_USD_FEED_ID, stork_state)
} 
