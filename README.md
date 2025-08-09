# FlowForge DAO

[![Stacks](https://img.shields.io/badge/Stacks-blockchain-purple.svg)](https://www.stacks.co/)
[![Clarity](https://img.shields.io/badge/Clarity-smart%20contracts-blue.svg)](https://clarity-lang.org/)
[![Tests](https://img.shields.io/badge/tests-vitest-green.svg)](https://vitest.dev/)

A sophisticated decentralized autonomous organization (DAO) smart contract built on the Stacks blockchain that democratizes decision-making through stake-weighted voting, enabling community-driven resource allocation and transparent proposal execution.

## 🌟 Overview

FlowForge DAO revolutionizes decentralized governance by implementing a robust voting mechanism where community members stake STX tokens to gain proportional influence over treasury management and strategic decisions. The protocol features time-bound proposal lifecycles, automated quorum validation, and seamless fund distribution, creating a self-sustaining ecosystem where stakeholder alignment drives collective value creation and democratic resource stewardship.

## ✨ Key Features

### 🏛️ **Democratic Governance**

- **Stake-weighted voting system** ensuring proportional representation
- **Time-bound proposals** with configurable voting periods
- **Automatic quorum validation** for legitimate decision-making
- **Transparent execution** of approved proposals

### 💰 **Treasury Management**

- **Secure fund custody** with multi-signature-like approval process
- **Automated distribution** of approved funding requests
- **Real-time balance tracking** and financial transparency
- **Minimum stake requirements** to prevent spam and ensure commitment

### 🔐 **Security & Governance**

- **Comprehensive error handling** for all edge cases
- **Member verification** and authorization checks
- **Immutable vote recording** for complete audit trails
- **Protection against double voting** and unauthorized access

### 📊 **Analytics & Transparency**

- **Complete proposal history** with voting statistics
- **Member participation metrics** and engagement tracking
- **Real-time DAO statistics** and health monitoring
- **Public read-only interfaces** for external integrations

## 🏗️ Architecture

### Core Components

#### **Member Registry**

```clarity
(define-map members principal {
  joined-at: uint,
  stx-balance: uint,
  voting-power: uint,
  proposals-created: uint,
  last-vote-height: uint,
})
```

#### **Proposal Repository**

```clarity
(define-map proposals uint {
  creator: principal,
  title: (string-ascii 50),
  description: (string-ascii 500),
  amount: uint,
  recipient: principal,
  created-at: uint,
  expires-at: uint,
  yes-votes: uint,
  no-votes: uint,
  executed: bool,
  total-votes: uint,
})
```

#### **Vote Ledger**

```clarity
(define-map votes {proposal-id: uint, voter: principal} {
  vote: bool,
  power: uint,
})
```

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) (latest version)
- [Node.js](https://nodejs.org/) (v18 or higher)
- [Stacks Wallet](https://www.hiro.so/wallet) for testing

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/kingsley-cmake/flow-forge.git
   cd flow-forge
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Check contract syntax**

   ```bash
   clarinet check
   ```

4. **Run tests**

   ```bash
   npm test
   ```

### Development Setup

```bash
# Format contracts
clarinet fmt --in-place

# Watch mode for continuous testing
npm run test:watch

# Generate test coverage report
npm run test:report
```

## 📖 Usage Guide

### Joining the DAO

To become a DAO member, stake the minimum required STX tokens:

```clarity
;; Join the DAO by staking minimum membership fee
(contract-call? .flow-forge join-dao)
```

**Requirements:**

- Must not already be a member
- Must have sufficient STX balance for membership fee (default: 1 STX)

### Creating Proposals

Members can submit funding proposals for community consideration:

```clarity
;; Create a new proposal
(contract-call? .flow-forge create-proposal
  "Infrastructure Upgrade"           ;; title (max 50 chars)
  "Upgrade server infrastructure"    ;; description (max 500 chars)
  u5000000                          ;; amount in microSTX (5 STX)
  'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX17ECWG0X0) ;; recipient address
```

**Requirements:**

- Must be a DAO member
- Proposal amount cannot exceed treasury balance
- Title and description cannot be empty

### Voting on Proposals

Cast your vote on active proposals:

```clarity
;; Vote on proposal (true = yes, false = no)
(contract-call? .flow-forge vote-on-proposal u1 true)
```

**Voting Power:** Calculated as `staked-balance / 1,000,000`

**Requirements:**

- Must be a DAO member
- Proposal must be active (not expired)
- Cannot vote twice on same proposal

### Executing Proposals

Execute approved proposals to distribute funds:

```clarity
;; Execute a passed proposal
(contract-call? .flow-forge execute-proposal u1)
```

**Execution Criteria:**

- Proposal voting period must be complete
- Must meet quorum threshold (default: 51%)
- Yes votes must exceed quorum percentage
- Proposal not already executed

## 🔍 Query Functions

### Get Proposal Details

```clarity
(contract-call? .flow-forge get-proposal u1)
```

### Get Member Information

```clarity
(contract-call? .flow-forge get-member 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX17ECWG0X0)
```

### Get Vote Record

```clarity
(contract-call? .flow-forge get-vote u1 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX17ECWG0X0)
```

### Get DAO Statistics

```clarity
(contract-call? .flow-forge get-dao-info)
```

## ⚙️ Configuration Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| `minimum-membership-fee` | 1,000,000 µSTX (1 STX) | Minimum stake to join DAO |
| `proposal-duration` | 144 blocks (~1 day) | Voting period for proposals |
| `quorum-threshold` | 51% | Minimum vote percentage for approval |

## 🛡️ Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | `ERR-OWNER-ONLY` | Operation restricted to contract owner |
| 101 | `ERR-NOT-MEMBER` | User is not a DAO member |
| 102 | `ERR-ALREADY-MEMBER` | User is already a DAO member |
| 103 | `ERR-INSUFFICIENT-BALANCE` | Not enough funds for operation |
| 104 | `ERR-PROPOSAL-NOT-FOUND` | Requested proposal doesn't exist |
| 105 | `ERR-ALREADY-VOTED` | Member has already voted on proposal |
| 106 | `ERR-PROPOSAL-EXPIRED` | Proposal voting period has ended |
| 107 | `ERR-INSUFFICIENT-QUORUM` | Proposal didn't reach required votes |
| 108 | `ERR-PROPOSAL-NOT-PASSED` | Proposal didn't get enough yes votes |
| 109 | `ERR-INVALID-AMOUNT` | Invalid amount specified |
| 110 | `ERR-UNAUTHORIZED` | User not authorized for operation |
| 111 | `ERR-PROPOSAL-EXECUTED` | Proposal has already been executed |

## 🧪 Testing

The project includes comprehensive test coverage using Vitest and the Clarinet SDK:

```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:report

# Watch mode for development
npm run test:watch

# Check contract validity
clarinet check
```

### Test Structure

- **Unit Tests**: Individual function testing
- **Integration Tests**: End-to-end workflow testing
- **Edge Case Testing**: Error condition validation
- **Gas Cost Analysis**: Transaction cost optimization

## 🏃‍♂️ Deployment

### Testnet Deployment

1. **Configure network settings**

   ```bash
   # Edit settings/Testnet.toml for testnet configuration
   ```

2. **Deploy contract**

   ```bash
   clarinet deployments generate --devnet
   clarinet deployments apply --devnet
   ```

### Mainnet Deployment

```bash
# Configure mainnet settings
# Edit settings/Mainnet.toml

# Deploy to mainnet
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## 🔒 Security Considerations

- **Reentrancy Protection**: All external calls use `try!` for safe error handling
- **Access Control**: Comprehensive member verification system
- **Input Validation**: Strict parameter checking and bounds validation
- **Economic Security**: Minimum stake requirements prevent spam attacks
- **Immutable Records**: Vote history cannot be altered after submission

## 🤝 Contributing

We welcome contributions to FlowForge DAO! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Add comprehensive tests** for new functionality
4. **Follow Clarity best practices** and coding standards
5. **Submit a pull request** with detailed description

### Development Guidelines

- Follow [Clarity coding standards](https://book.clarity-lang.org/)
- Maintain test coverage above 90%
- Document all public functions
- Use descriptive variable names
- Include error handling for all edge cases

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Resources

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Guide](https://book.clarity-lang.org/)
- [Clarinet Documentation](https://github.com/hirosystems/clarinet)
- [Stacks Community](https://stacks.org/community)

*FlowForge DAO - Democratizing decentralized governance through transparent, stake-weighted decision making.*
