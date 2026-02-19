// To compute the last **n digits** of a number raised to a power using binary exponentiation while avoiding large computations, you can employ modular arithmetic. This method lets you take the modulus of intermediate results, thereby keeping the numbers manageable and only focusing on the last **n digits**.

// ## Steps for Binary Exponentiation to Find Last n Digits

// 1. **Define the Problem**: 
//    To compute \(a^b \mod 10^n\), where **a** is your base, **b** is the exponent, and **10^n** helps extract the last **n digits**.

// 2. **Initialize the Variables**:
//    Set up a result variable initialized to **1** and a variable for your modulus as \(M = 10^n\).

// 3. **Binary Exponentiation Algorithm**:
//    - While the exponent **b** is greater than **0**:
//      - If **b** is odd, multiply the result by **a** and take modulo **M**: 
//        \[
//        \text{result} = (\text{result} \times a) \mod M
//        \]
//      - Square **a** and take modulo **M**: 
//        \[
//        a = (a \times a) \mod M
//        \]
//      - Halve **b**: 
//        \[
//        b = b // 2
//        \]

// 4. **Return the Result**:
//    After the loop finishes, the result will hold the last **n digits** of \(a^b\).

// ## Example

// To compute \(3^{13}\) and find the last **3 digits**:

// 1. Set \(M = 10^3 = 1000\).
// 2. Initialize \( \text{result} = 1\) and execute binary exponentiation:

//    - For \(b = 13\): result = 1, \(a = 3\)
//      - \(b\) is odd: result = \(3 \mod 1000 = 3\)
//      - \(a\) = \(3 \times 3 \mod 1000 = 9\), \(b = 6\)

//    - For \(b = 6\): result = 3, \(a = 9\)
//      - \(a\) = \(9 \times 9 \mod 1000 = 81\), \(b = 3\)

//    - For \(b = 3\): result = 3, \(a = 81\)
//      - \(b\) is odd: result = \(3 \times 81 \mod 1000 = 243\)
//      - \(a\) = \(81 \times 81 \mod 1000 = 561\), \(b = 1\)

//    - For \(b = 1\): result = 243, \(a = 561\)
//      - \(b\) is odd: result = \(243 \times 561 \mod 1000 = 543\)
//      - \(a\) = \(561 \times 561 \mod 1000 = 721\), \(b = 0\)

// The last three digits of \(3^{13}\) are **543**.

// ---

// This method avoids overflow and is efficient for finding the last **n digits** of large exponentiations. Feel free to ask for further clarifications or examples if needed!

const lastndigitsofbinexp = (a: bigint, b: bigint, last?: bigint): bigint => {
    const mod = last ? 10n ** last : 10n ** 9n;
    let result = 1n;
    a = a % mod;
    while (b > 0n) {
        if (b & 1n) {
            result = (result * a) % mod;
        }
        a = (a * a) % mod;
        b >>= 1n;
    }
    return result;
}

console.log(lastndigitsofbinexp(30739879823949837983498n, 94390389794873984938749n, 4n));