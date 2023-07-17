import credits.aleo;
program swap.aleo;


record PrivateToken:
    owner as address.private;
    token as field.private;
    amount as u128.private;

struct TokenInfo:
    name as field;
    symbol as field;
    decimals as u8;
    total_supply as u128;
    admin as address;

struct GlobalState:
    next_token_id as field;
    admin as address;

struct BalanceKeyData:
    token as field;
    user as address;

struct AllowanceKeyData:
    token as field;
    payer as address;
    spender as address;

struct Pair:
    reserve_a as u128;
    reserve_b as u128;

struct PairKeyData:
    token_a as field;
    token_b as field;

struct WrapState:
    unwrap_count as u64;
    total_pending_amount as u128;
    unwrap_fee as u128;

struct UnwrapItem:
    to as address;
    amount as u128;
    fee as u128;
    is_private as boolean;
    is_pending as boolean;


mapping balances:
	key left as field.public;
	value right as u128.public;


mapping allowance:
	key left as field.public;
	value right as u128.public;


mapping tokens:
	key left as field.public;
	value right as TokenInfo.public;


mapping faucets:
	key left as field.public;
	value right as u128.public;


mapping global_state:
	key left as boolean.public;
	value right as GlobalState.public;


mapping pairs:
	key left as field.public;
	value right as Pair.public;


mapping unwraps:
	key left as u64.public;
	value right as UnwrapItem.public;


mapping wrap_state:
	key left as boolean.public;
	value right as WrapState.public;



function create_token:
    input r0 as TokenInfo.public;
    gt r0.name 0field into r1;
    assert.eq r1 true;

    finalize r0 self.caller;

finalize create_token:
    input r0 as TokenInfo.public;
    input r1 as address.public;
    get global_state[true] into r2;
    add r2.next_token_id 1field into r3;
    cast r3 r2.admin into r4 as GlobalState;
    set r4 into global_state[true];
    set r0 into tokens[r2.next_token_id];
    cast r2.next_token_id r1 into r5 as BalanceKeyData;
    hash.bhp256 r5 into r6 as field;    set r0.total_supply into balances[r6];


function transfer:
    input r0 as field.public;
    input r1 as address.public;
    input r2 as u128.public;

    finalize r0 self.caller r1 r2;

finalize transfer:
    input r0 as field.public;
    input r1 as address.public;
    input r2 as address.public;
    input r3 as u128.public;
    contains tokens[r0] into r4;
    assert.eq r4 true;
    cast r0 r1 into r5 as BalanceKeyData;
    hash.bhp256 r5 into r6 as field;    get balances[r6] into r7;
    sub r7 r3 into r8;
    set r8 into balances[r6];
    cast r0 r2 into r9 as BalanceKeyData;
    hash.bhp256 r9 into r10 as field;    get.or_use balances[r10] 0u128 into r11;
    add r11 r3 into r12;
    set r12 into balances[r10];




function approve:
    input r0 as field.public;
    input r1 as address.public;
    input r2 as u128.public;

    finalize r0 self.caller r1 r2;

finalize approve:
    input r0 as field.public;
    input r1 as address.public;
    input r2 as address.public;
    input r3 as u128.public;
    contains tokens[r0] into r4;
    assert.eq r4 true;
    cast r0 r1 r2 into r5 as AllowanceKeyData;
    hash.bhp256 r5 into r6 as field;    set r3 into allowance[r6];


function transfer_from:
    input r0 as field.public;
    input r1 as address.public;
    input r2 as address.public;
    input r3 as u128.public;

    finalize self.caller r0 r1 r2 r3;

finalize transfer_from:
    input r0 as address.public;
    input r1 as field.public;
    input r2 as address.public;
    input r3 as address.public;
    input r4 as u128.public;
    contains tokens[r1] into r5;
    assert.eq r5 true;
    cast r1 r2 r0 into r6 as AllowanceKeyData;
    hash.bhp256 r6 into r7 as field;    get allowance[r7] into r8;
    sub r8 r4 into r9;
    set r9 into allowance[r7];
    cast r1 r2 into r10 as BalanceKeyData;
    hash.bhp256 r10 into r11 as field;    get balances[r11] into r12;
    sub r12 r4 into r13;
    set r13 into balances[r11];
    cast r1 r3 into r14 as BalanceKeyData;
    hash.bhp256 r14 into r15 as field;    get.or_use balances[r15] 0u128 into r16;
    add r16 r4 into r17;
    set r17 into balances[r15];


function set_token_faucet:
    input r0 as field.public;
    input r1 as u128.public;
    is.neq r0 0field into r2;
    assert.eq r2 true;

    finalize self.caller r0 r1;

finalize set_token_faucet:
    input r0 as address.public;
    input r1 as field.public;
    input r2 as u128.public;
    get tokens[r1] into r3;
    assert.eq r0 r3.admin;
    set r2 into faucets[r1];


function change_token_admin:
    input r0 as field.public;
    input r1 as address.public;

    finalize self.caller r0 r1;

finalize change_token_admin:
    input r0 as address.public;
    input r1 as field.public;
    input r2 as address.public;
    get tokens[r1] into r3;
    assert.eq r0 r3.admin;
    cast r3.name r3.symbol r3.decimals r3.total_supply r2 into r4 as TokenInfo;
    set r4 into tokens[r1];


function token_faucet:
    input r0 as field.public;
    input r1 as address.public;

    finalize r0 r1;

finalize token_faucet:
    input r0 as field.public;
    input r1 as address.public;
    get faucets[r0] into r2;
    gt r2 0u128 into r3;
    assert.eq r3 true;
    get tokens[r0] into r4;
    add r4.total_supply r2 into r5;
    cast r4.name r4.symbol r4.decimals r5 r4.admin into r6 as TokenInfo;
    set r6 into tokens[r0];
    cast r0 r1 into r7 as BalanceKeyData;
    hash.bhp256 r7 into r8 as field;    get.or_use balances[r8] 0u128 into r9;
    add r9 r2 into r10;
    set r10 into balances[r8];


function wrap_private_credits:
    input r0 as credits.aleo/credits.record;
    input r1 as address.public;
    input r2 as field.public;
    input r3 as address.public;
    gt r2 0field into r4;
    lte r2 18446744073709551615field into r5;
    and r4 r5 into r6;
    assert.eq r6 true;
    cast r2 into r7 as u64;
    call credits.aleo/transfer_private_to_public r0 r3 r7 into r8;
    cast r2 into r9 as u128;
    output r8 as credits.aleo/credits.record;

    finalize r1 r9 r3;

finalize wrap_private_credits:
    input r0 as address.public;
    input r1 as u128.public;
    input r2 as address.public;
    get tokens[0field] into r3;
    assert.eq r2 r3.admin;
    add r3.total_supply r1 into r4;
    cast r3.name r3.symbol r3.decimals r4 r3.admin into r5 as TokenInfo;
    set r5 into tokens[0field];
    cast 0field r0 into r6 as BalanceKeyData;
    hash.bhp256 r6 into r7 as field;    get.or_use balances[r7] 0u128 into r8;
    add r8 r1 into r9;
    set r9 into balances[r7];


function wrap_public_credits:
    input r0 as address.public;
    input r1 as field.public;
    input r2 as address.public;
    gt r1 0field into r3;
    lte r1 18446744073709551615field into r4;
    and r3 r4 into r5;
    assert.eq r5 true;
    cast r1 into r6 as u64;
    call credits.aleo/transfer_public r2 r6;    cast r1 into r7 as u128;

    finalize r0 r7 r2;

finalize wrap_public_credits:
    input r0 as address.public;
    input r1 as u128.public;
    input r2 as address.public;
    get tokens[0field] into r3;
    assert.eq r2 r3.admin;
    add r3.total_supply r1 into r4;
    cast r3.name r3.symbol r3.decimals r4 r3.admin into r5 as TokenInfo;
    set r5 into tokens[0field];
    cast 0field r0 into r6 as BalanceKeyData;
    hash.bhp256 r6 into r7 as field;    get.or_use balances[r7] 0u128 into r8;
    add r8 r1 into r9;
    set r9 into balances[r7];


function unwrap:
    input r0 as address.public;
    input r1 as field.public;
    input r2 as boolean.public;
    gt r1 0field into r3;
    lte r1 18446744073709551615field into r4;
    and r3 r4 into r5;
    assert.eq r5 true;
    cast r1 into r6 as u128;

    finalize self.caller r0 r6 r2;

finalize unwrap:
    input r0 as address.public;
    input r1 as address.public;
    input r2 as u128.public;
    input r3 as boolean.public;
    get wrap_state[true] into r4;
    gt r2 r4.unwrap_fee into r5;
    assert.eq r5 true;
    get tokens[0field] into r6;
    sub r6.total_supply r2 into r7;
    cast r6.name r6.symbol r6.decimals r7 r6.admin into r8 as TokenInfo;
    set r8 into tokens[0field];
    cast 0field r0 into r9 as BalanceKeyData;
    hash.bhp256 r9 into r10 as field;    get.or_use balances[r10] 0u128 into r11;
    sub r11 r2 into r12;
    set r12 into balances[r10];
    cast r1 r2 r4.unwrap_fee r3 true into r13 as UnwrapItem;
    set r13 into unwraps[r4.unwrap_count];
    add r4.unwrap_count 1u64 into r14;
    add r4.total_pending_amount r2 into r15;
    cast r14 r15 r4.unwrap_fee into r16 as WrapState;
    set r16 into wrap_state[true];


function handle_unwrap_to_private:
    input r0 as u64.public;
    input r1 as address.public;
    input r2 as field.public;
    cast r2 into r3 as u64;
    call credits.aleo/transfer_public_to_private r1 r3 into r4;
    cast r2 into r5 as u128;
    output r4 as credits.aleo/credits.record;

    finalize r0 r1 r5;

finalize handle_unwrap_to_private:
    input r0 as u64.public;
    input r1 as address.public;
    input r2 as u128.public;
    get unwraps[r0] into r3;
    assert.eq r3.to r1;
    sub r3.amount r3.fee into r4;
    gte r2 r4 into r5;
    assert.eq r5 true;
    assert.eq r3.is_private true;
    assert.eq r3.is_pending true;
    cast r3.to r3.amount r3.fee r3.is_private false into r6 as UnwrapItem;
    set r6 into unwraps[r0];
    get wrap_state[true] into r7;
    sub r7.total_pending_amount r2 into r8;
    cast r7.unwrap_count r8 r7.unwrap_fee into r9 as WrapState;
    set r9 into wrap_state[true];


function handle_unwrap_to_public:
    input r0 as u64.public;
    input r1 as address.public;
    input r2 as field.public;
    cast r2 into r3 as u64;
    call credits.aleo/transfer_public r1 r3;    cast r2 into r4 as u128;

    finalize r0 r1 r4;

finalize handle_unwrap_to_public:
    input r0 as u64.public;
    input r1 as address.public;
    input r2 as u128.public;
    get unwraps[r0] into r3;
    assert.eq r3.to r1;
    sub r3.amount r3.fee into r4;
    gte r2 r4 into r5;
    assert.eq r5 true;
    assert.eq r3.is_private false;
    assert.eq r3.is_pending true;
    cast r3.to r3.amount r3.fee r3.is_private false into r6 as UnwrapItem;
    set r6 into unwraps[r0];
    get wrap_state[true] into r7;
    sub r7.total_pending_amount r2 into r8;
    cast r7.unwrap_count r8 r7.unwrap_fee into r9 as WrapState;
    set r9 into wrap_state[true];


function set_unwrap_fee:
    input r0 as u128.public;
    lt r0 10000000u128 into r1;
    assert.eq r1 true;

    finalize self.caller r0;

finalize set_unwrap_fee:
    input r0 as address.public;
    input r1 as u128.public;
    get tokens[0field] into r2;
    assert.eq r0 r2.admin;
    get wrap_state[true] into r3;
    cast r3.unwrap_count r3.total_pending_amount r1 into r4 as WrapState;
    set r4 into wrap_state[true];


function init:

    finalize self.caller;

finalize init:
    input r0 as address.public;
    cast 0field aleo1tdszx3hcgnyp2jw3y3fzvw27vremxcs24u4pys6vptg9y2jfsvps8e8ffz into r1 as GlobalState;
    get.or_use global_state[true] r1 into r2;
    assert.eq r2.next_token_id 0field;
    assert.eq r0 r2.admin;
    cast 1field r2.admin into r3 as GlobalState;
    set r3 into global_state[true];
    cast 105716693521782238488585583field 374757672271field 6u8 0u128 aleo1tdszx3hcgnyp2jw3y3fzvw27vremxcs24u4pys6vptg9y2jfsvps8e8ffz into r4 as TokenInfo;
    set r4 into tokens[0field];
    cast 0u64 0u128 0u128 into r5 as WrapState;
    set r5 into wrap_state[true];


function change_admin:
    input r0 as address.public;

    finalize self.caller r0;

finalize change_admin:
    input r0 as address.public;
    input r1 as address.public;
    get global_state[true] into r2;
    assert.eq r0 r2.admin;
    cast r2.next_token_id r1 into r3 as GlobalState;
    set r3 into global_state[true];


function transfer_to_private:
    input r0 as field.public;
    input r1 as address.private;
    input r2 as u128.public;
    cast r1 r0 r2 into r3 as PrivateToken.record;
    hash.bhp256 r3 into r4 as field;    output r3 as PrivateToken.record;

    finalize r0 self.caller r2;

finalize transfer_to_private:
    input r0 as field.public;
    input r1 as address.public;
    input r2 as u128.public;
    contains tokens[r0] into r3;
    assert.eq r3 true;
    cast r0 r1 into r4 as BalanceKeyData;
    hash.bhp256 r4 into r5 as field;    get balances[r5] into r6;
    sub r6 r2 into r7;
    set r7 into balances[r5];


function transfer_to_public:
    input r0 as PrivateToken.record;
    input r1 as address.public;
    input r2 as u128.public;
    sub r0.amount r2 into r3;
    cast r0.owner r0.token r3 into r4 as PrivateToken.record;
    output r4 as PrivateToken.record;

    finalize r0.token r1 r2;

finalize transfer_to_public:
    input r0 as field.public;
    input r1 as address.public;
    input r2 as u128.public;
    contains tokens[r0] into r3;
    assert.eq r3 true;
    cast r0 r1 into r4 as BalanceKeyData;
    hash.bhp256 r4 into r5 as field;    get.or_use balances[r5] 0u128 into r6;
    add r6 r2 into r7;
    set r7 into balances[r5];


function transfer_privately:
    input r0 as PrivateToken.record;
    input r1 as address.private;
    input r2 as u128.private;
    cast r1 r0.token r2 into r3 as PrivateToken.record;
    sub r0.amount r2 into r4;
    cast r0.owner r0.token r4 into r5 as PrivateToken.record;
    output r3 as PrivateToken.record;
    output r5 as PrivateToken.record;


function join:
    input r0 as PrivateToken.record;
    input r1 as PrivateToken.record;
    assert.eq r0.token r1.token;
    add r0.amount r1.amount into r2;
    cast r0.owner r0.token r2 into r3 as PrivateToken.record;
    output r3 as PrivateToken.record;










function create_pair:
    input r0 as field.public;
    input r1 as field.public;
    input r2 as u128.public;
    input r3 as u128.public;
    input r4 as address.public;
    lt r0 r1 into r5;
    assert.eq r5 true;
    gt r2 0u128 into r6;
    assert.eq r6 true;
    gt r3 0u128 into r7;
    assert.eq r7 true;

    finalize self.caller r0 r1 r2 r3 r4;

finalize create_pair:
    input r0 as address.public;
    input r1 as field.public;
    input r2 as field.public;
    input r3 as u128.public;
    input r4 as u128.public;
    input r5 as address.public;
    lt r1 r2 into r6;
    assert.eq r6 true;
    cast r1 r2 into r7 as PairKeyData;
    hash.bhp256 r7 into r8 as field;    mul r3 r4 into r9;
    is.eq r9 0u128 into r10;
    shr r9 64u32 into r11;
    gt r11 0u128 into r12;
    shr r9 64u32 into r13;
    add 0u32 64u32 into r14;
    ternary r12 r13 r9 into r15;
    ternary r12 r14 0u32 into r16;
    shr r15 32u32 into r17;
    gt r17 0u128 into r18;
    shr r15 32u32 into r19;
    add r16 32u32 into r20;
    ternary r18 r19 r15 into r21;
    ternary r18 r20 r16 into r22;
    shr r21 16u32 into r23;
    gt r23 0u128 into r24;
    shr r21 16u32 into r25;
    add r22 16u32 into r26;
    ternary r24 r25 r21 into r27;
    ternary r24 r26 r22 into r28;
    shr r27 8u32 into r29;
    gt r29 0u128 into r30;
    shr r27 8u32 into r31;
    add r28 8u32 into r32;
    ternary r30 r31 r27 into r33;
    ternary r30 r32 r28 into r34;
    shr r33 4u32 into r35;
    gt r35 0u128 into r36;
    shr r33 4u32 into r37;
    add r34 4u32 into r38;
    ternary r36 r37 r33 into r39;
    ternary r36 r38 r34 into r40;
    shr r39 2u32 into r41;
    gt r41 0u128 into r42;
    shr r39 2u32 into r43;
    add r40 2u32 into r44;
    ternary r42 r43 r39 into r45;
    ternary r42 r44 r40 into r46;
    shr r45 1u32 into r47;
    gt r47 0u128 into r48;
    add r46 1u32 into r49;
    ternary r48 r49 r46 into r50;
    div r50 2u32 into r51;
    shl 1u128 r51 into r52;
    div r9 r52 into r53;
    add r52 r53 into r54;
    shr r54 1u32 into r55;
    div r9 r55 into r56;
    add r55 r56 into r57;
    shr r57 1u32 into r58;
    div r9 r58 into r59;
    add r58 r59 into r60;
    shr r60 1u32 into r61;
    div r9 r61 into r62;
    add r61 r62 into r63;
    shr r63 1u32 into r64;
    div r9 r64 into r65;
    add r64 r65 into r66;
    shr r66 1u32 into r67;
    div r9 r67 into r68;
    add r67 r68 into r69;
    shr r69 1u32 into r70;
    div r9 r70 into r71;
    add r70 r71 into r72;
    shr r72 1u32 into r73;
    div r9 r73 into r74;
    lt r73 r74 into r75;
    ternary r75 r73 r74 into r76;
    ternary r10 0u128 r76 into r77;
    gt r77 0u128 into r78;
    assert.eq r78 true;
    cast 5183377571718029925300968712562field 4281168field 6u8 0u128 aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc into r79 as TokenInfo;
    get.or_use tokens[r8] r79 into r80;
    assert.eq r80.total_supply 0u128;
    cast 0u128 0u128 into r81 as Pair;
    get.or_use pairs[r8] r81 into r82;
    cast r1 r0 into r83 as BalanceKeyData;
    hash.bhp256 r83 into r84 as field;    get balances[r84] into r85;
    sub r85 r3 into r86;
    set r86 into balances[r84];
    cast r2 r0 into r87 as BalanceKeyData;
    hash.bhp256 r87 into r88 as field;    get balances[r88] into r89;
    sub r89 r4 into r90;
    set r90 into balances[r88];
    cast r8 r5 into r91 as BalanceKeyData;
    hash.bhp256 r91 into r92 as field;    get.or_use balances[r92] 0u128 into r93;
    add r93 r77 into r94;
    set r94 into balances[r92];
    add r80.total_supply r77 into r95;
    cast r80.name r80.symbol r80.decimals r95 r80.admin into r96 as TokenInfo;
    set r96 into tokens[r8];
    add r82.reserve_a r3 into r97;
    add r82.reserve_b r4 into r98;
    cast r97 r98 into r99 as Pair;
    set r99 into pairs[r8];


function add_liquidity:
    input r0 as field.public;
    input r1 as field.public;
    input r2 as u128.public;
    input r3 as u128.public;
    input r4 as u128.public;
    input r5 as u128.public;
    input r6 as address.public;
    lt r0 r1 into r7;
    assert.eq r7 true;
    gt r2 0u128 into r8;
    gte r2 r4 into r9;
    and r8 r9 into r10;
    assert.eq r10 true;
    gt r3 0u128 into r11;
    gte r3 r5 into r12;
    and r11 r12 into r13;
    assert.eq r13 true;

    finalize self.caller r0 r1 r2 r3 r4 r5 r6;

finalize add_liquidity:
    input r0 as address.public;
    input r1 as field.public;
    input r2 as field.public;
    input r3 as u128.public;
    input r4 as u128.public;
    input r5 as u128.public;
    input r6 as u128.public;
    input r7 as address.public;
    lt r1 r2 into r8;
    assert.eq r8 true;
    cast r1 r2 into r9 as PairKeyData;
    hash.bhp256 r9 into r10 as field;    get pairs[r10] into r11;
    get tokens[r10] into r12;
    mul r3 r12.total_supply into r13;
    div r13 r11.reserve_a into r14;
    mul r4 r12.total_supply into r15;
    div r15 r11.reserve_b into r16;
    lte r14 r16 into r17;
    ternary r17 r14 r16 into r18;
    lte r14 r18 into r19;
    mul r18 r11.reserve_a into r20;
    add r20 r12.total_supply into r21;
    sub r21 1u128 into r22;
    div r22 r12.total_supply into r23;
    ternary r19 r3 r23 into r24;
    lte r16 r18 into r25;
    mul r18 r11.reserve_b into r26;
    add r26 r12.total_supply into r27;
    sub r27 1u128 into r28;
    div r28 r12.total_supply into r29;
    ternary r25 r4 r29 into r30;
    gt r18 0u128 into r31;
    assert.eq r31 true;
    gte r24 r5 into r32;
    assert.eq r32 true;
    gte r30 r6 into r33;
    assert.eq r33 true;
    cast r1 r0 into r34 as BalanceKeyData;
    hash.bhp256 r34 into r35 as field;    get balances[r35] into r36;
    sub r36 r24 into r37;
    set r37 into balances[r35];
    cast r2 r0 into r38 as BalanceKeyData;
    hash.bhp256 r38 into r39 as field;    get balances[r39] into r40;
    sub r40 r30 into r41;
    set r41 into balances[r39];
    cast r10 r7 into r42 as BalanceKeyData;
    hash.bhp256 r42 into r43 as field;    get.or_use balances[r43] 0u128 into r44;
    add r44 r18 into r45;
    set r45 into balances[r43];
    add r12.total_supply r18 into r46;
    cast r12.name r12.symbol r12.decimals r46 r12.admin into r47 as TokenInfo;
    set r47 into tokens[r10];
    add r11.reserve_a r24 into r48;
    add r11.reserve_b r30 into r49;
    cast r48 r49 into r50 as Pair;
    set r50 into pairs[r10];


function remove_liquidity:
    input r0 as field.public;
    input r1 as field.public;
    input r2 as u128.public;
    input r3 as u128.public;
    input r4 as u128.public;
    input r5 as address.public;
    lt r0 r1 into r6;
    assert.eq r6 true;
    gt r2 0u128 into r7;
    assert.eq r7 true;

    finalize self.caller r0 r1 r2 r3 r4 r5;

finalize remove_liquidity:
    input r0 as address.public;
    input r1 as field.public;
    input r2 as field.public;
    input r3 as u128.public;
    input r4 as u128.public;
    input r5 as u128.public;
    input r6 as address.public;
    lt r1 r2 into r7;
    assert.eq r7 true;
    cast r1 r2 into r8 as PairKeyData;
    hash.bhp256 r8 into r9 as field;    get tokens[r9] into r10;
    get pairs[r9] into r11;
    mul r3 r11.reserve_a into r12;
    div r12 r10.total_supply into r13;
    mul r3 r11.reserve_b into r14;
    div r14 r10.total_supply into r15;
    gte r13 r4 into r16;
    gte r15 r5 into r17;
    and r16 r17 into r18;
    assert.eq r18 true;
    gt r13 0u128 into r19;
    gt r15 0u128 into r20;
    or r19 r20 into r21;
    assert.eq r21 true;
    cast r9 r0 into r22 as BalanceKeyData;
    hash.bhp256 r22 into r23 as field;    get balances[r23] into r24;
    sub r24 r3 into r25;
    set r25 into balances[r23];
    sub r10.total_supply r3 into r26;
    cast r10.name r10.symbol r10.decimals r26 r10.admin into r27 as TokenInfo;
    set r27 into tokens[r9];
    sub r11.reserve_a r13 into r28;
    sub r11.reserve_b r15 into r29;
    cast r28 r29 into r30 as Pair;
    set r30 into pairs[r9];
    cast r1 r6 into r31 as BalanceKeyData;
    hash.bhp256 r31 into r32 as field;    cast r2 r6 into r33 as BalanceKeyData;
    hash.bhp256 r33 into r34 as field;    get.or_use balances[r32] 0u128 into r35;
    add r35 r13 into r36;
    set r36 into balances[r32];
    get.or_use balances[r34] 0u128 into r37;
    add r37 r15 into r38;
    set r38 into balances[r34];


function swap_exact_tokens_for_tokens:
    input r0 as field.public;
    input r1 as field.public;
    input r2 as u128.public;
    input r3 as u128.public;
    input r4 as address.public;
    is.neq r0 r1 into r5;
    assert.eq r5 true;
    gt r2 0u128 into r6;
    assert.eq r6 true;

    finalize self.caller r0 r1 r2 r3 r4;

finalize swap_exact_tokens_for_tokens:
    input r0 as address.public;
    input r1 as field.public;
    input r2 as field.public;
    input r3 as u128.public;
    input r4 as u128.public;
    input r5 as address.public;
    lt r1 r2 into r6;
    ternary r6 r1 r2 into r7;
    lt r1 r2 into r8;
    ternary r8 r2 r1 into r9;
    lt r7 r9 into r10;
    assert.eq r10 true;
    cast r7 r9 into r11 as PairKeyData;
    hash.bhp256 r11 into r12 as field;    get pairs[r12] into r13;
    is.eq r7 r1 into r14;
    ternary r14 r13.reserve_a r13.reserve_b into r15;
    is.eq r7 r2 into r16;
    ternary r16 r13.reserve_a r13.reserve_b into r17;
    mul r3 997u128 into r18;
    mul r18 r17 into r19;
    mul r15 1000u128 into r20;
    add r20 r18 into r21;
    div r19 r21 into r22;
    gte r22 r4 into r23;
    assert.eq r23 true;
    gt r22 0u128 into r24;
    assert.eq r24 true;
    cast r1 r0 into r25 as BalanceKeyData;
    hash.bhp256 r25 into r26 as field;    get balances[r26] into r27;
    sub r27 r3 into r28;
    set r28 into balances[r26];
    add r15 r3 into r29;
    sub r17 r22 into r30;
    is.eq r7 r1 into r31;
    ternary r31 r29 r30 into r32;
    is.eq r9 r1 into r33;
    ternary r33 r29 r30 into r34;
    cast r32 r34 into r35 as Pair;
    set r35 into pairs[r12];
    cast r2 r5 into r36 as BalanceKeyData;
    hash.bhp256 r36 into r37 as field;    get.or_use balances[r37] 0u128 into r38;
    add r38 r22 into r39;
    set r39 into balances[r37];


function swap_tokens_for_exact_tokens:
    input r0 as field.public;
    input r1 as field.public;
    input r2 as u128.public;
    input r3 as u128.public;
    input r4 as address.public;
    is.neq r0 r1 into r5;
    assert.eq r5 true;
    gt r3 0u128 into r6;
    assert.eq r6 true;

    finalize self.caller r0 r1 r2 r3 r4;

finalize swap_tokens_for_exact_tokens:
    input r0 as address.public;
    input r1 as field.public;
    input r2 as field.public;
    input r3 as u128.public;
    input r4 as u128.public;
    input r5 as address.public;
    lt r1 r2 into r6;
    ternary r6 r1 r2 into r7;
    lt r1 r2 into r8;
    ternary r8 r2 r1 into r9;
    lt r7 r9 into r10;
    assert.eq r10 true;
    cast r7 r9 into r11 as PairKeyData;
    hash.bhp256 r11 into r12 as field;    get pairs[r12] into r13;
    is.eq r7 r1 into r14;
    ternary r14 r13.reserve_a r13.reserve_b into r15;
    is.eq r7 r2 into r16;
    ternary r16 r13.reserve_a r13.reserve_b into r17;
    mul r15 r4 into r18;
    mul r18 1000u128 into r19;
    sub r17 r4 into r20;
    mul r20 997u128 into r21;
    div r19 r21 into r22;
    add r22 1u128 into r23;
    lte r23 r3 into r24;
    assert.eq r24 true;
    gt r23 0u128 into r25;
    assert.eq r25 true;
    cast r1 r0 into r26 as BalanceKeyData;
    hash.bhp256 r26 into r27 as field;    get balances[r27] into r28;
    sub r28 r23 into r29;
    set r29 into balances[r27];
    add r15 r23 into r30;
    sub r17 r4 into r31;
    is.eq r7 r1 into r32;
    ternary r32 r30 r31 into r33;
    is.eq r9 r1 into r34;
    ternary r34 r30 r31 into r35;
    cast r33 r35 into r36 as Pair;
    set r36 into pairs[r12];
    cast r2 r5 into r37 as BalanceKeyData;
    hash.bhp256 r37 into r38 as field;    get.or_use balances[r38] 0u128 into r39;
    add r39 r4 into r40;
    set r40 into balances[r38];
