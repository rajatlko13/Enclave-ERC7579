# ERC-7579 Reference Implementation

Reference Implementation to Minimal Modular Smart Account ([ERC-7579](https://eips.ethereum.org/EIPS/eip-7579)).

## Usage

### Installation

```bash
pnpm i
```

### Compile contracts

```bash
forge build
```

### Contracts

The reference implementation provides one account flavor:

- [MSAAdvanced](./src/MSAAdvanced.sol): A modular smart account that supports the mandatory ERC-7579 features, `delegatecall` executions and the optional hook extension.

- [CooldownValidator](./src/modules/CooldownValidator.sol): Validator contract to validate using ERC1271 standard and cooldown period.
