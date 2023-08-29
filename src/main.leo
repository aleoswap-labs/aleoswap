import credits.leo;

// The 'AleoSwap' program.
program aleoswap05.aleo {
    // BalanceKeyData => balance
    mapping balances: field => u128;
    // AllowanceKeyData => amount
    mapping allowance: field => u128;
    // token_id => TokenInfo
    mapping tokens: field => TokenInfo;
    // token_id => faucet amount
    mapping faucets: field => u128;
    // true => GlobalState
    mapping global_state: bool => GlobalState;
    // PairKeyData => Pair
    mapping pairs: field => Pair;
    // index => UnwrapItem
    mapping unwraps: u64 => UnwrapItem;
    // true => WrapState
    mapping wrap_state: bool => WrapState;

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
        // The id of token to be created by the next call to create_token
        next_token_id: field,
        admin: address,
    }

    struct BalanceKeyData {
        token: field,
        user: address,
    }

    // Mapping key of allowance
    struct AllowanceKeyData {
        token: field,
        payer: address,
        spender: address,
    }

    struct Pair {
        reserve_a: u128,
        reserve_b: u128,
    }

    // Mapping key of pairs
    struct PairKeyData {
        token_a: field,
        token_b: field,
    }

    struct WrapState {
        // total count of unwraps
        unwrap_count: u64,
        // total amount of pending unwraps
        total_pending_amount: u128,
        // max operation fee for each unwrap
        unwrap_fee: u128,
    }

    struct UnwrapItem {
        // receiver address
        to: address,
        // amount of aleo micro-credits
        amount: u128,
        // fee to the operator for handling the unwrapping
        fee: u128,
        // to private or public credits
        is_private: bool,
        // pending or dealed
        is_pending: bool,
    }

    // ========================= token =========================

    // Create a new token.
    transition create_token(public info: TokenInfo) {
        assert(info.name > 0field);
        // assert(info.total_supply <= 18446744073709551615u128);
        return then finalize(info, self.caller);
    }

    finalize create_token(public info: TokenInfo, public caller: address) {
        let gs: GlobalState = Mapping::get(global_state, true);
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
        // can not set faucet for WALEO
        assert(token_id != 0field);
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

    // ========================= WALEO =========================

    // Wrap private aleo credits into WALEO tokens.
    transition wrap_private_credits(
        private input: credits.leo/credits,
        public to: address,
        public amount: field,
        public holder: address
    ) -> (credits.leo/credits) {
        assert(amount > 0field && amount <= 18446744073709551615field);
        let aleo_change: credits = credits.leo/transfer_private_to_public(input, holder, amount as u64);
        return aleo_change then finalize(to, amount as u128, holder);
    }

    finalize wrap_private_credits(public to: address, public amount: u128, public holder: address) {
        let token_id: field = 0field;
        let ti: TokenInfo = Mapping::get(tokens, token_id);
        // check holder
        assert_eq(holder, ti.admin);
        // mint WALEO
        Mapping::set(tokens, token_id, TokenInfo {
            name: ti.name,
            symbol: ti.symbol,
            decimals: ti.decimals,
            total_supply: ti.total_supply + amount,
            admin: ti.admin,
        });
        // update balance
        let bid : field = get_balance_id(token_id, to);
        Mapping::set(balances, bid, Mapping::get_or_use(balances, bid, 0u128) + amount);
    }

    // Wrap public aleo credits into WALEO tokens.
    transition wrap_public_credits(
        public to: address,
        public amount: field,
        public holder: address
    ) {
        assert(amount > 0field && amount <= 18446744073709551615field);
        credits.leo/transfer_public(holder, amount as u64);
        return then finalize(to, amount as u128, holder);
    }

    finalize wrap_public_credits(public to: address, public amount: u128, public holder: address) {
        let token_id: field = 0field;
        let ti: TokenInfo = Mapping::get(tokens, token_id);
        // check holder
        assert_eq(holder, ti.admin);
        // mint WALEO
        Mapping::set(tokens, token_id, TokenInfo {
            name: ti.name,
            symbol: ti.symbol,
            decimals: ti.decimals,
            total_supply: ti.total_supply + amount,
            admin: ti.admin,
        });
        // update balance
        let bid : field = get_balance_id(token_id, to);
        Mapping::set(balances, bid, Mapping::get_or_use(balances, bid, 0u128) + amount);
    }

    // Request to unwrap WALEO tokens into aleo credits.
    // The WALEO tokens will be burned, and a pending unwrap item will be created.
    transition unwrap(public to: address, public amount: field, public into_private: bool) {
        assert(amount > 0field && amount <= 18446744073709551615field);
        return then finalize(self.caller, to, amount as u128, into_private);
    }

    finalize unwrap(public caller: address, public to: address, public amount: u128, public into_private: bool) {
        let ws: WrapState = Mapping::get(wrap_state, true);
        assert(amount > ws.unwrap_fee);

        let token_id: field = 0field;
        let ti: TokenInfo = Mapping::get(tokens, token_id);
        // burn WALEO
        Mapping::set(tokens, token_id, TokenInfo {
            name: ti.name,
            symbol: ti.symbol,
            decimals: ti.decimals,
            total_supply: ti.total_supply - amount,
            admin: ti.admin,
        });
        // update balance
        let bid : field = get_balance_id(token_id, caller);
        Mapping::set(balances, bid, Mapping::get_or_use(balances, bid, 0u128) - amount);

        // add the pending item to the mapping
        Mapping::set(unwraps, ws.unwrap_count, UnwrapItem {
            to: to,
            amount: amount,
            fee: ws.unwrap_fee,
            is_private: into_private,
            is_pending: true,
        });
        // update wrap state
        Mapping::set(wrap_state, true, WrapState {
            unwrap_count: ws.unwrap_count + 1u64,
            total_pending_amount: ws.total_pending_amount + amount,
            unwrap_fee: ws.unwrap_fee,
        });
    }

    // Handle a pending unwrap item, transfer private credits to user.
    transition handle_unwrap_to_private(public index: u64, public to: address, public amount: field) -> credits.leo/credits {
        let unwrapped: credits = credits.leo/transfer_public_to_private(to, amount as u64);
        return unwrapped then finalize(index, to, amount as u128);
    }

    finalize handle_unwrap_to_private(public index: u64, public to: address, public amount: u128) {
        // check params
        let ui: UnwrapItem = Mapping::get(unwraps, index);
        assert_eq(ui.to, to);
        assert(amount >= ui.amount - ui.fee);
        assert_eq(ui.is_private, true);
        assert_eq(ui.is_pending, true);

        // unset the pending flag
        Mapping::set(unwraps, index, UnwrapItem {
            to: ui.to,
            amount: ui.amount,
            fee: ui.fee,
            is_private: ui.is_private,
            is_pending: false,
        });

        // update wrap state
        let ws: WrapState = Mapping::get(wrap_state, true);
        Mapping::set(wrap_state, true, WrapState {
            unwrap_count: ws.unwrap_count,
            total_pending_amount: ws.total_pending_amount - amount,
            unwrap_fee: ws.unwrap_fee,
        });
    }

    // Handle a pending unwrap item, transfer public credits to user.
    transition handle_unwrap_to_public(public index: u64, public to: address, public amount: field) {
        credits.leo/transfer_public(to, amount as u64);
        return then finalize(index, to, amount as u128);
    }

    finalize handle_unwrap_to_public(public index: u64, public to: address, public amount: u128) {
        // check params
        let ui: UnwrapItem = Mapping::get(unwraps, index);
        assert_eq(ui.to, to);
        assert(amount >= ui.amount - ui.fee);
        assert_eq(ui.is_private, false);
        assert_eq(ui.is_pending, true);

        // unset the pending flag
        Mapping::set(unwraps, index, UnwrapItem {
            to: ui.to,
            amount: ui.amount,
            fee: ui.fee,
            is_private: ui.is_private,
            is_pending: false,
        });

        // update global unwrap state
        let ws: WrapState = Mapping::get(wrap_state, true);
        Mapping::set(wrap_state, true, WrapState {
            unwrap_count: ws.unwrap_count,
            total_pending_amount: ws.total_pending_amount - amount,
            unwrap_fee: ws.unwrap_fee,
        });
    }


    // Set unwrap fee of waleo
    transition set_unwrap_fee(public fee: u128) {
        assert(fee < 10000000u128);
        return then finalize(self.caller, fee);
    }

    finalize set_unwrap_fee(public caller: address, public fee: u128) {
        let ti: TokenInfo = Mapping::get(tokens, 0field);
        assert_eq(caller, ti.admin);
        let ws: WrapState = Mapping::get(wrap_state, true);
        Mapping::set(wrap_state, true, WrapState {
            unwrap_count: ws.unwrap_count,
            total_pending_amount: ws.total_pending_amount,
            unwrap_fee: fee,
        });
    }

    // ========================= admin =========================

    // Initialize the program after deployment.
    transition init(public b: bool) {
        return then finalize(self.caller);
    }

    finalize init(public caller: address) {
        // init global state
        let gs: GlobalState = Mapping::get_or_use(global_state, true, GlobalState {
            next_token_id: 0field,
            admin: aleo1tdszx3hcgnyp2jw3y3fzvw27vremxcs24u4pys6vptg9y2jfsvps8e8ffz,
        });
        assert_eq(gs.next_token_id, 0field);
        assert_eq(caller, gs.admin);
        Mapping::set(global_state, true, GlobalState {
            next_token_id: 1field,
            admin: gs.admin,
        });

        // init WALEO token
        Mapping::set(tokens, 0field, TokenInfo {
            name: 105716693521782238488585583field,
            symbol: 374757672271field,
            decimals: 6u8,
            total_supply: 0u128,
            admin: aleo1tdszx3hcgnyp2jw3y3fzvw27vremxcs24u4pys6vptg9y2jfsvps8e8ffz,
        });

        // init unwrap states
        Mapping::set(wrap_state, true, WrapState {
            unwrap_count: 0u64,
            total_pending_amount: 0u128,
            unwrap_fee: 0u128,
        });
    }

    // Change the main admin of the program.
    transition change_admin(public admin: address) {
        return then finalize(self.caller, admin);
    }

    finalize change_admin(public caller: address, public admin: address) {
        let gs: GlobalState = Mapping::get(global_state, true);
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

    // Create a new pair and add initial liquidity privately.
    transition create_pair_privately(
        private pt_a: PrivateToken,
        private pt_b: PrivateToken,
        public amount_a: u128,
        public amount_b: u128,
        private to: address,
        public liquidity: u128,
     ) -> (PrivateToken, PrivateToken, PrivateToken) {
        let token_a: field = pt_a.token;
        let token_b: field = pt_b.token;
        assert(token_a < token_b);
        assert(amount_a > 0u128);
        assert(amount_b > 0u128);
        assert(liquidity > 0u128);
        let change_a: PrivateToken = PrivateToken {
            owner: pt_a.owner,
            token: token_a,
            amount: pt_a.amount - amount_a,
        };
        let change_b: PrivateToken = PrivateToken {
            owner: pt_b.owner,
            token: token_b,
            amount: pt_b.amount - amount_b,
        };

        let pid: field = get_pair_id(token_a, token_b);
        let pt_lp: PrivateToken = PrivateToken {
            owner: to,
            token: pid,
            amount: liquidity,
        };
        return (pt_lp, change_a, change_b) then finalize(token_a, token_b, amount_a, amount_b, pid, liquidity);
    }

    finalize create_pair_privately(
        public token_a: field,
        public token_b: field,
        public amount_a: u128,
        public amount_b: u128,
        public pid: field,
        public liquidity_in: u128,
    ) {
        let liquidity: u128 = sqrt_u128(amount_a * amount_b);
        assert(liquidity_in == liquidity);

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

        // mint liquidity
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

    // Add liquidity to a pair privately.
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
     ) -> (PrivateToken, PrivateToken, PrivateToken) {
        let token_a: field = pt_a.token;
        let token_b: field = pt_b.token;
        assert(token_a < token_b);
        assert(amount_a > 0u128 && amount_a >= min_a);
        assert(amount_b > 0u128 && amount_b >= min_b);
        assert(min_liquidity > 0u128);

        // change
        let change_a: PrivateToken = PrivateToken {
            owner: pt_a.owner,
            token: token_a,
            amount: pt_a.amount - amount_a,
        };
        let change_b: PrivateToken = PrivateToken {
            owner: pt_b.owner,
            token: token_b,
            amount: pt_b.amount - amount_b,
        };

        // mint lp token
        let pid: field = get_pair_id(token_a, token_b);
        let pt_lp: PrivateToken = PrivateToken {
            owner: to,
            token: pid,
            amount: min_liquidity,
        };

        return (pt_lp, change_a, change_b) then finalize(token_a, token_b, pid, amount_a, amount_b, min_a, min_b, min_liquidity, refund_to);
    }

    finalize add_liquidity_privately(
        public token_a: field,
        public token_b: field,
        public pid: field,
        public amount_a: u128,
        public amount_b: u128,
        public min_a: u128,
        public min_b: u128,
        public min_liquidity: u128,
        public refund_to: address,
    ) {
        let pair: Pair = Mapping::get(pairs, pid);
        let ti_pair: TokenInfo = Mapping::get(tokens, pid);
        let liq_a: u128 = amount_a * ti_pair.total_supply / pair.reserve_a;
        let liq_b: u128 = amount_b * ti_pair.total_supply / pair.reserve_b;
        let liquidity: u128 = liq_a <= liq_b ? liq_a : liq_b;
        let amount_a_used: u128 = liq_a <= liquidity
                ? amount_a
                : (liquidity * pair.reserve_a + ti_pair.total_supply - 1u128) / ti_pair.total_supply;
        let amount_b_used: u128 = liq_b <= liquidity
                ? amount_b
                : (liquidity * pair.reserve_b + ti_pair.total_supply - 1u128) / ti_pair.total_supply;
        assert(liquidity >= min_liquidity);
        assert(amount_a >= amount_a_used && amount_a_used >= min_a);
        assert(amount_b >= amount_b_used && amount_b_used >= min_b);

        // refund tokens
        let bid_a: field = get_balance_id(token_a, refund_to);
        Mapping::set(balances, bid_a, Mapping::get_or_use(balances, bid_a, 0u128) + amount_a - amount_a_used);
        let bid_b: field = get_balance_id(token_b, refund_to);
        Mapping::set(balances, bid_b, Mapping::get_or_use(balances, bid_b, 0u128) + amount_b - amount_b_used);

        // refund liquidity
        let bid_p: field = get_balance_id(pid, refund_to);
        Mapping::set(balances, bid_p, Mapping::get_or_use(balances, bid_p, 0u128) + liquidity - min_liquidity);

        // set liquidity supply
        Mapping::set(tokens, pid, TokenInfo {
            name: ti_pair.name,
            symbol: ti_pair.symbol,
            decimals: ti_pair.decimals,
            total_supply: ti_pair.total_supply + liquidity,
            admin: ti_pair.admin,
        });

        // update pair
        Mapping::set(pairs, pid, Pair {
            reserve_a: pair.reserve_a + amount_a_used,
            reserve_b: pair.reserve_b + amount_b_used,
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

    // Remove liquidity from a pair.
    transition remove_liquidity_privately(
        public token_a: field,
        public token_b: field,
        private pt_lp: PrivateToken,
        public liquidity: u128,
        public min_a: u128,
        public min_b: u128,
        private to: address,
        public refund_to: address,
     ) -> (PrivateToken, PrivateToken, PrivateToken) {
        assert(token_a < token_b);
        assert(liquidity > 0u128);
        let pid: field = get_pair_id(token_a, token_b);
        // check pair id and lp token
        assert_eq(pid, pt_lp.token);

        // mint tokens
        let pt_a: PrivateToken = PrivateToken {
            owner: to,
            token: token_a,
            amount: min_a,
        };
        let pt_b: PrivateToken = PrivateToken {
            owner: to,
            token: token_b,
            amount: min_b,
        };

        // change
        let change_lp: PrivateToken = PrivateToken {
            owner: pt_lp.owner,
            token: pid,
            amount: pt_lp.amount - liquidity,
        };

        return (pt_a, pt_b, change_lp) then finalize(token_a, token_b, pid, liquidity, min_a, min_b, refund_to);
    }

    finalize remove_liquidity_privately(
        public token_a: field,
        public token_b: field,
        public pid: field,
        public liquidity: u128,
        public min_a: u128,
        public min_b: u128,
        public refund_to: address,
    ) {
        let ti_pair: TokenInfo = Mapping::get(tokens, pid);
        let pair: Pair = Mapping::get(pairs, pid);

        // calculate token amounts
        let amount_a: u128 = liquidity * pair.reserve_a / ti_pair.total_supply;
        let amount_b: u128 = liquidity * pair.reserve_b / ti_pair.total_supply;
        assert(amount_a >= min_a && amount_b >= min_b);
        assert(amount_a > 0u128 || amount_b > 0u128);

        // liquidity has been burned privately

        // update pair
        Mapping::set(tokens, pid, TokenInfo {
            name: ti_pair.name,
            symbol: ti_pair.symbol,
            decimals: ti_pair.decimals,
            total_supply: ti_pair.total_supply - liquidity,
            admin: ti_pair.admin,
        });
        Mapping::set(pairs, pid, Pair {
            reserve_a: pair.reserve_a - amount_a,
            reserve_b: pair.reserve_b - amount_b,
        });

        // refund tokens
        let bid_a: field = get_balance_id(token_a, refund_to);
        let bid_b: field = get_balance_id(token_b, refund_to);
        Mapping::set(balances, bid_a, Mapping::get_or_use(balances, bid_a, 0u128) + amount_a - min_a);
        Mapping::set(balances, bid_b, Mapping::get_or_use(balances, bid_b, 0u128) + amount_b - min_b);
    }

    // ========================= swap exact =========================

    // Exchange a fixed amount of public input tokens for a variable amount of public output tokens.
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

    // Exchange a fixed amount of private input tokens for a variable amount of public output tokens.
    transition swap_exact_private_for_public(
        private pt_in: PrivateToken,
        public token_out: field,
        public amount_in: u128,
        public amount_out_min: u128,
        public to: address,
     ) -> (PrivateToken) {
        let token_in: field = pt_in.token;
        assert(token_in != token_out);
        assert(amount_in > 0u128);

        let change_in: PrivateToken = PrivateToken {
            owner: pt_in.owner,
            token: token_in,
            amount: pt_in.amount - amount_in,
        };
        return change_in then finalize(token_in, token_out, amount_in, amount_out_min, to);
    }

    finalize swap_exact_private_for_public(
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

        // input token has been transferred privately

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

    // Exchange a fixed amount of private input tokens for a variable amount of private output tokens.
    transition swap_exact_private_for_private(
        private pt_in: PrivateToken,
        public token_out: field,
        public amount_in: u128,
        public amount_out_min: u128,
        private to_pri: address,
        public to_pub: address,
     ) -> (PrivateToken, PrivateToken) {
        let token_in: field = pt_in.token;
        assert(token_in != token_out);
        assert(amount_in > 0u128);
        let pt_out: PrivateToken = PrivateToken {
            owner: to_pri,
            token: token_out,
            amount: amount_out_min,
        };
        let change_in: PrivateToken = PrivateToken {
            owner: pt_in.owner,
            token: token_in,
            amount: pt_in.amount - amount_in,
        };
        return (pt_out, change_in) then finalize(token_in, token_out, amount_in, amount_out_min, to_pub);
    }

    finalize swap_exact_private_for_private(
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

        // input token has been transferred privately

        // update pair
        let reserve_in_new: u128 = reserve_in + amount_in;
        let reserve_out_new: u128 = reserve_out - amount_out;
        Mapping::set(pairs, pid, Pair {
            reserve_a: token_a == token_in ? reserve_in_new : reserve_out_new,
            reserve_b: token_b == token_in ? reserve_in_new : reserve_out_new,
        });

        // transfer output token (minus the private part)
        let bid_out: field = get_balance_id(token_out, to);
        let amount_out_diff: u128 = amount_out - amount_out_min;
        Mapping::set(balances, bid_out, Mapping::get_or_use(balances, bid_out, 0u128) + amount_out_diff);
    }

    // // Exchange a fixed amount of public input tokens for a variable amount of private output tokens.
    // transition swap_exact_public_for_private(
    //     public token_in: field,
    //     public token_out: field,
    //     public amount_in: u128,
    //     public amount_out_min: u128,
    //     private to_pri: address,
    //     public to_pub: address,
    //  ) -> (PrivateToken) {
    //     assert(token_in != token_out);
    //     assert(amount_in > 0u128);

    //     let pt_out: PrivateToken = PrivateToken {
    //         owner: to_pri,
    //         token: token_out,
    //         amount: amount_out_min,
    //     };
    //     return pt_out then finalize(self.caller, token_in, token_out, amount_in, amount_out_min, to_pub);
    // }

    // finalize swap_exact_public_for_private(
    //     public caller: address,
    //     public token_in: field,
    //     public token_out: field,
    //     public amount_in: u128,
    //     public amount_out_min: u128,
    //     public to_pub: address,
    // ) {
    //     let token_a: field = token_in < token_out ? token_in : token_out;
    //     let token_b: field = token_in < token_out ? token_out : token_in;
    //     let pid: field = get_pair_id(token_a, token_b);
    //     let pair: Pair = Mapping::get(pairs, pid);

    //     // calculate output amount
    //     let reserve_in: u128 = token_a == token_in ? pair.reserve_a : pair.reserve_b;
    //     let reserve_out: u128 = token_a == token_out ? pair.reserve_a : pair.reserve_b;
    //     let amount_in_with_fee: u128 = amount_in * 997u128;
    //     let amount_out: u128 = amount_in_with_fee * reserve_out / (reserve_in * 1000u128 + amount_in_with_fee);
    //     assert(amount_out >= amount_out_min);
    //     assert(amount_out > 0u128);

    //     // transfer input token
    //     let bid_in: field = get_balance_id(token_in, caller);
    //     Mapping::set(balances, bid_in, Mapping::get(balances, bid_in) - amount_in);

    //     // update pair
    //     let reserve_in_new: u128 = reserve_in + amount_in;
    //     let reserve_out_new: u128 = reserve_out - amount_out;
    //     Mapping::set(pairs, pid, Pair {
    //         reserve_a: token_a == token_in ? reserve_in_new : reserve_out_new,
    //         reserve_b: token_b == token_in ? reserve_in_new : reserve_out_new,
    //     });

    //     // transfer output token(minus the private part)
    //     let bid_out: field = get_balance_id(token_out, to_pub);
    //     let amount_out_diff: u128 = amount_out - amount_out_min;
    //     Mapping::set(balances, bid_out, Mapping::get_or_use(balances, bid_out, 0u128) + amount_out_diff);
    // }

    // ========================= swap for exact =========================

    // Exchange a variable amount of public input tokens for a fixed amount of public output tokens.
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

    // Exchange a variable amount of private input tokens for a fixed amount of public output tokens.
    transition swap_private_for_exact_public(
        private pt_in: PrivateToken,
        public token_out: field,
        public amount_in_max: u128,
        public amount_out: u128,
        public to: address,
        public refund_to: address,
     ) -> (PrivateToken) {
        let token_in: field = pt_in.token;
        assert(token_in != token_out);
        assert(amount_out > 0u128);

        // All amount_in_max is transferred, any excess will be returned in public
        let change_in: PrivateToken = PrivateToken {
            owner: pt_in.owner,
            token: token_in,
            amount: pt_in.amount - amount_in_max,
        };

        return change_in then finalize(token_in, token_out, amount_in_max, amount_out, to, refund_to);
    }

    finalize swap_private_for_exact_public(
        public token_in: field,
        public token_out: field,
        public amount_in_max: u128,
        public amount_out: u128,
        public to: address,
        public refund_to: address,
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

        // refund input token
        let bid_refund: field = get_balance_id(token_in, refund_to);
        let refund_amount: u128 = amount_in_max - amount_in;
        Mapping::set(balances, bid_refund, Mapping::get_or_use(balances, bid_refund, 0u128) + refund_amount);

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

    // Exchange a variable amount of private input tokens for a fixed amount of private output tokens.
    transition swap_private_for_exact_private(
        private pt_in: PrivateToken,
        public token_out: field,
        public amount_in_max: u128,
        public amount_out: u128,
        private to_pri: address,
        public refund_to: address,
     ) -> (PrivateToken, PrivateToken) {
        let token_in: field = pt_in.token;
        assert(token_in != token_out);
        assert(amount_out > 0u128);
        let pt_out: PrivateToken = PrivateToken {
            owner: to_pri,
            token: token_out,
            amount: amount_out,
        };
        // All amount_in_max is transferred, any excess will be returned in public
        let change_in: PrivateToken = PrivateToken {
            owner: pt_in.owner,
            token: token_in,
            amount: pt_in.amount - amount_in_max,
        };
        return (pt_out, change_in) then finalize(token_in, token_out, amount_in_max, amount_out, refund_to);
    }

    finalize swap_private_for_exact_private(
        public token_in: field,
        public token_out: field,
        public amount_in_max: u128,
        public amount_out: u128,
        public refund_to: address,
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

        // refund input token
        let bid_refund: field = get_balance_id(token_in, refund_to);
        let refund_amount: u128 = amount_in_max - amount_in;
        Mapping::set(balances, bid_refund, Mapping::get_or_use(balances, bid_refund, 0u128) + refund_amount);

        // update pair
        let reserve_in_new: u128 = reserve_in + amount_in;
        let reserve_out_new: u128 = reserve_out - amount_out;
        Mapping::set(pairs, pid, Pair {
            reserve_a: token_a == token_in ? reserve_in_new : reserve_out_new,
            reserve_b: token_b == token_in ? reserve_in_new : reserve_out_new,
        });

        // output token has been transferred privately
    }

    // // Exchange a variable amount of public input tokens for a fixed amount of private output tokens.
    // transition swap_public_for_exact_private(
    //     public token_in: field,
    //     public token_out: field,
    //     public amount_in_max: u128,
    //     public amount_out: u128,
    //     private to_pri: address,
    //  ) -> (PrivateToken) {
    //     assert(token_in != token_out);
    //     assert(amount_out > 0u128);
    //     let pt_out: PrivateToken = PrivateToken {
    //         owner: to_pri,
    //         token: token_out,
    //         amount: amount_out,
    //     };
    //     return pt_out then finalize(self.caller, token_in, token_out, amount_in_max, amount_out);
    // }

    // finalize swap_public_for_exact_private(
    //     public caller: address,
    //     public token_in: field,
    //     public token_out: field,
    //     public amount_in_max: u128,
    //     public amount_out: u128,
    // ) {
    //     let token_a: field = token_in < token_out ? token_in : token_out;
    //     let token_b: field = token_in < token_out ? token_out : token_in;
    //     let pid: field = get_pair_id(token_a, token_b);
    //     let pair: Pair = Mapping::get(pairs, pid);

    //     // calculate input amount
    //     let reserve_in: u128 = token_a == token_in ? pair.reserve_a : pair.reserve_b;
    //     let reserve_out: u128 = token_a == token_out ? pair.reserve_a : pair.reserve_b;
    //     let amount_in: u128 = reserve_in * amount_out * 1000u128 / ((reserve_out - amount_out) * 997u128) + 1u128;
    //     assert(amount_in <= amount_in_max);
    //     assert(amount_in > 0u128);

    //     // transfer input token
    //     let bid_in: field = get_balance_id(token_in, caller);
    //     Mapping::set(balances, bid_in, Mapping::get(balances, bid_in) - amount_in);

    //     // update pair
    //     let reserve_in_new: u128 = reserve_in + amount_in;
    //     let reserve_out_new: u128 = reserve_out - amount_out;
    //     Mapping::set(pairs, pid, Pair {
    //         reserve_a: token_a == token_in ? reserve_in_new : reserve_out_new,
    //         reserve_b: token_b == token_in ? reserve_in_new : reserve_out_new,
    //     });

    //     // output token has been transferred privately
    // }


    // ========================= inline =========================

    // Build a key of the mapping `balances`
    inline get_balance_id(token_: field, user_: address) -> field {
        // copy to avoid compiling error
        let token: field = token_;
        let user: address = user_;
        return BHP256::hash_to_field(BalanceKeyData {token, user});
    }

    // Build a key of the mapping `allowance`
    inline get_allowance_id(token_id_: field, payer_: address, spender_: address) -> field {
        let token: field = token_id_;
        let payer: address = payer_;
        let spender: address = spender_;
        // copy to avoid compiling error
        return BHP256::hash_to_field(AllowanceKeyData {token, payer, spender});
    }

    // Build the id of a pair
    inline get_pair_id(token_a_: field, token_b_: field) -> field {
        // copy to avoid compiling error
        let token_a: field = token_a_;
        let token_b: field = token_b_;
        assert(token_a < token_b);
        return  BHP256::hash_to_field(PairKeyData {token_a, token_b});
    }

    // sqrt for u128
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

    // log2 for u128
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

    // min for u128
    inline min_u128(a: u128, b: u128) -> u128 {
        return a < b ? a : b;
    }
}
