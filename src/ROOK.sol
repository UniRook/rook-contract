// SPDX-License-Identifier: MIT
/**
██████╗  ██████╗  ██████╗ ██╗  ██╗
██╔══██╗██╔═══██╗██╔═══██╗██║ ██╔╝
██████╔╝██║   ██║██║   ██║█████╔╝
██╔══██╗██║   ██║██║   ██║██╔═██╗
██║  ██║╚██████╔╝╚██████╔╝██║  ██╗
╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝
*/
pragma solidity ^0.8.13;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

/// @custom:security-contact devteam@unirook.com
contract Rook is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20SnapshotUpgradeable, AccessControlUpgradeable, PausableUpgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable, UUPSUpgradeable {
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    bytes32 private hashedBackupAddress;

    address public burnerContract;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _backupAddress) initializer public {
        __ERC20_init("Rook", "ROOK");
        __ERC20Burnable_init();
        __ERC20Snapshot_init();
        __AccessControl_init();
        __Pausable_init();
        __ERC20Permit_init("Rook");
        __ERC20Votes_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SNAPSHOT_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        _mint(msg.sender, 100000000 * 10 ** decimals());

        hashedBackupAddress = keccak256(abi.encodePacked(_backupAddress));
    }

    function recoverControl(address newBackupAddress) external {
    require(keccak256(abi.encodePacked(msg.sender)) == hashedBackupAddress, "Only the backup address can call this function.");

    // Grant roles to the recovery admin
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(SNAPSHOT_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _grantRole(UPGRADER_ROLE, msg.sender);

    // Revoke all roles from the original admin
    renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    renounceRole(SNAPSHOT_ROLE, msg.sender);
    renounceRole(PAUSER_ROLE, msg.sender);
    renounceRole(MINTER_ROLE, msg.sender);
    renounceRole(UPGRADER_ROLE, msg.sender);

    // Update the hashedBackupAddress with the hash of the new backup address
    hashedBackupAddress = keccak256(abi.encodePacked(newBackupAddress));
    }

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function assignBurnerRole(address _contract) public onlyRole(DEFAULT_ADMIN_ROLE) {
        //To be called once to implement NFT contract as the burner of ROOK tokens and recipricate Transcript,
        //verify BURNER_ROLE is a contract, and that is can only be set once
        require(Address.isContract(_contract), "Assigned address must be a contract");
        if (burnerContract == address(0)) {
            grantRole(BURNER_ROLE, _contract);
            burnerContract = _contract;
        }
    }

    //Function for NFT contract RKT (RookTranscript) to call to burn deposited tokens
    function burnFrom(address account, uint256 amount) public onlyRole(BURNER_ROLE) {
    _burn(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20Upgradeable, ERC20SnapshotUpgradeable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._burn(account, amount);
    }
}
