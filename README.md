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

---

### CHALLENGE 5 - The Rewarder

In this challenge, key is to use the flash loan exactly at the timestamp when rewards are distributed. At this time, I depositing all the DMV tokens borrowed from flash loan pool into the Rewards pool, I dilute every other player in Reward Pool and capture all the rewards that would be paid out in the next cycle.

Here are following steps

- Create a [RewardAttacker.sol](./contracts/the-rewarder/RewardAttacker.sol) contract and define a `receiveFlashLoan` function. This function will be called right after flash loan deposit happens into the attacker contract
- Wait for the Next Snapshot time - at the exact timestamp, deposit DVT tokens into the [TheRewardPool.sol](./contracts/the-rewarder/TheRewarderPool.sol).
- Within deposits, accToken is minted and snapshot is captured
- Once done, withdraw all tokens from Reward Pool and pay back the flashloan
- Now on the next reward date, distribute Rewards transfers all rewards to me

---

### CHALLENGE 6 - Selfie

https://www.damnvulnerabledefi.xyz/challenges/6.html
Not sure why this contract is named Selfie.. anyways.

Again key concept here is to exploit flash loans -> create a governance action that will be executed after some time delay.
In the execution, do a low level function call to drainFunds() to attacker. Lets break it down

1. First I create a [SelfieAttacker.sol](./contracts/selfie/SeflieAttacker.sol) file that has the callback function called `receiveTokens` which will be called from within flashloans
2. In this function, first we call `snapshot()` to create a snapshot where balances will be captured by `ERC20Snapshot`
3. Next we create an action -> each action has 3 items
   - receiver (address on which the callback will be called)
   - data (this is bytes data that includes function call and arguments to that function)
   - weiAmount - this is the amount of ETH to be transferred (we can ignore this as there is no ETH transfer in our challenge)
4. In the receiver, we first give the pool contract address - this is the [flashloan pool contract](./contracts/selfie/SelfiePool.sol)
5. In the data, we encode the function `drainAllFunds` that is defined in the pool - note that this function can only be called by the Governance contract. This function takes a single address - here I assigned `tx.origin` -> a global variable that stores the original caller address, which in our case is the attacker
6. Now define another function `exploit` inside SelfieAttacker that calls `flashloan` function in pool
7. Since we took a flashloan of >50%, the `hasEnoughVotes` inside `queueAction` will return true. This will successfully queue txn
8. Now last step, we shift time by 2 days and call the `executeAction` function in governance contract

If all is done well, we end up with all the funds from this governance hack

### CHALLENGE 7 - Compromised

https://www.damnvulnerabledefi.xyz/challenges/7.html

1. Key in this challenge is to realize that the output of API is a hex code. Convert hex code -> ASCII -> Base64. And to guess that it is a private key -> So if we create a wallet using this key and check public address, we realize it matches with 2 price oracles

2. Notice that the [TrustfulOracle contract](./contracts/compromised/TrustfulOracle.sol) takes price from 3 oracles and calculates the median value using `_computeMedianPrice` function. Notice that there is a `postPrice` function in the same contract that can only be called by trusted oracles -> this function allows oracle to update a price -> and this function is manually callable

3. We first create a signed txn that calls the `postPrice` function from a wallet address that we control using hacked private key. We then set a price of 0 from both oracles to force price to go to 0

4. Once done, we go to the [Exchange contract](./contracts/compromised/Exchange.sol) to buy a NFT using the `buyOne` function. Next we again post a price (this time, we post the actual trading price of 990 ETH) to the oracle. And then call the `sellOne` function to sell at the high price. Buy low, sell high until the exchange is drained of all funds
