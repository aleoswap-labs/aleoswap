# AleoSwap Program

AleoSwap is a decentralized exchange (DEX) built on the Aleo blockchain, utilizing the Uniswap mechanism. It leverages the unique features of the Aleo blockchain to offer enhanced privacy and new functionalities to both the DEX and its users.

We are currently undergoing rapid iteration. Some of the optimizations and new features may require Aleo(snarkVM, aleo lang) to provide additional features and support before they can be implemented.

## TOC
- [AleoSwap Program](#aleoswap-program)
  - [TOC](#toc)
  - [Functions](#functions)
    - [create\_token](#create_token)
    - [transfer](#transfer)
    - [approve](#approve)
    - [transfer\_from](#transfer_from)
    - [transfer\_to\_private](#transfer_to_private)
    - [transfer\_to\_public](#transfer_to_public)
    - [transfer\_privately](#transfer_privately)
    - [join](#join)
    - [create\_pair](#create_pair)
    - [add\_liquidity](#add_liquidity)
    - [remove\_liquidity](#remove_liquidity)
    - [swap\_exact\_tokens\_for\_tokens](#swap_exact_tokens_for_tokens)
    - [swap\_tokens\_for\_exact\_tokens](#swap_tokens_for_exact_tokens)
    - [token\_faucet](#token_faucet)
    - [set\_token\_faucet](#set_token_faucet)
    - [change\_token\_admin](#change_token_admin)
  - [Public States](#public-states)
    - [balances](#balances)
    - [allowance](#allowance)
    - [tokens](#tokens)
    - [faucets](#faucets)
    - [pairs](#pairs)
    - [global\_state](#global_state)

## Functions

### create_token

`create_token` is used to create a new token.

Function:
```rust
create_token(public info: TokenInfo)
```

Params:
- `info: TokenInfo`: a struct including token name, symbol, decimals and total_supply

  ```go
  struct TokenInfo {
      name: field,
      symbol: field,
      decimals: u8,
      total_supply: u128,
      admin: address,
  }
  ```
- We need to convert `name` and `symbol` string directly to bytes array and then to field (integer) type.
  e.g. `USDT -> 1431520340field`.
- The admin can perform some special operations on the token, like `set_token_faucet`.

### transfer

`transfer` is used to transfer public tokens.
- It is similar to the ERC20 transfer, but with an additional `token_id` parameter.

Function:
```rust
transfer(public token_id: field, public to: address, public amount: u128)
```

Params:
- `token_id: field`: the token id to be transferred
- `to: address`: the receiver address
- `amount: u128`: amount of tokens to be transferred

### approve

`approve` is used to authorize other accounts to spend tokens.
- It is similar to the ERC20 approve, but with an additional `token_id` parameter.

Function:
```rust
approve(public token_id: field, public spender: address, public amount: u128)
```

Params:
- `token_id: field`: the token id to be approved
- `spender: address`: the spender address
- `amount: u128`: the maximum amount that the spender can spend

### transfer_from

`transfer_from` is used to transfer of tokens from other accounts.
- It is similar to the ERC20 transfer_from, but with an additional `token_id` parameter.

Function:
```rust
transfer_from(public token_id: field, public from: address, public to: address, public amount: u128)
```

Params:
- `token_id: field`: the token id to be transferred
- `from: address`: the address of the account from which the token is transferred
- `to: address`: the receiver address
- `amount: u128`: amount of tokens to be transferred

### transfer_to_private

`transfer_to_private` is used to transfer and convert public tokens to a private token record (PrivateToken).

Function:
```rust
transfer_to_private(public token_id: field, private to: address, public amount: u128) -> PrivateToken
```

Params:
- `token_id: field`: the token id to be transferred
- `to: address`: the receiver address
- `amount: u128`: amount of tokens to be transferred and converted
- Output 1 PrivateToken record: a new PrivateToken record with the following structure:

  ```rust
  record PrivateToken {
      // The token owner
      owner: address,
      // The token id
      token: field,
      // The token amount
      amount: u128,
  }
  ```

### transfer_to_public

`transfer_to_public` is used to transfer and convert a private token record (`PrivateToken`) to public tokens.

Function:
```rust
transfer_to_public(private pt_in: PrivateToken, public to: address, public amount: u128) -> PrivateToken
```

Params:
- `pt_in: PrivateToken`: the PrivateToken record to be spent
- `to: address`: the receiver address
- `amount: u128`: amount of tokens to be transferred and converted
- Output 1 PrivateToken record: it is a new PrivateToken record (owned by the caller) with an amount of `pt_in.amount - amount`.

### transfer_privately

`transfer_privately` is used to transfer private tokens (`PrivateToken` records).

Function:
```rust
transfer_privately(private pt_in: PrivateToken, private to: address, private amount: u128) -> (PrivateToken, PrivateToken)
```

Params:
- `pt_in: PrivateToken`: the PrivateToken record to be spent
- `to: address`: the receiver address
- `amount: u128`: amount of tokens to be transferred
- Output 2 PrivateToken records: the first is belonging to the receiver(`to`), the second is a change belonging to the caller

### join

`join` is used to merge two `PrivateToken` records into a new `PrivateToken` record.
- The two records being merged must have the same owner and token

Function:
```rust
join(private pt1: PrivateToken, private pt2: PrivateToken) -> PrivateToken
```

Params:
- `pt1: PrivateToken`: the PrivateToken record to be spent
- `pt2: PrivateToken`: the PrivateToken record to be spent
- Output 1 PrivateToken record: the new record with an amount of `pt1.amount + pt2.amount`.

### create_pair

`create_pair` is used to create a new pair and add initial liquidity.
- A pair must be created through this function before subsequent liquidity and swap operations can be performed.
- This function can only be used to add initial liquidity, further liquidity additions require calling the `add_liquidity` function.
- Each pair is also a standard token (called LP token, created automatically when the pair is created), and its token_id is the same as pair_id: `lp_token_id = pair_id = bhp256_hash({token_a: field, token_b: field})`.

Function:
```rust
create_pair(
    public token_a: field,
    public token_b: field,
    public amount_a: u128,
    public amount_b: u128,
    public to: address
)
```

Params:
- `token_a: field`: the token with the smaller token id
- `token_b: field`: the token with the larger token id
- `amount_a: u128`: the amount of `token_a` to be added as the initial liquidity
- `amount_b: u128`: the amount of `token_b` to be added as the initial liquidity
- `to: address`: the address to receive the LP tokens

### add_liquidity

`add_liquidity` is used to add liquidity to a pair.

Function:
```rust
add_liquidity(
    public token_a: field,
    public token_b: field,
    public amount_a: u128,
    public amount_b: u128,
    public min_a: u128,
    public min_b: u128,
    public to: address
)
```

Params:
- `token_a: field`: the token with the smaller token id
- `token_b: field`: the token with the larger token id
- `amount_a: u128`: the max amount of `token_a` to be added
- `amount_b: u128`: the max amount of `token_b` to be added
- `min_a: u128`: the min amount of `token_a` to be added
- `min_b: u128`: the min amount of `token_b` to be added
- `to: address`: the address to receive the LP tokens

### remove_liquidity

`remove_liquidity` is used to remove liquidity from a pair.

Function:
```rust
remove_liquidity(
    public token_a: field,
    public token_b: field,
    public liquidity: u128,
    public min_a: u128,
    public min_b: u128,
    public to: address,
)
```

Params:
- `token_a: field`: the token with the smaller token id
- `token_b: field`: the token with the larger token id
- `liquidity: u128`: the amount of lP token to remove
- `min_a: u128`: the min amount of `token_a` to be removed
- `min_b: u128`: the min amount of `token_b` to be removed
- `to: address`: the address to receive the `token_a` and `token_b` tokens

### swap_exact_tokens_for_tokens

`swap_exact_tokens_for_tokens` is used to exchange a fixed amount of input token for a variable amount of output token.
- Slippage can be adjusted through the parameters.
- Each swap call will charge a fee of `0.3%`.

Function:
```rust
swap_exact_tokens_for_tokens(
    public token_in: field,
    public token_out: field,
    public amount_in: u128,
    public amount_out_min: u128,
    public to: address,
)
```

Params:
- `token_in: field`: the input token id
- `token_out: field`: the output token id
- `amount_in: u128`: the fixed amount of input token
- `amount_out_min: u128`: the minimum amount of output token expected to receive
- `to: address`: the address to receive the output tokens

### swap_tokens_for_exact_tokens

`swap_tokens_for_exact_tokens` is used to exchange a variable amount of input token for a fixed amount of output token.
- Slippage can be adjusted through the parameters.
- Each swap call will charge a fee of `0.3%`.

Function:
```rust
swap_tokens_for_exact_tokens(
    public token_in: field,
    public token_out: field,
    public amount_in_max: u128,
    public amount_out: u128,
    public to: address,
)
```

Params:
- `token_in: field`: the input token id
- `token_out: field`: the output token id
- `amount_in_max: u128`: the maximum amount of input token originally intended to be spent
- `amount_out: u128`: the fixed amount of output token
- `to: address`: the address to receive the output tokens

### token_faucet

`token_faucet` is used to obtain a small number of tokens for free.
- The faucet is used to facilitate users to get test tokens, it only exists in the test network.

Function:
```rust
token_faucet(public token_id: field, public to: address)
```

Params:
- `token_id: field`: the id of the token
- `to: address`: the receiver address

### set_token_faucet

`set_token_faucet` is used to configure the faucet amount of the token.
- Only the admin of the token can call this function.
- The faucet is used to facilitate users to get test tokens, it only exists in the test network.

Function:
```rust
set_token_faucet(public token_id: field, public amount: u128)
```

Params:
- `token_id: field`: the id of the token
- `amount: u128`: the amount of tokens the user can receive each time calling `token_faucet`. Set to 0 to turn off faucet.

### change_token_admin

`change_token_admin` is used to change the token admin address.
- Only the admin of the token can call this function.

Function:
```rust
change_token_admin(public token_id: field, public admin: address)
```

Params:
- `token_id: field`: the id of the token
- `admin: address`: the new admin address. It can be set to a special address to renounce administrator permissions.

## Public States

### balances

`balances` stores the balances of all tokens and all accounts.
- mapping: `key: field => balance: u128`
- key: `key = bhp256_hash({token: field, user: address})`
- the token id of an LP token is the same as its pair id

Query command:
```sh
curl $aleoRpc/testnet3/program/swap.aleo/mapping/balances/$key
```

### allowance

`allowance` stores authorization data (`approve`) of all tokens and all accounts.
- mapping: `key: field => amount: u128`
- key: `key = bhp256_hash({token: field, payer: address, spender: address})`
- the token id of an LP token is the same as its pair id

Query command:
```sh
curl $aleoRpc/testnet3/program/swap.aleo/mapping/allowance/$key
```

### tokens

`tokens` stores meta info (`TokenInfo`) of all tokens.
- mapping: `token_id: field => info: TokenInfo`
- the token id of an LP token is the same as its pair id
- `TokenInfo` is a structure as follows:

  ```rust
  struct TokenInfo {
      name: field,
      symbol: field,
      decimals: u8,
      total_supply: u128,
      admin: address,
  }
  ```

Query command:
```sh
curl $aleoRpc/testnet3/program/swap.aleo/mapping/tokens/$token_id
```

### faucets

`faucets` stores faucet configs of all tokens.
- mapping: `token_id: field => faucet_amount: u128`

Query command:
```sh
curl $aleoRpc/testnet3/program/swap.aleo/mapping/faucets/$token_id
```

### pairs

`pairs` stores the info of all pairs.
- mapping: `pair_id: field => pair: Pair`
- `pair_id` is a hash: `pair_id = bhp256_hash({token_a: field, token_b: field})`,
  `token_a` and `token_b` are the token ids of the two tokens that make up the pair, requiring `token_a < token_b`.
- `Pair` is a structure as follows:

  ```rust
  struct Pair {
      reserve_a: u128,
      reserve_b: u128,
  }
  ```

Query command:
```sh
curl $aleoRpc/testnet3/program/swap.aleo/mapping/pairs/$pair_id
```

### global_state

`global_state` stores the global state.
- mapping: `true: bool => state: GlobalState`
- `GlobalState` is a structure as follows:

  ```rust
  struct GlobalState {
      next_token_id: field,
      admin: address,
  }
  ```

Query command:
```sh
curl $aleoRpc/testnet3/program/swap.aleo/mapping/global_state/true
```
