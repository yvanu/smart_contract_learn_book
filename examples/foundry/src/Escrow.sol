// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Learning-only ETH escrow. Not audited; do not use with real funds.
/// @dev One instance represents exactly one order. No arbitration or upgrade path.
contract Escrow {
    enum State { Funded, Delivered, Released, Refunded }

    address public immutable buyer;
    address public immutable seller;
    uint256 public immutable amount;
    uint256 public immutable deadline;
    State public state;

    error Unauthorized();
    error InvalidSeller();
    error InvalidDeposit();
    error InvalidDeadline();
    error InvalidState();
    error TooEarly();
    error DeadlinePassed();
    error TransferFailed();

    event Funded(address indexed buyer, address indexed seller, uint256 amount, uint256 deadline);
    event Delivered(address indexed seller);
    event Released(address indexed seller, uint256 amount);
    event Refunded(address indexed buyer, uint256 amount);

    constructor(address seller_, uint256 deadline_) payable {
        if (seller_ == address(0) || seller_ == msg.sender) revert InvalidSeller();
        if (msg.value == 0) revert InvalidDeposit();
        if (deadline_ <= block.timestamp) revert InvalidDeadline();

        buyer = msg.sender;
        seller = seller_;
        amount = msg.value;
        deadline = deadline_;
        state = State.Funded;
        emit Funded(buyer, seller, amount, deadline);
    }

    function markDelivered() external {
        if (msg.sender != seller) revert Unauthorized();
        if (state != State.Funded) revert InvalidState();
        if (block.timestamp >= deadline) revert DeadlinePassed();

        state = State.Delivered;
        emit Delivered(msg.sender);
    }

    function release() external {
        if (msg.sender != buyer) revert Unauthorized();
        if (state != State.Delivered) revert InvalidState();

        // Checks -> Effects -> Interactions. A reverting receiver restores state.
        state = State.Released;
        emit Released(seller, amount);
        (bool ok, ) = payable(seller).call{value: amount}("");
        if (!ok) revert TransferFailed();
    }

    function refund() external {
        if (msg.sender != buyer) revert Unauthorized();
        if (state != State.Funded && state != State.Delivered) revert InvalidState();
        if (block.timestamp < deadline) revert TooEarly();

        state = State.Refunded;
        emit Refunded(buyer, amount);
        (bool ok, ) = payable(buyer).call{value: amount}("");
        if (!ok) revert TransferFailed();
    }
}
