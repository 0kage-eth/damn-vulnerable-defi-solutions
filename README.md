![](cover.png)

**A set of challenges to learn offensive security of smart contracts in Ethereum.**

Featuring flash loans, price oracles, governance, NFTs, lending pools, smart contract wallets, timelocks, and more!

## Play

Visit [damnvulnerabledefi.xyz](https://damnvulnerabledefi.xyz)

## Disclaimer

All Solidity code, practices and patterns in this repository are DAMN VULNERABLE and for educational purposes only.

DO NOT USE IN PRODUCTION.

## Solutions

---

### CHALLENGE 1 - Unstoppable Flash Loan

In this exercise, we need to stop FlashLoan from executing -> on line 40 of [UnstoppableLender.sol](./contracts/unstoppable/UnstoppableLender.sol), we notice an assertion that expects pool balance to equal to token balance of Dammn token -> this implicitly assumes that all users use the `depositTokens` function to deposit dammn tokens -> we can use the `transfer` of IERC20 implementation to send dammn tokens to pool address

Since poolBalance does not increase when we use the `transfer` function, assertion inside the `flashLoan` function reverts with an error -> this achieves our objective

---

### CHALLENGE 2 - Naive Receiver

Key to this challenge is to realize that flashLoans function in [NaiveReceiverLenderPool.sol](./contracts/naive-receiver/NaiveReceiverLenderPool.sol) is not checking if contract caller is indeed the borrower. Since fees is high (1 Eth), anyone can drain the receiver contract by repeatedly calling flashLoans and draining out 1 Ether everytime. Run a while loop until all ether is drained

---

### CHALLENGE 3 - Naive Receiver

In this challenge, we have to deplete the funds from a TrusterLenderPool. 2 things are clear from the `TrusterLenderPool` contract in [TrusterLenderPool.sol](./contracts/truster/TrusterLenderPool.sol). - `flashLoan()` function does not check if sender is borrower. Meaning anyone can send with a borrower address - `borrow` amount can be 0. In this case, we can send a 0 amount & access the `target` call function

Key here is to access the call function on `target` address where `msg.sender` becomes the TrusterLenderPool contract.
I send the target address as the token address and call the function `approve` to get my attacker address to allow to spend all tokens in trustpool contract. After this, its straight forward - I transfer all tokens from pool to attacker

---

### CHALLENGE 4 - Side Entrance

In this challenge, we have to drain all funds from a Lending Pool contract [SideEntranceLenderPool.sol](./contracts/side-entrance/SideEntranceLenderPool.sol). Key here is to note that the `flashLoan` function is only checking if the overall balance after loan > balance before loan. We exploit this weakness by doing following

- Create a new contract called `SideEntranceLenderPoolExploit`
- Create a function `pawn` which first borrows a flash loan from pool contract. On borrowing funds, the `fallback()` function gets triggered
- Inside fallback, I deposit the funds back into the lending pool contract. This ensures balance before and after are same
- But now `balances` mapping shows that attacking contract is the owner of the funcs
- Now I happily go and withdraw funds to this attacking contract
- And from there, I transfer funds to whereever I want
