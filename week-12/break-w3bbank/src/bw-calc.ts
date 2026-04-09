function calcFee(amount: bigint, bonusBps: bigint): bigint {
    const feeBps = 3141n;
    return (amount * (feeBps + bonusBps)) / 10000n;
}

function calcLowerThanFeePayout(amount: bigint): bigint {
    while (calcFee(amount, 0n) - amount == 1n) {
        amount *= 2n;
    }
    return amount;
}

function main() {
    console.log("Lower than fee payout:", calcLowerThanFeePayout(1n).toString());
}

main();
