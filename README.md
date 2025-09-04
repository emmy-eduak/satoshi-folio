# SatoshiFolio - Autonomous Bitcoin Portfolio Management Protocol

[![Clarity Version](https://img.shields.io/badge/Clarity-v3-blue)](https://clarity-lang.org/)
[![Stacks](https://img.shields.io/badge/Stacks-Layer%201-orange)](https://stacks.co/)
[![License](https://img.shields.io/badge/License-ISC-green)](./LICENSE)

## Overview

SatoshiFolio represents the evolution of Bitcoin-native wealth management, combining the security of Bitcoin's base layer with the programmability of Stacks. Our protocol enables sophisticated investors to deploy automated strategies across the growing Bitcoin ecosystem without sacrificing self-sovereignty.

### Key Features

- **Autonomous Portfolio Execution** - Set-and-forget strategies with 24-hour rebalancing cycles
- **Multi-Asset Intelligence** - Support for up to 10 Bitcoin-native and Stacks tokens
- **Precision Allocation** - Fine-tuned percentage control down to 0.01% granularity
- **Non-Custodial Architecture** - Users maintain complete control over their assets
- **Institutional Security** - Multi-signature compatibility with SECP256k1 compliance
- **Transparent Economics** - Clear 0.25% protocol fee structure
- **Audit-Ready Design** - Clarity's inherent verifiability ensures trust through code

## System Architecture

### Protocol Constants

| Parameter | Value | Description |
|-----------|--------|-------------|
| `MAX-PORTFOLIO-ASSETS` | 10 | Maximum assets per portfolio |
| `PERCENTAGE-BASIS` | 10,000 | Basis points for percentage calculations (100.00%) |
| `REBALANCE-COOLDOWN` | 144 blocks | ~24 hours rebalancing frequency |
| `MAX-USER-PORTFOLIOS` | 20 | Maximum portfolios per user |
| `MANAGEMENT-FEE-BPS` | 25 | 0.25% management fee in basis points |

### Contract Architecture

```
SatoshiFolio Protocol
├── Portfolio Registry
│   ├── Portfolio Metadata
│   ├── Ownership Tracking
│   └── Rebalancing State
├── Asset Management
│   ├── Token Contracts
│   ├── Allocation Targets
│   └── Current Balances
└── User Management
    ├── Portfolio Ownership
    └── Multi-Portfolio Support
```

## Core Data Structures

### PortfolioRegistry Map

```clarity
{
  owner: principal,
  creation-block: uint,
  last-rebalance-block: uint,
  total-portfolio-value: uint,
  is-active: bool,
  asset-count: uint
}
```

### AssetAllocations Map

```clarity
{
  target-allocation-bps: uint,
  current-balance: uint,
  token-contract: principal
}
```

### UserPortfolioIndex Map

```clarity
(list 20 uint) ;; List of portfolio IDs owned by user
```

## Public Functions

### Portfolio Management

#### `create-portfolio`

Creates a new autonomous portfolio with specified token contracts and allocation percentages.

**Parameters:**

- `token-contracts`: List of up to 10 token contract principals
- `allocation-percentages`: Corresponding allocation percentages in basis points

**Returns:** Portfolio ID (uint)

**Example:**

```clarity
(contract-call? .satoshi-folio create-portfolio
  (list 'SP1H1733V5MZ3SZ9XRW9FKYGEZT0JDGEB8Y634C7R.my-token
        'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.usda-token)
  (list u6000 u4000)) ;; 60% / 40% allocation
```

#### `execute-rebalancing`

Triggers portfolio rebalancing according to target allocations.

**Parameters:**

- `portfolio-id`: Target portfolio identifier

**Returns:** Success boolean

#### `modify-asset-allocation`

Updates target allocation for a specific asset within a portfolio.

**Parameters:**

- `portfolio-id`: Portfolio identifier
- `asset-index`: Asset position index (0-based)
- `new-allocation-bps`: New allocation percentage in basis points

**Returns:** Success boolean

### Read-Only Functions

#### `get-portfolio-details`

Retrieves complete portfolio information including ownership, creation block, and current status.

#### `get-asset-allocation`

Returns allocation details for a specific asset within a portfolio.

#### `calculate-portfolio-health`

Analyzes portfolio status and determines rebalancing requirements.

#### `get-protocol-stats`

Provides protocol-wide statistics including total portfolios and fee structure.

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 100 | `ERR-UNAUTHORIZED-ACCESS` | Caller lacks required permissions |
| 101 | `ERR-PORTFOLIO-NOT-FOUND` | Portfolio ID does not exist |
| 102 | `ERR-INSUFFICIENT-BALANCE` | Insufficient token balance |
| 103 | `ERR-INVALID-TOKEN-CONTRACT` | Invalid or malformed token contract |
| 104 | `ERR-REBALANCING-FAILED` | Rebalancing operation failed |
| 105 | `ERR-PORTFOLIO-ALREADY-EXISTS` | Portfolio creation conflict |
| 106 | `ERR-INVALID-ALLOCATION` | Invalid allocation percentages |
| 107 | `ERR-TOKEN-LIMIT-EXCEEDED` | Exceeds maximum asset limit |
| 108 | `ERR-MISMATCHED-ARRAYS` | Token/allocation array length mismatch |
| 109 | `ERR-USER-REGISTRY-FAILED` | User portfolio registration failed |
| 110 | `ERR-TOKEN-INDEX-INVALID` | Asset index out of bounds |

## Data Flow

### Portfolio Creation Flow

1. **Input Validation**: Verify token contracts and allocation percentages
2. **Portfolio Registration**: Create entry in PortfolioRegistry
3. **Asset Configuration**: Map token contracts to allocation targets
4. **User Registry**: Update UserPortfolioIndex with new portfolio
5. **ID Generation**: Increment next-portfolio-id counter

### Rebalancing Flow

1. **Authorization Check**: Verify portfolio ownership
2. **Cooldown Validation**: Ensure 24-hour minimum between rebalances
3. **Portfolio Analysis**: Calculate current vs. target allocations
4. **Asset Reallocation**: Execute token swaps to match targets
5. **State Update**: Record last-rebalance-block timestamp

## Installation & Setup

### Prerequisites

- [Clarinet CLI](https://github.com/hirosystems/clarinet)
- Node.js 18+
- Stacks wallet (Hiro Wallet recommended)

### Installation

1. **Clone the repository**

```bash
git clone https://github.com/emmy-eduak/satoshi-folio.git
cd satoshi-folio
```

2. **Install dependencies**

```bash
npm install
```

3. **Verify contract syntax**

```bash
clarinet check
```

4. **Run tests**

```bash
npm test
```

## Development

### Contract Deployment

#### Testnet Deployment

```bash
clarinet deploy --testnet
```

#### Mainnet Deployment

```bash
clarinet deploy --mainnet
```

### Testing

#### Run all tests

```bash
npm test
```

#### Run tests with coverage

```bash
npm run test:report
```

#### Watch mode for development

```bash
npm run test:watch
```

### Contract Interaction Examples

#### Create a diversified Bitcoin portfolio

```clarity
;; 50% STX, 30% USDA, 20% ALEX
(contract-call? .satoshi-folio create-portfolio
  (list 'SP000000000000000000002Q6VF78.pox
        'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.usda-token
        'SP3K8BC0PPEVCV7NZ6QSRWPQ2JE9E5B6N3PA0KBR9.alex-token)
  (list u5000 u3000 u2000))
```

#### Check portfolio health

```clarity
(contract-call? .satoshi-folio calculate-portfolio-health u1)
```

#### Execute rebalancing

```clarity
(contract-call? .satoshi-folio execute-rebalancing u1)
```

## Security Considerations

- **Asset Custody**: Users maintain full custody of assets through non-custodial architecture
- **Access Control**: Portfolio operations restricted to verified owners
- **Rebalancing Cooldowns**: 24-hour minimum prevents excessive trading
- **Input Validation**: Comprehensive validation prevents malformed transactions
- **Fee Transparency**: Clear 0.25% management fee structure

## Protocol Economics

### Fee Structure

- **Management Fee**: 0.25% annually (25 basis points)
- **Rebalancing**: No additional fees beyond network costs
- **Portfolio Creation**: Free (excluding network fees)

### Revenue Distribution

Protocol fees support ongoing development, security audits, and ecosystem growth.

## Roadmap

### Phase 1: Core Protocol (Current)

- ✅ Portfolio creation and management
- ✅ Asset allocation framework
- ✅ Rebalancing mechanism
- ✅ User portfolio tracking

### Phase 2: Advanced Features

- 🔄 Automated DCA strategies
- 🔄 Yield farming integration
- 🔄 Advanced rebalancing algorithms
- 🔄 Portfolio performance analytics

### Phase 3: Ecosystem Integration

- 📋 DEX aggregation for optimal execution
- 📋 Cross-chain asset support
- 📋 Institutional features
- 📋 Mobile application

## Contributing

We welcome contributions from the community. Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

### Development Process

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit pull request

## License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.
