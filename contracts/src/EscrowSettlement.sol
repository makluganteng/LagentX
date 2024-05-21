// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title EscrowSettlement
 * @dev This contract allows users to create intent transactions that can be settled by a solver.
 */
contract EscrowSettlement {

    address public solver;

    enum SettlementStatus {
        PENDING,
        DONE
    }

    struct IntentTxn {
        address user;
        address tokenAddress1;
        uint amount1;
        address tokenAddress2;
        uint amount2;
        uint chainId; // The destination of the chain the intent transaction is intended for
        SettlementStatus status;
    }

    mapping(address => mapping(uint => IntentTxn)) public userIntents;
    mapping(address => uint) public userIntentCount;

    event IntentCreated(
        address indexed user, 
        uint indexed intentId, 
        address tokenAddress1, 
        uint amount1, 
        address tokenAddress2, 
        uint amount2, 
        uint chainId
    );
    
    event SingleWithdrawn(
        address indexed solver, 
        address indexed user, 
        uint256 indexed intentId
    );
    
    event BatchWithdrawn(
        address indexed solver, 
        address indexed user, 
        uint count
    );

    modifier onlySolver() {
        require(msg.sender == solver, "You are not the solver");
        _;
    }

    /**
     * @dev Sets the solver address.
     * @param _solver Address of the solver.
     */
    constructor(address _solver){
        solver = _solver;
    }

    /**
     * @notice Creates a new intent transaction.
     * @param tokenAddress1 Address of the first token to be transferred.
     * @param amount1 Amount of the first token to be transferred.
     * @param tokenAddress2 Address of the second token to be transferred.
     * @param amount2 Amount of the second token to be transferred.
     * @param chainId ID of the destination chain for the intent transaction.
     */
    function createIntentTxn(
        address tokenAddress1,
        uint amount1,
        address tokenAddress2,
        uint amount2,
        uint chainId
    ) external {
        require(amount1 > 0 && amount2 > 0, "Amount cannot be 0");
        uint intentId = userIntentCount[msg.sender]++;
        userIntents[msg.sender][intentId] = IntentTxn({
            user: msg.sender,
            tokenAddress1: tokenAddress1,
            amount1: amount1,
            tokenAddress2: tokenAddress2,
            amount2: amount2,
            chainId: chainId,
            status: SettlementStatus.PENDING
        });

        IERC20(tokenAddress1).transferFrom(msg.sender, address(this), amount1);

        emit IntentCreated(msg.sender, intentId, tokenAddress1, amount1, tokenAddress2, amount2, chainId);
    }

    /**
     * @notice Allows the solver to withdraw a single intent transaction.
     * @param user Address of the user who created the intent transaction.
     * @param intentId ID of the intent transaction to be withdrawn.
     */
    function singleWithdraw(address user, uint intentId) external onlySolver() {
        require(userIntents[user][intentId].user == user, "User data not found");
        require(userIntents[user][intentId].status == SettlementStatus.PENDING, "Transaction is settled");
        
        // Get the intent transaction
        IntentTxn storage userData = userIntents[user][intentId];
        
        // Transfer token2 to the user
        IERC20(userData.tokenAddress2).transfer(userData.user, userData.amount2);

        emit SingleWithdrawn(msg.sender, user, intentId);
    }

    /**
     * @notice TODO: Allows the solver to withdraw multiple intent transactions in batch.
     */
    function batchWithdraw() external onlySolver {
        // Batch withdrawal logic goes here

        emit BatchWithdrawn(msg.sender, address(0), 0); // Placeholder for event parameters
    }
}
