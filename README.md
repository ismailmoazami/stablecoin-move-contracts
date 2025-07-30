# Stablecoin Protocol on Sui

A decentralized stablecoin protocol built on Sui Move, featuring over-collateralized lending with SUI as collateral and integration with Supra Oracle for real-time price feeds.

## 🚀 Features

- **Over-Collateralized Lending**: Users can deposit SUI as collateral to mint stablecoins
- **Real-Time Price Feeds**: Integrated with Supra Oracle for accurate SUI/USD pricing
- **Liquidation Mechanism**: Automated liquidation of undercollateralized positions
- **Health Factor Monitoring**: Continuous monitoring of user positions to prevent insolvency
- **Decentralized Architecture**: Built entirely on Sui Move for maximum security and transparency

## 🏗️ Architecture

### Core Components

1. **Stablecoin Module** (`stablecoin.move`)
   - Defines the stablecoin token (STC) with 9 decimals
   - Handles minting and burning operations
   - Treasury cap management

2. **Engine Module** (`engine.move`)
   - Core logic and collateral management 
   - Health factor calculations
   - Liquidation mechanism
   - Event emission for transparency

3. **Price Feed Module** (`price_feed.move`)
   - Integration with Supra Oracle
   - Real-time SUI/USD price fetching
   - Price validation and event emission

### Key Features

- **Collateralization Ratio**: 50% liquidation threshold
- **Liquidation Bonus**: 10% bonus for liquidators
- **Health Factor**: Minimum 1.0 required for operations
- **Oracle Integration**: Uses Supra Oracle for reliable price feeds

## 📦 Installation

### Prerequisites

- Sui CLI installed
- Access to Sui testnet

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd stablecoin
```

2. Install dependencies:
```bash
sui move build
```

3. Deploy to testnet:
```bash
sui client publish --gas-budget 100000000
```

## 🎯 Usage

### Initialization

```move
// Initialize the minter with treasury cap
engine::init_minter(treasury_cap, ctx);
```

### Core Operations

#### Deposit Collateral
```move
engine::deposit_collateral(engine, coin, ctx);
```

#### Mint Stablecoins
```move
engine::mint(oracle_holder, minter, engine, amount, ctx);
```

#### Burn Stablecoins
```move
engine::burn(engine, minter, oracle_holder, coin, ctx);
```

#### Withdraw Collateral
```move
engine::withdraw_collateral(engine, oracle_holder, amount, ctx);
```

#### Liquidate Position
```move
engine::liquidate(engine, minter, oracle_holder, user, coin, ctx);
```

## 🔧 Configuration

### Oracle Settings
- **SUI/USD Pair ID**: 90
- **Price Precision**: 18 decimals
- **Update Frequency**: Real-time via Supra Oracle

### Protocol Parameters
- **Liquidation Threshold**: 50%
- **Liquidation Bonus**: 10%
- **Minimum Health Factor**: 1.0
- **Precision**: 1,000,000,000 (9 decimals)

## 🧪 Testing

Run the test suite:
```bash
sui move test
```

## 📊 Events

The protocol emits comprehensive events for transparency:

- `CollateralDeposited`: When users deposit SUI collateral
- `CollateralWithdrawn`: When users withdraw collateral
- `Minted`: When stablecoins are minted
- `Burned`: When stablecoins are burned
- `Liquidated`: When positions are liquidated
- `LatestPrice`: Real-time price updates from oracle

## 🔒 Security Features

- **Over-collateralization**: Minimum 200% collateralization ratio
- **Health Factor Monitoring**: Continuous position monitoring
- **Automated Liquidation**: Prevents protocol insolvency
- **Oracle Integration**: Reliable price feeds from Supra
- **Move Language**: Type-safe and resource-oriented programming

## 🌟 Why Sui Move?

- **Parallel Execution**: High throughput and low latency
- **Object-Centric Model**: Natural fit for DeFi protocols
- **Type Safety**: Compile-time guarantees prevent common bugs
- **Resource-Oriented**: Secure asset management
- **Composability**: Easy integration with other Sui protocols

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- **Sui Foundation** for the excellent Move framework
- **Supra Oracle** for reliable price feeds

---

**Built with ❤️ on Sui Move**
