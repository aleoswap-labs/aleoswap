# AleoSwap Program

[AleoSwap](https://aleoswap.org) is a decentralized exchange (DEX) built on the Aleo blockchain, utilizing the Uniswap mechanism. It leverages the unique features of the Aleo blockchain to offer enhanced privacy and new functionalities to both the DEX and its users.

We are currently undergoing rapid iteration. Some of the optimizations and new features may require Aleo(snarkVM, aleo lang) to provide additional features and support before they can be implemented.

Learn more about the project:
- [Official Website](https://aleoswap.org)
- [Aleoswap Introduction](./introduction.md)
- [Aleoswap Tutorial](./aleoswap-tutorial.pdf)

## TOC
- [AleoSwap Program](#aleoswap-program)
  - [TOC](#toc)
  - [Deployment](#deployment)
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
    - [create\_pair\_privately](#create_pair_privately)
    - [add\_liquidity](#add_liquidity)
    - [add\_liquidity\_privately](#add_liquidity_privately)
    - [remove\_liquidity](#remove_liquidity)
    - [remove\_liquidity\_privately](#remove_liquidity_privately)
    - [wrap\_private\_credits](#wrap_private_credits)
    - [wrap\_public\_credits](#wrap_public_credits)
    - [unwrap](#unwrap)
    - [handle\_unwrap\_to\_private](#handle_unwrap_to_private)
    - [handle\_unwrap\_to\_public](#handle_unwrap_to_public)
    - [swap\_exact\_tokens\_for\_tokens](#swap_exact_tokens_for_tokens)
    - [swap\_exact\_private\_for\_public](#swap_exact_private_for_public)
    - [swap\_exact\_private\_for\_private](#swap_exact_private_for_private)
    - [swap\_exact\_public\_for\_private](#swap_exact_public_for_private)
    - [swap\_tokens\_for\_exact\_tokens](#swap_tokens_for_exact_tokens)
    - [swap\_private\_for\_exact\_public](#swap_private_for_exact_public)
    - [swap\_private\_for\_exact\_private](#swap_private_for_exact_private)
    - [swap\_public\_for\_exact\_private](#swap_public_for_exact_private)
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
    - [wrap\_state](#wrap_state)
    - [unwraps](#unwraps)

## Deployment

- [aleoswap05.aleo](https://explorer.hamp.app/program?id=aleoswap05.aleo)
- [aleoswap04.aleo](https://explorer.hamp.app/program?id=aleoswap04.aleo)
- [aleoswap03.aleo](https://explorer.hamp.app/program?id=aleoswap03.aleo)
- [aleoswap02.aleo](https://explorer.hamp.app/program?id=aleoswap02.aleo)
- [hello_als1.aleo](https://explorer.hamp.app/program?id=hello_als1.aleo)

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

Command:
```sh
# Create a new token: name=USDT, symbol=USDT, decimals=6, total_supply=1e8*1e6, admin=$admin_addr
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id create_token "{name: 1431520340field, symbol: 1431520340field, decimals: 6u8, total_supply: 100000000000000u128, admin: $admin_addr}"
```

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

Command:
```sh
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id transfer 1field $to_address 100000000u128
```

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

Command:
```sh
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id approve 1field $spender 10000000000u128
```

### transfer_from

`transfer_from` is used to transfer public tokens from other accounts.
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

Command:
```sh
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id transfer_from 1field $from_addr $to_addr 100000000u128
```

### transfer_to_private

`transfer_to_private` is used to transfer and convert public tokens to a new private token record (PrivateToken).

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

Command:
```sh
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id transfer_to_private 1field $to_addr 100000000u128
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

Command:
```sh
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id transfer_to_public $private_token_record $to_addr 10000000u128
```

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
- Output 2 PrivateToken records: the first belongs to the receiver(`to`), the second is a change belonging to the caller

Command:
```sh
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id transfer_privately $private_token_record $to_addr 50000000u128
```

### join

`join` is used to merge two `PrivateToken` records into a new `PrivateToken` record.
- The two records being joined must have the same owner and the token id.

Function:
```rust
join(private pt1: PrivateToken, private pt2: PrivateToken) -> PrivateToken
```

Params:
- `pt1: PrivateToken`: the PrivateToken record to be spent
- `pt2: PrivateToken`: the PrivateToken record to be spent
- Output 1 PrivateToken record: the new record with an amount of `pt1.amount + pt2.amount`.

Command:
```sh
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id join $private_token_record_1 $private_token_record_2
```

### create_pair

`create_pair` is used to create a new pair and add initial liquidity.
- A pair must be created through this function (or `create_pair_privately`) before subsequent liquidity and swap operations can be performed.
- Each pair is also a standard token (called liquidity pool token or LP token) created automatically when the pair is created,
  and its token_id is the same as pair_id: `lp_token_id = pair_id = bhp256_hash({token_a: field, token_b: field})`.
- This function can only be used to add initial liquidity, further liquidity additions require calling the `add_liquidity` function.
- The caller's token_a and token_b will be transferred to the program, and LP tokens will be minted to the `to` address.

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

Command:
```sh
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id create_pair 1field 2field 100000000u128 10000000000u128 $to_addr
```

### create_pair_privately

`create_pair_privately` is used to create a new pair and add initial liquidity privately.

Function:
```rust
transition create_pair_privately(
    private pt_a: PrivateToken,
    private pt_b: PrivateToken,
    public amount_a: u128,
    public amount_b: u128,
    private to: address,
    public liquidity: u128,
) -> (PrivateToken, PrivateToken, PrivateToken)
```

Params:
- `pt_a: PrivateToken`: the PrivateToken record of `token_a` to be spent
- `pt_b: PrivateToken`: the PrivateToken record of `token_b` to be spent, require `pt_a.token < pt_b.token`
- `amount_a: u128`: the amount of `token_a` to be added as the initial liquidity
- `amount_b: u128`: the amount of `token_b` to be added as the initial liquidity
- `to: address`: the address to receive the private LP tokens
- `liquidity: u128`: the amount of LP token to add initially
- Output 3 `PrivateToken` records:
  1. the output LP token owned by `to`
  2. the change of `pt_a` owned by caller
  3. the change of `pt_b` owned by caller

### add_liquidity

`add_liquidity` is used to add liquidity to a pair.
- The caller's `token_a` and `token_b` will be transferred to the program, and LP tokens will be minted to the `to` address.

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
- `token_b: field`: the token with the larger token id, require `token_a < token_b`
- `amount_a: u128`: the max amount of `token_a` to be added
- `amount_b: u128`: the max amount of `token_b` to be added
- `min_a: u128`: the min amount of `token_a` to be added
- `min_b: u128`: the min amount of `token_b` to be added
- `to: address`: the address to receive the LP tokens

Command:
```sh
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id add_liquidity 1field 2field 100000000u128 10000000000u128 0u128 0u128 $to_addr
```

### add_liquidity_privately

`add_liquidity_privately` is used to add liquidity to a pair privately.

Function:
```rust
transition add_liquidity_privately(
    private pt_a: PrivateToken,
    private pt_b: PrivateToken,
    public amount_a: u128,
    public amount_b: u128,
    public min_a: u128,
    public min_b: u128,
    public min_liquidity: u128,
    private to: address,
    public refund_to: address,
) -> (PrivateToken, PrivateToken, PrivateToken)
```

Params:
- `pt_a: PrivateToken`: the PrivateToken record of `token_a` to be spent
- `pt_b: PrivateToken`: the PrivateToken record of `token_b` to be spent, require `pt_a.token < pt_b.token`
- `amount_a: u128`: the max amount of `token_a` to be added
- `amount_b: u128`: the max amount of `token_b` to be added
- `min_a: u128`: the min amount of `token_a` to be added
- `min_b: u128`: the min amount of `token_b` to be added
- `min_liquidity: u128`: the min amount of LP token to receive
- `refund_to: address`: the address to receive the refunded LP token publicly

- Output 3 `PrivateToken` records:
  1. the output LP token owned by `to`
  2. the change of `pt_a` owned by caller
  3. the change of `pt_b` owned by caller

### remove_liquidity

`remove_liquidity` is used to remove liquidity from a pair.
- The caller's LP tokens will be burned, `token_a` and `token_b` will be transferred to the `to` address.

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

Command:
```sh
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id remove_liquidity 1field 2field 1000000000u128 0u128 0u128 $to_addr
```

### remove_liquidity_privately

`remove_liquidity` is used to remove liquidity from a pair privately.

Function:
```rust
transition remove_liquidity_privately(
    public token_a: field,
    public token_b: field,
    private pt_lp: PrivateToken,
    public liquidity: u128,
    public min_a: u128,
    public min_b: u128,
    private to: address,
    public refund_to: address,
) -> (PrivateToken, PrivateToken, PrivateToken)
```

Params:
- `token_a: field`: the token with the smaller token id
- `token_b: field`: the token with the larger token id
- `pt_lp: PrivateToken`: the PrivateToken record of LP token to be spent
- `liquidity: u128`: the amount of LP token to remove
- `min_a: u128`: the min amount of `token_a` to be removed
- `min_b: u128`: the min amount of `token_b` to be removed
- `to: address`: the address to receive the `token_a` and `token_b` tokens
- `refund_to: address`: the address to receive the remaining `token_a` and `token_b` publicly
- Output 3 `PrivateToken` records:
  1. the output `token_a` record owned by `to`
  2. the output `token_b` record owned by `to`
  3. the change of `pt_lp` owned by caller

### wrap_private_credits

`wrap_private_credits` is used to wrap private aleo credits into WALEO tokens (the token-0).
- The wrapper function performs a `1:1` exchange between Aleo micro-credits and WALEO token.
- In this way, we can introduce aleo credits into our DeFi world. The user can always convert WALEO tokens back into aleo credits by unwrapping.

Function:
```rust
wrap_private_credits(
    private input: credits.leo/credits,
    public to: address,
    public amount: field,
    public holder: address
) -> (credits.leo/credits)
```

Params:
- `input: credits`: the aleo credits record to be wrapped
- `to: address`: the address to receive the WALEO tokens
- `amount: field`: amount of micro-credits to be wrapped
- `holder: address`: the address to hold the wrapped aleo credits. It must be the admin of WALEO token (token-0) for safety.
- Output 1 credits record: it is the change for the caller

Command:
```sh
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id wrap_private_credits $input_record $to_addr 10000000field $holder_addr
```

### wrap_public_credits

`wrap_private_credits` is used to wrap public aleo credits into WALEO tokens (the token-0).
- It is similar to the `wrap_private_credits`, except the wrapped aleo credits is public.

Function:
```rust
transition wrap_public_credits(
    public to: address,
    public amount: field,
    public holder: address
)
```

Params:
- `to: address`: the address to receive the WALEO tokens
- `amount: field`: amount of micro-credits to be wrapped
- `holder: address`: the address to hold the wrapped aleo credits. It must be the admin of WALEO token (token-0) for safety.

Command:
```sh
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id wrap_public_credits $to_addr 10000000field $holder_addr
```

### unwrap

`unwrap` is used to unwrap WALEO tokens into aleo credits.
- The unwrapped WALEO tokens will be burned, and a pending `UnwrapItem` will be created.

Function:
```rust
unwrap(public to: address, public amount: field, public into_private: bool)
```

Params:
- `to: address`: the address to receive aleo credits
- `amount: field`: amount of micro-credits to be unwrapped
- `into_private: bool`: unwrap into private or public aleo credits

Command:
```sh
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id unwrap $to_addr 10000000field true
```

### handle_unwrap_to_private

`handle_unwrap_to_private` is used to handle a pending unwrap item, transferring private credits to the user.

Function:
```rust
handle_unwrap_to_private(public index: u64, public to: address, public amount: field) -> credits.leo/credits
```

Params:
- `index: u64`: the index of the `UnwrapItem`
- `to: address`: the address to receive aleo credits
- `amount: field`: amount of micro-credits to be transferred

Command:
```sh
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id handle_unwrap_to_private 0u64 $to_addr 10000000field
```

### handle_unwrap_to_public

`handle_unwrap_to_public` is used to handle a pending unwrap item, transferring public credits to the user.

Function:
```rust
handle_unwrap_to_public(public index: u64, public to: address, public amount: field)
```

Params:
- `index: u64`: the index of the `UnwrapItem`
- `to: address`: the address to receive aleo credits
- `amount: field`: amount of micro-credits to be transferred

Command:
```sh
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id handle_unwrap_to_public 1u64 $to_addr 10000000field
```

### swap_exact_tokens_for_tokens

`swap_exact_tokens_for_tokens` is used to exchange a fixed amount of input tokens for a variable amount of output tokens.
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

Command:
```sh
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id swap_exact_tokens_for_tokens 1field 2field 1000000u128 98000000u128 $to_addr
```

### swap_exact_private_for_public

`swap_exact_private_for_public` is used to exchange a fixed amount of private input tokens for a variable amount of public output tokens.
- Slippage can be adjusted through the parameters.
- Each swap call will charge a fee of `0.3%`.

Function:
```rust
swap_exact_private_for_public(
    private pt_in: PrivateToken,
    public token_out: field,
    public amount_in: u128,
    public amount_out_min: u128,
    public to: address,
) -> (PrivateToken)
```

Params:
- `pt_in: PrivateToken`: the PrivateToken record to be spent
- `token_out: field`: the output token id
- `amount_in: u128`: the fixed amount of input token
- `amount_out_min: u128`: the minimum amount of output token expected to receive
- `to: address`: the address to receive the output tokens
- Output 1 `PrivateToken` record: it is a new PrivateToken record (owned by the caller) with an amount of `pt_in.amount - amount_in`.

### swap_exact_private_for_private

`swap_exact_private_for_private` is used to exchange a fixed amount of private input tokens for a variable amount of private output tokens.
- Slippage can be adjusted through the parameters.
- Each swap call will charge a fee of `0.3%`.

Function:
```rust
swap_exact_private_for_private(
    private pt_in: PrivateToken,
    public token_out: field,
    public amount_in: u128,
    public amount_out_min: u128,
    private to_pri: address,
    public to_pub: address,
) -> (PrivateToken, PrivateToken)
```

Params:
- `pt_in: PrivateToken`: the PrivateToken record to be spent
- `token_out: field`: the output token id
- `amount_in: u128`: the fixed amount of input token
- `amount_out_min: u128`: the minimum amount of output token expected to receive
- `to_pri: address`: the address to receive `amount_out_min` of output tokens privately
- `to_pub: address`: the address to receive the remaining output tokens publicly
- Output 2 `PrivateToken` records: the first belongs to the receiver(`to_pri`), the second is a change and belongs to the caller

### swap_exact_public_for_private

`swap_exact_public_for_private` is used to exchange a fixed amount of public input tokens for a variable amount of private output tokens.
- Slippage can be adjusted through the parameters.
- Each swap call will charge a fee of `0.3%`.

Function:
```rust
swap_exact_public_for_private(
    public token_in: field,
    public token_out: field,
    public amount_in: u128,
    public amount_out_min: u128,
    private to_pri: address,
    public to_pub: address,
) -> (PrivateToken) {
```

Params:
- `token_in: field`: the input token id
- `token_out: field`: the output token id
- `amount_in: u128`: the fixed amount of input token
- `amount_out_min: u128`: the minimum amount of output token expected to receive
- `to_pri: address`: the address to receive `amount_out_min` of output tokens privately
- `to_pub: address`: the address to receive the remaining output tokens publicly
- Output 1 `PrivateToken` records: it is a new PrivateToken record (owned by `to_pri`) with an amount of `amount_out_min`.

### swap_tokens_for_exact_tokens

`swap_tokens_for_exact_tokens` is used to exchange a variable amounts of input token for a fixed amount of output tokens.
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

Command:
```sh
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id swap_tokens_for_exact_tokens 2field 1field 50000000u128 500000u128 $to_addr
```

### swap_private_for_exact_public

`swap_private_for_exact_public` is used to exchange a variable amount of private input tokens for a fixed amount of public output tokens.
- Slippage can be adjusted through the parameters.
- Each swap call will charge a fee of `0.3%`.

Function:
```rust
swap_private_for_exact_public(
    private pt_in: PrivateToken,
    public token_out: field,
    public amount_in_max: u128,
    public amount_out: u128,
    public to: address,
    public refund_to: address,
) -> (PrivateToken)
```

Params:
- `pt_in: PrivateToken`: the PrivateToken record to be spent, with an amount greater than or equal to `amount_in_max`
- `token_out: field`: the output token id
- `amount_in_max: u128`: the maximum amount of input token originally intended to be spent
- `amount_out: u128`: the fixed amount of output token
- `to: address`: the address to receive the public output tokens
- `refund_to: address`: the address to receive the refunded input token publicly
- Output 1 `PrivateToken` records: it is a new PrivateToken record (owned by the caller) with an amount of `pt_in.amount - amount_in_max`.

### swap_private_for_exact_private

`swap_private_for_exact_private` is used to exchange a variable amount of private input tokens for a fixed amount of private output tokens.
- Slippage can be adjusted through the parameters.
- Each swap call will charge a fee of `0.3%`.

Function:
```rust
swap_private_for_exact_private(
    private pt_in: PrivateToken,
    public token_out: field,
    public amount_in_max: u128,
    public amount_out: u128,
    private to_pri: address,
    public refund_to: address,
) -> (PrivateToken, PrivateToken)
```

Params:
- `pt_in: PrivateToken`: the PrivateToken record to be spent, with an amount greater than or equal to `amount_in_max`
- `token_out: field`: the output token id
- `amount_in_max: u128`: the maximum amount of input token originally intended to be spent
- `amount_out: u128`: the fixed amount of output token
- `to_pri: address`: the address to receive the private output tokens
- `refund_to: address`: the address to receive the refunded input token publicly
- Output 2 `PrivateToken` records: the first belongs to the receiver(`to_pri`), the second is a change and belongs to the caller

### swap_public_for_exact_private

`swap_public_for_exact_private` is used to exchange a variable amount of public input tokens for a fixed amount of private output tokens.
- Slippage can be adjusted through the parameters.
- Each swap call will charge a fee of `0.3%`.

Function:
```rust
swap_public_for_exact_private(
    public token_in: field,
    public token_out: field,
    public amount_in_max: u128,
    public amount_out: u128,
    private to_pri: address,
) -> (PrivateToken){
```

Params:
- `token_out: field`: the input token id
- `token_out: field`: the output token id
- `amount_in_max: u128`: the maximum amount of input token originally intended to be spent
- `amount_out: u128`: the fixed amount of output token
- `to_pri: address`: the address to receive the private output tokens
- Output 1 `PrivateToken` records: the first belongs to the receiver(`to_pri`), the second is a change and belongs to the caller
- Output 1 `PrivateToken` records: it is a new PrivateToken record (owned by `to_pri`) with an amount of `amount_out`.

### token_faucet

`token_faucet` is used to obtain some tokens from the token's faucet for free.
- The faucet is used to facilitate users to get test tokens, it only exists in the test network.

Function:
```rust
token_faucet(public token_id: field, public to: address)
```

Params:
- `token_id: field`: the id of the token
- `to: address`: the receiver address

Command:
```sh
snarkos developer execute -q $rpc_url -b $broadcast_url -p $private_key -r $fee_record \
  $program_id token_faucet 1field $to_addr
```

### set_token_faucet

`set_token_faucet` is used to configure the faucet amount of the token.
- Only the token's admin can successfully perform this operation.
- The faucet is used to facilitate users to get test tokens, it only exists in the test network.

Function:
```rust
set_token_faucet(public token_id: field, public amount: u128)
```

Params:
- `token_id: field`: the id of the token
- `amount: u128`: the amount of tokens the user can receive each time calling `token_faucet`. Set to 0 to turn off faucet.

### change_token_admin

`change_token_admin` is used to change the token's admin address.
- Only the token's admin can successfully perform this operation.

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

### wrap_state

`wrap_state` stores the state of WALEO (Wrapped Aleo) functions.
- mapping: `true: bool => state: WrapState`
- `WrapState` is a structure as follows:

  ```rust
  struct WrapState {
      // total count of unwraps
      unwrap_count: u64,
      // total amount of pending unwraps
      total_pending_amount: u128,
      // max operation fee for each unwrap
      unwrap_fee: u128,
  }
  ```

Query command:
```sh
curl $aleoRpc/testnet3/program/swap.aleo/mapping/wrap_state/true
```

### unwraps

`unwraps` stores all the WALEO unwrapping history (pending or handled).
- mapping: `index: u64 => item: UnwrapItem`
- `UnwrapItem` is a structure as follows:

  ```rust
  struct UnwrapItem {
    // receiver address
    to: address,
    // amount of aleo micro-credits
    amount: u128,
    // fee to the operator for handling the unwrapping
    fee: u128,
    // to private or public credits
    is_private: bool,
    // pending or handled
    is_pending: bool,
  }
  ```

Query command:
```sh
curl $aleoRpc/testnet3/program/swap.aleo/mapping/unwraps/$index
```