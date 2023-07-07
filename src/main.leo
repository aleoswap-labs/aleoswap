// The 'AleoSwap' program.
program swap.aleo {
    // (token_id, owner_address) => balance
    mapping balances: field => u128;
    // (token_id, owner_address, spender_address) => amount
    mapping allowance: field => u128;
    // token_id => TokenInfo
    mapping tokens: field => TokenInfo;
    // token_id => faucet amount 
    mapping faucets: field => u128;
    // true => GlobalState
    mapping global_state: bool => GlobalState;
    // (token_a, token_b) => Pair
    mapping pairs: field => Pair;

    record PrivateToken {
        // The token owner
        owner: address,
        // The token id
        token: field,
        // The token amount
        amount: u128,
    }

    struct TokenInfo {
        name: field,
        symbol: field,
        decimals: u8,
        total_supply: u128,
        admin: address,
    }

    struct GlobalState {
        next_token_id: field,
        admin: address,
    }

    struct BalanceKeyData {
        token: field,
        user: address,
    }

    struct AllowanceKeyData {
        token: field,
        payer: address,
        spender: address,
    }

    struct Pair {
        reserve_a: u128,
        reserve_b: u128,
    }

    struct PairKeyData {
        token_a: field,
        token_b: field,
    }

    // ========================= token =========================

    // Create a new token.
    transition create_token(public info: TokenInfo) {
        assert(info.name > 0field);
        // assert(info.total_supply <= 18446744073709551615u128);
        return then finalize(info, self.caller);
    }

    finalize create_token(public info: TokenInfo, public caller: address) {
        let gs: GlobalState = Mapping::get_or_use(global_state, true, GlobalState {
            next_token_id: 1field,
            admin: aleo1tdszx3hcgnyp2jw3y3fzvw27vremxcs24u4pys6vptg9y2jfsvps8e8ffz,
        });
        let token_id: field = gs.next_token_id;
        Mapping::set(global_state, true, GlobalState {
            next_token_id: token_id + 1field,
            admin: gs.admin,
        });
        Mapping::set(tokens, token_id, info);
        let balance_id: field = get_balance_id(token_id, caller);
        Mapping::set(balances, balance_id, info.total_supply);
    }

    // Transfer public tokens.
    transition transfer(public token_id: field, public to: address, public amount: u128) {
        return then finalize(token_id, self.caller, to, amount);
    }

    finalize transfer(public token_id: field, public from: address, public to: address, public amount: u128) {
        // confirm token exists
        assert(Mapping::contains(tokens, token_id));
        let bid_from: field = get_balance_id(token_id, from);
        let bal_from: u128 = Mapping::get(balances, bid_from);
        Mapping::set(balances, bid_from, bal_from - amount);

        let bid_to: field = get_balance_id(token_id, to);
        let bal_to: u128 = Mapping::get_or_use(balances, bid_to, 0u128);
        Mapping::set(balances, bid_to, bal_to + amount);
    }

    // Authorize other accounts to spend tokens.
    transition approve(public token_id: field, public spender: address, public amount: u128) {
        return then finalize(token_id, self.caller, spender, amount);
    }

    finalize approve(public token_id: field, public caller: address, public spender: address, public amount: u128) {
        // confirm token exists
        assert(Mapping::contains(tokens, token_id));
        let key: field = get_allowance_id(token_id, caller, spender);
        Mapping::set(allowance, key, amount);
    }

    // Transfer public tokens from other accounts.
    transition transfer_from(
        public token_id: field,
        public from: address,
        public to: address,
        public amount: u128
     ) {
        return then finalize(self.caller, token_id, from, to, amount);
    }

    finalize transfer_from(
        public caller: address,
        public token_id: field,
        public from: address,
        public to: address,
        public amount: u128
    ) {
        // confirm token exists
        assert(Mapping::contains(tokens, token_id));
        let key: field = get_allowance_id(token_id, from, caller);
        Mapping::set(allowance, key, Mapping::get(allowance, key) - amount);

        let bid_from: field = get_balance_id(token_id, from);
        Mapping::set(balances, bid_from, Mapping::get(balances, bid_from) - amount);

        let bid_to: field = get_balance_id(token_id, to);
        Mapping::set(balances, bid_to, Mapping::get_or_use(balances, bid_to, 0u128) + amount);
    }

    // ========================= token advanced =========================

    // Configure the faucet amount of the token.
    // Only the token's admin can successfully perform this operation.
    transition set_token_faucet(public token_id: field, public amount: u128) {
        return then finalize(self.caller, token_id, amount);
    }

    finalize set_token_faucet(public caller: address, public token_id: field, public amount: u128) {
        let ti: TokenInfo = Mapping::get(tokens, token_id);
        // only admin
        assert_eq(caller, ti.admin);
        Mapping::set(faucets, token_id, amount);
    }

    // Change the token's admin address.
    // Only the token's admin can successfully perform this operation.
    transition change_token_admin(public token_id: field, public admin: address) {
        return then finalize(self.caller, token_id, admin);
    }

    finalize change_token_admin(public caller: address, public token_id: field, public admin: address) {
        let ti: TokenInfo = Mapping::get(tokens, token_id);
        // only admin
        assert_eq(caller, ti.admin);
        Mapping::set(tokens, token_id, TokenInfo {
            name: ti.name,
            symbol: ti.symbol,
            decimals: ti.decimals,
            total_supply: ti.total_supply,
            admin: admin,
        });
    }

    // Obtain some tokens from the token's faucet for free.
    transition token_faucet(public token_id: field, public to: address) {
        return then finalize(token_id, to);
    }

    finalize token_faucet(public token_id: field, public to: address) {
        let amount: u128 = Mapping::get(faucets, token_id);
        assert(amount > 0u128);
        let ti: TokenInfo = Mapping::get(tokens, token_id);
        // mint
        Mapping::set(tokens, token_id, TokenInfo {
            name: ti.name,
            symbol: ti.symbol,
            decimals: ti.decimals,
            total_supply: ti.total_supply + amount,
            admin: ti.admin,
        });
        // update balance
        let bid_to: field = get_balance_id(token_id, to);
        Mapping::set(balances, bid_to, Mapping::get_or_use(balances, bid_to, 0u128) + amount);
    }

    // ========================= admin =========================

    // Change the main admin of the program.
    transition change_admin(public admin: address) {
        return then finalize(self.caller, admin);
    }

    finalize change_admin(public caller: address, public admin: address) {
        let gs: GlobalState = Mapping::get_or_use(global_state, true, GlobalState {
            next_token_id: 1field,
            admin: aleo1tdszx3hcgnyp2jw3y3fzvw27vremxcs24u4pys6vptg9y2jfsvps8e8ffz,
        });
        assert_eq(caller, gs.admin);
        Mapping::set(global_state, true, GlobalState {
            next_token_id: gs.next_token_id,
            admin: admin,
        });
    }

    // ========================= private token =========================

    // Transfer and convert public tokens to a new private token record (PrivateToken).
    transition transfer_to_private(public token_id: field, private to: address, public amount: u128) -> PrivateToken {
        // mint a new private token
        let pt: PrivateToken = PrivateToken {
            owner: to,
            token: token_id,
            amount: amount,
        };
        let test_hash: field = BHP256::hash_to_field(pt);
        return pt then finalize(token_id, self.caller, amount);
    }

    finalize transfer_to_private(public token_id: field, public from: address, public amount: u128) {
        // confirm token exists
        assert(Mapping::contains(tokens, token_id));
        let bid_from: field = get_balance_id(token_id, from);
        Mapping::set(balances, bid_from, Mapping::get(balances, bid_from) - amount);
    }

    // Transfer and convert a private token record (`PrivateToken`) to public tokens.
    transition transfer_to_public(private pt_in: PrivateToken, public to: address, public amount: u128) -> PrivateToken {
        let pt_change: PrivateToken = PrivateToken {
            owner: pt_in.owner,
            token: pt_in.token,
            amount: pt_in.amount - amount,
        };
        return pt_change then finalize(pt_in.token, to, amount);
    }

    finalize transfer_to_public(public token_id: field, public to: address, public amount: u128) {
        // confirm token exists
        assert(Mapping::contains(tokens, token_id));
        let bid_to: field = get_balance_id(token_id, to);
        Mapping::set(balances, bid_to, Mapping::get_or_use(balances, bid_to, 0u128) + amount);
    }

    // Transfer private tokens (`PrivateToken` records).
    transition transfer_privately(private pt_in: PrivateToken, private to: address, private amount: u128) -> (PrivateToken, PrivateToken) {
        let pt_to: PrivateToken = PrivateToken {
            owner: to,
            token: pt_in.token,
            amount: amount,
        };

        let pt_change: PrivateToken = PrivateToken {
            owner: pt_in.owner,
            token: pt_in.token,
            amount: pt_in.amount - amount,
        };
        return (pt_to, pt_change);
    }

    // Merge two `PrivateToken` records into a new `PrivateToken` record.
    // The two records being joined must have the same owner and the token id.
    transition join(private pt1: PrivateToken, private pt2: PrivateToken) -> PrivateToken {
        assert_eq(pt1.token, pt2.token);
        // the following should always be true
        // assert_eq(pt1.owner, pt2.owner);
        // assert_eq(pt1.owner, self.caller);
        return PrivateToken {
            owner: pt1.owner,
            token: pt1.token,
            amount: pt1.amount + pt2.amount,
        };
    }

    // ========================= liquidity =========================

    // Create a new pair and add initial liquidity.
    // A pair must be created through this function before subsequent liquidity and swap operations can be performed.
    // Each pair is also a standard token (called liquidity pool token or LP token) created automatically when the pair is created,
    // and its token_id is the same as pair_id: `lp_token_id = pair_id = bhp256_hash({token_a: field, token_b: field})`.
    // The caller's token_a and token_b will be transferred to the program, and LP tokens will be minted to the `to` address.
    transition create_pair(
        public token_a: field,
        public token_b: field,
        public amount_a: u128,
        public amount_b: u128,
        public to: address
     ) {
        assert(token_a < token_b);
        assert(amount_a > 0u128);
        assert(amount_b > 0u128);
        return then finalize(self.caller, token_a, token_b, amount_a, amount_b, to);
    }

    finalize create_pair(
        public caller: address,
        public token_a: field,
        public token_b: field,
        public amount_a: u128,
        public amount_b: u128,
        public to: address
    ) {
        let pid: field = get_pair_id(token_a, token_b);
        let liquidity: u128 = sqrt_u128(amount_a * amount_b);
        assert(liquidity > 0u128);

        let ti_pair: TokenInfo = Mapping::get_or_use(tokens, pid, TokenInfo {
            name: 5183377571718029925300968712562field, // AleoSwap-Pair
            symbol: 4281168field, // ASP
            decimals: 6u8,
            total_supply: 0u128,
            admin: aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc,
        });
        assert_eq(ti_pair.total_supply, 0u128);

        let pair: Pair = Mapping::get_or_use(pairs, pid, Pair {
            reserve_a: 0u128,
            reserve_b: 0u128,
        });


        // update balances
        let bid_a: field = get_balance_id(token_a, caller);
        Mapping::set(balances, bid_a, Mapping::get(balances, bid_a) - amount_a);
        let bid_b: field = get_balance_id(token_b, caller);
        Mapping::set(balances, bid_b, Mapping::get(balances, bid_b) - amount_b);

        // mint liquidity
        let bid_p: field = get_balance_id(pid, to);
        Mapping::set(balances, bid_p, Mapping::get_or_use(balances, bid_p, 0u128) + liquidity);
        Mapping::set(tokens, pid, TokenInfo {
            name: ti_pair.name,
            symbol: ti_pair.symbol,
            decimals: ti_pair.decimals,
            total_supply: ti_pair.total_supply + liquidity,
            admin: ti_pair.admin,
        });

        // update pair
        Mapping::set(pairs, pid, Pair {
            reserve_a: pair.reserve_a + amount_a,
            reserve_b: pair.reserve_b + amount_b,
        });
    }

    // Add liquidity to a pair.
    // The caller's `token_a` and `token_b` will be transferred to the program, and LP tokens will be minted to the `to` address.
    transition add_liquidity(
        public token_a: field,
        public token_b: field,
        public amount_a: u128,
        public amount_b: u128,
        public min_a: u128,
        public min_b: u128,
        public to: address
     ) {
        assert(token_a < token_b);
        assert(amount_a > 0u128 && amount_a >= min_a);
        assert(amount_b > 0u128 && amount_b >= min_b);
        return then finalize(self.caller, token_a, token_b, amount_a, amount_b, min_a, min_b, to);
    }

    finalize add_liquidity(
        public caller: address,
        public token_a: field,
        public token_b: field,
        public amount_a: u128,
        public amount_b: u128,
        public min_a: u128,
        public min_b: u128,
        public to: address
    ) {
        let pid: field = get_pair_id(token_a, token_b);
        let pair: Pair = Mapping::get(pairs, pid);
        let ti_pair: TokenInfo = Mapping::get(tokens, pid);
        let liq_a: u128 = amount_a * ti_pair.total_supply / pair.reserve_a;
        let liq_b: u128 = amount_b * ti_pair.total_supply / pair.reserve_b;
        let liquidity: u128 = liq_a <= liq_b ? liq_a : liq_b;
        amount_a = liq_a <= liquidity
                ? amount_a
                : (liquidity * pair.reserve_a + ti_pair.total_supply - 1u128) / ti_pair.total_supply;
        amount_b = liq_b <= liquidity
                ? amount_b
                : (liquidity * pair.reserve_b + ti_pair.total_supply - 1u128) / ti_pair.total_supply;
        assert(liquidity > 0u128);
        assert(amount_a >= min_a);
        assert(amount_b >= min_b);

        // update balances
        let bid_a: field = get_balance_id(token_a, caller);
        Mapping::set(balances, bid_a, Mapping::get(balances, bid_a) - amount_a);
        let bid_b: field = get_balance_id(token_b, caller);
        Mapping::set(balances, bid_b, Mapping::get(balances, bid_b) - amount_b);

        // mint liquidity
        let bid_p: field = get_balance_id(pid, to);
        Mapping::set(balances, bid_p, Mapping::get_or_use(balances, bid_p, 0u128) + liquidity);
        Mapping::set(tokens, pid, TokenInfo {
            name: ti_pair.name,
            symbol: ti_pair.symbol,
            decimals: ti_pair.decimals,
            total_supply: ti_pair.total_supply + liquidity,
            admin: ti_pair.admin,
        });

        // update pair
        Mapping::set(pairs, pid, Pair {
            reserve_a: pair.reserve_a + amount_a,
            reserve_b: pair.reserve_b + amount_b,
        });
    }

    // Remove liquidity from a pair.
    // The caller's LP tokens will be burned, `token_a` and `token_b` will be transferred to the `to` address.
    transition remove_liquidity(
        public token_a: field,
        public token_b: field,
        public liquidity: u128,
        public min_a: u128,
        public min_b: u128,
        public to: address,
     ) {
        assert(token_a < token_b);
        assert(liquidity > 0u128);
        return then finalize(self.caller, token_a, token_b, liquidity, min_a, min_b, to);
    }

    finalize remove_liquidity(
        public caller: address,
        public token_a: field,
        public token_b: field,
        public liquidity: u128,
        public min_a: u128,
        public min_b: u128,
        public to: address,
    ) {
        let pid: field = get_pair_id(token_a, token_b);
        let ti_pair: TokenInfo = Mapping::get(tokens, pid);
        let pair: Pair = Mapping::get(pairs, pid);

        // calculate token amounts
        let amount_a: u128 = liquidity * pair.reserve_a / ti_pair.total_supply;
        let amount_b: u128 = liquidity * pair.reserve_b / ti_pair.total_supply;
        assert(amount_a >= min_a && amount_b >= min_b);
        assert(amount_a > 0u128 || amount_b > 0u128);

        // burn liquidity
        let bid_p: field = get_balance_id(pid, caller);
        Mapping::set(balances, bid_p, Mapping::get(balances, bid_p) - liquidity);
        Mapping::set(tokens, pid, TokenInfo {
            name: ti_pair.name,
            symbol: ti_pair.symbol,
            decimals: ti_pair.decimals,
            total_supply: ti_pair.total_supply - liquidity,
            admin: ti_pair.admin,
        });

        // update pair
        Mapping::set(pairs, pid, Pair {
            reserve_a: pair.reserve_a - amount_a,
            reserve_b: pair.reserve_b - amount_b,
        });

        // send tokens
        let bid_a: field = get_balance_id(token_a, to);
        let bid_b: field = get_balance_id(token_b, to);
        Mapping::set(balances, bid_a, Mapping::get_or_use(balances, bid_a, 0u128) + amount_a);
        Mapping::set(balances, bid_b, Mapping::get_or_use(balances, bid_b, 0u128) + amount_b);
    }

    // ========================= swap =========================

    // Exchange a fixed amount of input token for a variable amount of output token.
    transition swap_exact_tokens_for_tokens(
        public token_in: field,
        public token_out: field,
        public amount_in: u128,
        public amount_out_min: u128,
        public to: address,
     ) {
        assert(token_in != token_out);
        assert(amount_in > 0u128);
        return then finalize(self.caller, token_in, token_out, amount_in, amount_out_min, to);
    }

    finalize swap_exact_tokens_for_tokens(
        public caller: address,
        public token_in: field,
        public token_out: field,
        public amount_in: u128,
        public amount_out_min: u128,
        public to: address,
    ) {
        let token_a: field = token_in < token_out ? token_in : token_out;
        let token_b: field = token_in < token_out ? token_out : token_in;
        let pid: field = get_pair_id(token_a, token_b);
        let pair: Pair = Mapping::get(pairs, pid);

        // calculate output amount
        let reserve_in: u128 = token_a == token_in ? pair.reserve_a : pair.reserve_b;
        let reserve_out: u128 = token_a == token_out ? pair.reserve_a : pair.reserve_b;
        let amount_in_with_fee: u128 = amount_in * 997u128;
        let amount_out: u128 = amount_in_with_fee * reserve_out / (reserve_in * 1000u128 + amount_in_with_fee);
        assert(amount_out >= amount_out_min);
        assert(amount_out > 0u128);

        // transfer input token
        let bid_in: field = get_balance_id(token_in, caller);
        Mapping::set(balances, bid_in, Mapping::get(balances, bid_in) - amount_in);

        // update pair
        let reserve_in_new: u128 = reserve_in + amount_in;
        let reserve_out_new: u128 = reserve_out - amount_out;
        Mapping::set(pairs, pid, Pair {
            reserve_a: token_a == token_in ? reserve_in_new : reserve_out_new,
            reserve_b: token_b == token_in ? reserve_in_new : reserve_out_new,
        });

        // transfer output token
        let bid_out: field = get_balance_id(token_out, to);
        Mapping::set(balances, bid_out, Mapping::get_or_use(balances, bid_out, 0u128) + amount_out);
    }

    // Exchange a variable amount of input token for a fixed amount of output token.
    transition swap_tokens_for_exact_tokens(
        public token_in: field,
        public token_out: field,
        public amount_in_max: u128,
        public amount_out: u128,
        public to: address,
     ) {
        assert(token_in != token_out);
        assert(amount_out > 0u128);
        return then finalize(self.caller, token_in, token_out, amount_in_max, amount_out, to);
    }

    finalize swap_tokens_for_exact_tokens(
        public caller: address,
        public token_in: field,
        public token_out: field,
        public amount_in_max: u128,
        public amount_out: u128,
        public to: address,
    ) {
        let token_a: field = token_in < token_out ? token_in : token_out;
        let token_b: field = token_in < token_out ? token_out : token_in;
        let pid: field = get_pair_id(token_a, token_b);
        let pair: Pair = Mapping::get(pairs, pid);

        // calculate input amount
        let reserve_in: u128 = token_a == token_in ? pair.reserve_a : pair.reserve_b;
        let reserve_out: u128 = token_a == token_out ? pair.reserve_a : pair.reserve_b;
        let amount_in: u128 = reserve_in * amount_out * 1000u128 / ((reserve_out - amount_out) * 997u128) + 1u128;
        assert(amount_in <= amount_in_max);
        assert(amount_in > 0u128);

        // transfer input token
        let bid_in: field = get_balance_id(token_in, caller);
        Mapping::set(balances, bid_in, Mapping::get(balances, bid_in) - amount_in);

        // update pair
        let reserve_in_new: u128 = reserve_in + amount_in;
        let reserve_out_new: u128 = reserve_out - amount_out;
        Mapping::set(pairs, pid, Pair {
            reserve_a: token_a == token_in ? reserve_in_new : reserve_out_new,
            reserve_b: token_b == token_in ? reserve_in_new : reserve_out_new,
        });

        // transfer output token
        let bid_out: field = get_balance_id(token_out, to);
        Mapping::set(balances, bid_out, Mapping::get_or_use(balances, bid_out, 0u128) + amount_out);
    }

    // ========================= inline =========================

    inline get_balance_id(token_: field, user_: address) -> field {
        // copy to avoid compiling error
        let token: field = token_;
        let user: address = user_;
        return BHP256::hash_to_field(BalanceKeyData {token, user});
    }

    inline get_allowance_id(token_id_: field, payer_: address, spender_: address) -> field {
        let token: field = token_id_;
        let payer: address = payer_;
        let spender: address = spender_;
        // copy to avoid compiling error
        return BHP256::hash_to_field(AllowanceKeyData {token, payer, spender});
    }

    inline get_pair_id(token_a_: field, token_b_: field) -> field {
        // copy to avoid compiling error
        let token_a: field = token_a_;
        let token_b: field = token_b_;
        assert(token_a < token_b);
        return  BHP256::hash_to_field(PairKeyData {token_a, token_b});
    }

    // Same as Math.sol:sqrt()
    inline sqrt_u128(a: u128) -> u128 {
        if (a == 0u128) {
            return 0u128;
        }
        let result: u128 = 1u128.shl(log2(a) / 2u32);

        result = (result + a / result) >> 1u32;
        result = (result + a / result) >> 1u32;
        result = (result + a / result) >> 1u32;
        result = (result + a / result) >> 1u32;
        result = (result + a / result) >> 1u32;
        result = (result + a / result) >> 1u32;
        result = (result + a / result) >> 1u32;
        return min_u128(result, a / result);
    }

    inline log2(value: u128) -> u32 {
        let result: u32 = 0u32;
        // if value >> 128u32 > 0u128 {
        //     value >>= 128u32;
        //     result += 12832;
        // }
        if value >> 64u32 > 0u128 {
            value >>= 64u32;
            result += 64u32;
        }
        if value >> 32u32 > 0u128 {
            value >>= 32u32;
            result += 32u32;
        }
        if value >> 16u32 > 0u128 {
            value >>= 16u32;
            result += 16u32;
        }
        if value >> 8u32 > 0u128 {
            value >>= 8u32;
            result += 8u32;
        }
        if value >> 4u32 > 0u128 {
            value >>= 4u32;
            result += 4u32;
        }
        if value >> 2u32 > 0u128 {
            value >>= 2u32;
            result += 2u32;
        }
        if value >> 1u32 > 0u128 {
            result += 1u32;
        }
        return result;
    }

    inline min_u128(a: u128, b: u128) -> u128 {
        return a < b ? a : b;
    }
}
