// SPDX-License-Identifier: MIT
/**
██████╗  ██████╗  ██████╗ ██╗  ██╗
██╔══██╗██╔═══██╗██╔═══██╗██║ ██╔╝
██████╔╝██║   ██║██║   ██║█████╔╝
██╔══██╗██║   ██║██║   ██║██╔═██╗
██║  ██║╚██████╔╝╚██████╔╝██║  ██╗
╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝
v1.0
www.UniRook.com  */

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/// @custom:security-contact devteam@unirook.com
contract Rook is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20SnapshotUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");
    bytes32 public constant PROFESSOR_ROLE = keccak256("PROFESSOR_ROLE");
    bytes32 public constant REWARDER_ROLE = keccak256("REWARDER_ROLE");

    address public currentAdmin;
    address public lockerContract; //The RKT (RookTranscript NFT ERC721 Contract)
    address public rewardsAccount; //The NFD (RookDegree NFT ERC721 Contract)
    bytes32 private hashedBackupAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _backupAddress) public initializer {
        __Context_init();
        __ERC20_init("UniRook", "ROOK");
        __ERC20Burnable_init();
        __ERC20Snapshot_init();
        __AccessControl_init();
        __Pausable_init();
        __ERC20Permit_init("Rook");
        __ERC20Votes_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(SNAPSHOT_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
        _grantRole(PROFESSOR_ROLE, _msgSender());
        _grantRole(REWARDER_ROLE, _msgSender());

        // Set the current admin to the msg.sender at initialization
        currentAdmin = _msgSender();

        // Set secret backup recovery address
        hashedBackupAddress = keccak256(abi.encodePacked(_backupAddress));

        // Set token supply
        _mint(_msgSender(), 50000000 * 10 ** decimals());
    }

    function recoverControl(address newBackupAddress) external {
        require(
            keccak256(abi.encodePacked(_msgSender())) == hashedBackupAddress,
            "Only the backup address can call this function."
        );

        // Grant roles to the recovery admin
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(SNAPSHOT_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
        _grantRole(PROFESSOR_ROLE, _msgSender());
        _grantRole(REWARDER_ROLE, _msgSender());

        // Revoke all roles from the original admin
        _revokeRole(DEFAULT_ADMIN_ROLE, currentAdmin);
        _revokeRole(SNAPSHOT_ROLE, currentAdmin);
        _revokeRole(PAUSER_ROLE, currentAdmin);
        _revokeRole(MINTER_ROLE, currentAdmin);
        _revokeRole(BURNER_ROLE, currentAdmin);
        _revokeRole(UPGRADER_ROLE, currentAdmin);
        _revokeRole(PROFESSOR_ROLE, currentAdmin);
        _revokeRole(REWARDER_ROLE, currentAdmin);

        // Set the previous backup address (function caller) as the current admin
        currentAdmin = _msgSender();

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

    // Function for  RKT (RookTranscript NFT contract) to call to burn deposited tokens
    function burnFrom(
        address account,
        uint256 amount
    ) public override onlyRole(BURNER_ROLE) {
        _burn(account, amount);
    }

    // Function call to set RKD (RookDegree NFD contract) to hold locked tokens for rewards
    function setRewardsAccount(
        address _contract
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            AddressUpgradeable.isContract(_contract),
            "Assigned address must be a contract"
        );
        rewardsAccount = _contract;
    }

    // Function call to set RKD (RookDegree) as Rewarder Role
    function assignRewarderRole(
        address _contract
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            AddressUpgradeable.isContract(_contract),
            "Assigned address must be a contract"
        );

        grantRole(REWARDER_ROLE, _contract);
    }

    function mintReward(
        address to,
        uint256 amount
    ) public onlyRole(REWARDER_ROLE) {
        _mint(to, amount);
    }

    function rewardFromPool(
        address to,
        uint256 amount
    ) public onlyRole(REWARDER_ROLE) {
        require(
            balanceOf(rewardsAccount) >= amount,
            "Not enough tokens in rewards pool"
        );
        _transfer(rewardsAccount, to, amount);
    }

    //Grant RKT (RookTranscript) the locker role to lock tokens to NFD for rewards
    function assignLockerRole(
        address _contract
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            AddressUpgradeable.isContract(_contract),
            "Assigned address must be a contract"
        );

        grantRole(LOCKER_ROLE, _contract);
        lockerContract = _contract;
    }

    // Function for RKT (RookTranscript) to transfer deposited tokens to the RKD (RookDegree)
    function lockTokens(address account, uint256 amount) public {
        require(
            hasRole(LOCKER_ROLE, _msgSender()),
            "Must be RKT contract to lock tokens."
        );

        _transfer(account, rewardsAccount, amount);
    }

    //To be used to interact with RKT (RookTranscript contract)
    function assignProfessorRole(
        address professorAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(PROFESSOR_ROLE, professorAddress);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override(ERC20Upgradeable, ERC20SnapshotUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._mint(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._burn(account, amount);
    }
}
