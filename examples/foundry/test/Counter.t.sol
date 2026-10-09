// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../src/Counter.sol";

interface VmCounter {
    function prank(address) external;
    function expectRevert(bytes4) external;
}

contract CounterTest {
    VmCounter constant vm = VmCounter(address(uint160(uint256(keccak256("hevm cheat code")))));
    Counter counter;

    function setUp() public {
        counter = new Counter();
    }

    function testOwnerCanReset() public {
        counter.increase(3);
        require(counter.count() == 3, "wrong increase");
        counter.reset();
        require(counter.count() == 0, "wrong reset");
    }

    function testOtherAccountCannotReset() public {
        vm.expectRevert(Counter.Unauthorized.selector);
        vm.prank(address(0xBEEF));
        counter.reset();
    }

    function testFuzz_Increase(uint256 amount) public {
        counter.increase(amount);
        require(counter.count() == amount, "count mismatch");
    }
}
