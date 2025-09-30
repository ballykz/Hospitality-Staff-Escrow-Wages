# 💼 Hospitality Staff Escrow Wages

A blockchain-based wage streaming solution for hospitality workers. Service staff wages are streamed on-chain daily, tied to hours logged, ensuring timely and transparent compensation.

## 🌟 Features

- **Staff Registration**: Register hospitality workers with hourly rates
- **Shift Logging**: Track hours worked per shift
- **Automated Wage Calculation**: Wages calculated based on hours × hourly rate
- **On-Chain Escrow**: Employer funds held securely in smart contract
- **Wage Claims**: Staff can claim earned wages anytime
- **Bulk Claims**: Claim all unclaimed wages in one transaction
- **Real-time Tracking**: Query staff hours, earnings, and shift history

## 📋 Contract Overview

The smart contract manages:
- Staff profiles with hourly rates
- Shift logs with hours worked
- Employer deposit balances
- Wage claims and payment history

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

```bash
git clone https://github.com/ballykz/Hospitality-Staff-Escrow-Wages.git
cd Hospitality-Staff-Escrow-Wages
clarinet check
```

## 📖 Usage

### Register Staff

```clarity
(contract-call? .Hospitality-Staff-Escrow-Wages register-staff
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
  "John Doe"
  u15)  ;; $15 per hour
```

### Deposit Funds (Employer)

```clarity
(contract-call? .Hospitality-Staff-Escrow-Wages deposit-funds)
```

### Log a Shift

```clarity
(contract-call? .Hospitality-Staff-Escrow-Wages log-shift
  u1        ;; staff-id
  u8        ;; hours worked
  tx-sender)  ;; employer principal
```

### Claim Wages (Staff)

```clarity
(contract-call? .Hospitality-Staff-Escrow-Wages claim-wages u1)
```

### Claim All Wages (Staff)

```clarity
(contract-call? .Hospitality-Staff-Escrow-Wages claim-all-wages u1)
```

## 🔍 Read-Only Functions

### Get Staff Info

```clarity
(contract-call? .Hospitality-Staff-Escrow-Wages get-staff-by-id u1)
```

### Get Unclaimed Wages

```clarity
(contract-call? .Hospitality-Staff-Escrow-Wages get-unclaimed-wages u1)
```

### Get Shift Log

```clarity
(contract-call? .Hospitality-Staff-Escrow-Wages get-shift-log u1)
```

### Get Employer Balance

```clarity
(contract-call? .Hospitality-Staff-Escrow-Wages get-employer-balance 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## 🔐 Security Features

- ✅ Owner-only administrative functions
- ✅ Staff can only claim their own wages
- ✅ Prevents double claiming
- ✅ Validates sufficient employer balance before logging shifts
- ✅ Active/inactive staff status management

## 🏗️ Architecture

**Data Structures:**
- `staff-registry`: Maps staff IDs to profile data
- `shift-logs`: Records all shifts with hours and wages
- `employer-deposits`: Tracks employer fund balances
- `staff-shifts`: Maps staff to their shift IDs

**Key Functions:**
- `register-staff`: Add new staff member
- `log-shift`: Record hours worked
- `claim-wages`: Withdraw earned wages
- `deposit-funds`: Employer adds funds to escrow

## 🧪 Testing

```bash
clarinet test
```

## 📊 Example Workflow

1. **Owner registers staff**: `register-staff` with hourly rate
2. **Employer deposits funds**: `deposit-funds` to escrow
3. **Owner logs shift**: `log-shift` with staff ID and hours
4. **Staff claims wages**: `claim-wages` or `claim-all-wages`

## 🛠️ Admin Functions

- `update-hourly-rate`: Change staff hourly rate
- `deactivate-staff`: Temporarily disable staff account
- `reactivate-staff`: Re-enable staff account

## 💡 Use Cases

- 🍽️ Restaurant servers and bartenders
- 🏨 Hotel housekeeping staff
- 🎉 Event service workers
- ☕ Café baristas
- 🚗 Delivery drivers

## 📝 Error Codes

- `u100`: Owner only
- `u101`: Not found
- `u102`: Already exists
- `u103`: Unauthorized
- `u104`: Insufficient balance
- `u105`: Invalid amount
- `u106`: Invalid hours
- `u107`: No wages
- `u108`: Already claimed

## 🤝 Contributing

Contributions welcome! Please open an issue or submit a pull request.

## 📜 License

MIT License

## 🔗 Links

- [Stacks Blockchain](https://www.stacks.co/)
- [Clarity Language](https://docs.stacks.co/clarity)
- [Clarinet Documentation](https://docs.hiro.so/clarinet)

---

Built with ❤️ for the hospitality industry
