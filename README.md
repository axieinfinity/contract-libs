# contract-libs

A collection of reusable Solidity libraries that can be used across multiple blockchain projects.

## Development

### Requirement

-   [Foundry forge@^0.2.0](https://book.getfoundry.sh/)

### Build & Test

-   Install packages

```shell
$ forge install
```

-   Build contracts

```shell
$ forge build
```

-   Run test

```shell
$ forge test
```

### Deploy

```shell
$ forge script <path/to/file.s.sol> -f --private-key <your_private_key>
```
