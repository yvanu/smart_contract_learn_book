// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice A deliberately small example for learning storage and access control.
contract Counter {
    address public immutable owner;
    uint256 public count;

    error Unauthorized();
    event Increased(address indexed caller, uint256 newCount);
    event Reset(address indexed caller);

    constructor() {
        owner = msg.sender;
    }

    function increase(uint256 amount) external {
        count += amount;
        emit Increased(msg.sender, count);
    }

    function reset() external {
        if (msg.sender != owner) revert Unauthorized();
        count = 0;
        emit Reset(msg.sender);
    }
}
