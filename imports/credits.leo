// The 'credits' program
program credits.aleo {
    mapping account: address => u64;

    record credits {
        private owner: address;
        private microcredits: u64;
    }

    // The `transfer_public` function sends the specified amount
    // from the sender's `account` to the receiver's `account`.
    transition transfer_public(public to: address, public amount: u64) {
        return;
    }

    // The `transfer_private` function sends the specified amount
    // from the sender's record to the receiver in a record.
    transition transfer_private(private input: credits, private to: address, private amount: u64) -> (credits, credits) {
        let output: credits = credits {
            owner: to,
            microcredits: amount,
        };
        let change: credits = credits {
            owner: input.owner,
            microcredits: input.microcredits - amount,
        };
        return (output, change);
    }

    // The `transfer_private_to_public` function turns a specified amount
    // from a record into public credits for the specified receiver.
    //
    // This function preserves privacy for the sender's record, however
    // it publicly reveals the receiver and the amount.
    transition transfer_private_to_public(private input: credits, public to: address, public amount: u64) -> (credits) {
        return input;
    }

    // The `transfer_public_to_private` function turns a specified amount
    // from the mapping `account` into a record for the specified receiver.
    //
    // This function preserves privacy for the receiver's record, however
    // it publicly reveals the sender and the specified amount.
    transition transfer_public_to_private(public to: address, public amount: u64) -> (credits) {
        return credits {
            owner: to, microcredits: amount
        };
    }

    // The `join` function combines two records into one.
    // transition join(private input1: credits, private input2: credits) -> (credits) {
    //     return credits {
    //         owner: input1.owner,
    //         microcredits: input1.microcredits + input2.microcredits,
    //     };
    // }

    // The `split` function splits a record into two records.
    transition split(private input: credits, private amount: u64) -> (credits, credits) {
        let output1: credits = credits {
            owner: input.owner,
            microcredits: amount,
        };
        let output2: credits = credits {
            owner: input.owner,
            microcredits: input.microcredits - amount,
        };
        return (output1, output2);
    }
}
