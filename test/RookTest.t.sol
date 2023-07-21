// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Rook.sol";

contract RookTest is Test {
    Rook rook;
    address backupAddress = address(0x123);

    function setUp() public {
        rook = new Rook();
        rook.initialize(backupAddress);
    }

    function testInitialization() public {
        assertEq(
            rook.balanceOf(address(this)),
            50000000 * 10 ** rook.decimals()
        );
        assertEq(rook.name(), "Rook");
        assertEq(rook.symbol(), "ROOK");
        assertTrue(rook.hasRole(rook.DEFAULT_ADMIN_ROLE(), address(this)));
        assertTrue(rook.hasRole(rook.SNAPSHOT_ROLE(), address(this)));
        assertTrue(rook.hasRole(rook.PAUSER_ROLE(), address(this)));
        assertTrue(rook.hasRole(rook.MINTER_ROLE(), address(this)));
        assertTrue(rook.hasRole(rook.UPGRADER_ROLE(), address(this)));
    }
    /*
    function testSnapshot() public {
        rook.snapshot();
    }

    function testPauseUnpause() public {
        rook.pause();
        assertTrue(rook.paused());
        rook.unpause();
        assertFalse(rook.paused());
    }

    function testMint() public {
        uint256 amount = 10000 * 10 ** rook.decimals();
        rook.mint(address(this), amount);
        assertEq(
            rook.balanceOf(address(this)),
            500010000 * 10 ** rook.decimals()
        );
    }
/*
    function testRecoverControl() public {
        // Recover control from the backup address
        (bool success, ) = backupAddress.call(
            abi.encodeWithSignature("recoverControl(address)", address(this))
        );
        assertTrue(
            success,
            "Recover control should have succeeded from backup address"
        );

        // Verify that the backup address now has the roles
        assertTrue(
            rook.hasRole(rook.DEFAULT_ADMIN_ROLE(), backupAddress),
            "Backup address should have default admin role"
        );
        assertTrue(
            rook.hasRole(rook.SNAPSHOT_ROLE(), backupAddress),
            "Backup address should have snapshot role"
        );
        assertTrue(
            rook.hasRole(rook.PAUSER_ROLE(), backupAddress),
            "Backup address should have pauser role"
        );
        assertTrue(
            rook.hasRole(rook.MINTER_ROLE(), backupAddress),
            "Backup address should have minter role"
        );
        assertTrue(
            rook.hasRole(rook.UPGRADER_ROLE(), backupAddress),
            "Backup address should have upgrader role"
        );

        // Verify that the original address no longer has the roles
        assertFalse(
            rook.hasRole(rook.DEFAULT_ADMIN_ROLE(), address(this)),
            "Address should not have default admin role"
        );
        assertFalse(
            rook.hasRole(rook.SNAPSHOT_ROLE(), address(this)),
            "Address should not have snapshot role"
        );
        assertFalse(
            rook.hasRole(rook.PAUSER_ROLE(), address(this)),
            "Address should not have pauser role"
        );
        assertFalse(
            rook.hasRole(rook.MINTER_ROLE(), address(this)),
            "Address should not have minter role"
        );
        assertFalse(
            rook.hasRole(rook.UPGRADER_ROLE(), address(this)),
            "Address should not have upgrader role"
        );
    }
    */
}
