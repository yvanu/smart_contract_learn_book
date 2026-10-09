// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../src/Escrow.sol";

interface VmEscrow {
    function deal(address who, uint256 newBalance) external;
    function prank(address sender) external;
    function warp(uint256 timestamp) external;
    function expectRevert(bytes4 selector) external;
}

contract RejectingReceiver {
    receive() external payable {
        revert("receiver rejects ETH");
    }
}

contract EscrowTest {
    VmEscrow constant vm = VmEscrow(address(uint160(uint256(keccak256("hevm cheat code")))));
    address internal constant BUYER = address(0xB0B);
    address internal constant SELLER = address(0xCAFE);
    address internal constant STRANGER = address(0xD00D);
    Escrow escrow;

    function setUp() public {
        vm.deal(BUYER, 10 ether);
        vm.prank(BUYER);
        escrow = new Escrow{value: 1 ether}(SELLER, block.timestamp + 7 days);
    }

    function testDeployment() public view {
        require(escrow.buyer() == BUYER, "wrong buyer");
        require(escrow.seller() == SELLER, "wrong seller");
        require(escrow.amount() == 1 ether, "wrong amount");
        require(address(escrow).balance == 1 ether, "wrong balance");
        require(escrow.state() == Escrow.State.Funded, "wrong state");
    }

    function testDeliverAndRelease() public {
        vm.prank(SELLER);
        escrow.markDelivered();
        vm.prank(BUYER);
        escrow.release();
        require(escrow.state() == Escrow.State.Released, "not released");
        require(SELLER.balance == 1 ether, "seller not paid");
        require(address(escrow).balance == 0, "escrow not empty");
    }

    function testUnauthorizedDelivery() public {
        vm.expectRevert(Escrow.Unauthorized.selector);
        vm.prank(STRANGER);
        escrow.markDelivered();
    }

    function testUnauthorizedRelease() public {
        vm.prank(SELLER);
        escrow.markDelivered();
        vm.expectRevert(Escrow.Unauthorized.selector);
        vm.prank(STRANGER);
        escrow.release();
    }

    function testCannotReleaseBeforeDelivery() public {
        vm.expectRevert(Escrow.InvalidState.selector);
        vm.prank(BUYER);
        escrow.release();
    }

    function testCannotRefundBeforeDeadline() public {
        vm.expectRevert(Escrow.TooEarly.selector);
        vm.prank(BUYER);
        escrow.refund();
    }

    function testRefundAfterDeadline() public {
        vm.warp(escrow.deadline());
        uint256 original = BUYER.balance;
        vm.prank(BUYER);
        escrow.refund();
        require(escrow.state() == Escrow.State.Refunded, "not refunded");
        require(BUYER.balance == original + 1 ether, "buyer not refunded");
    }

    function testCannotReleaseAfterRefund() public {
        vm.prank(SELLER);
        escrow.markDelivered();
        vm.warp(escrow.deadline());
        vm.prank(BUYER);
        escrow.refund();
        vm.expectRevert(Escrow.InvalidState.selector);
        vm.prank(BUYER);
        escrow.release();
    }

    function testRejectInvalidSeller() public {
        vm.expectRevert(Escrow.InvalidSeller.selector);
        vm.prank(BUYER);
        new Escrow{value: 1 ether}(BUYER, block.timestamp + 7 days);
    }

    function testRejectZeroDeposit() public {
        vm.expectRevert(Escrow.InvalidDeposit.selector);
        vm.prank(BUYER);
        new Escrow(SELLER, block.timestamp + 7 days);
    }

    function testRejectPastDeadline() public {
        vm.expectRevert(Escrow.InvalidDeadline.selector);
        vm.prank(BUYER);
        new Escrow{value: 1 ether}(SELLER, block.timestamp);
    }

    function testSellerCannotDeliverAfterDeadline() public {
        vm.warp(escrow.deadline());
        vm.expectRevert(Escrow.DeadlinePassed.selector);
        vm.prank(SELLER);
        escrow.markDelivered();
    }

    function testRejectingSellerDoesNotLoseFunds() public {
        RejectingReceiver rejecting = new RejectingReceiver();
        vm.prank(BUYER);
        Escrow other = new Escrow{value: 1 ether}(address(rejecting), block.timestamp + 7 days);
        vm.prank(address(rejecting));
        other.markDelivered();
        vm.expectRevert(Escrow.TransferFailed.selector);
        vm.prank(BUYER);
        other.release();
        require(other.state() == Escrow.State.Delivered, "incorrect terminal state");
        require(address(other).balance == 1 ether, "funds disappeared");
    }

    function testFuzz_RefundAnyTimeAfterDeadline(uint64 elapsed) public {
        vm.warp(escrow.deadline() + uint256(elapsed));
        vm.prank(BUYER);
        escrow.refund();
        require(escrow.state() == Escrow.State.Refunded, "not refunded");
    }
}
