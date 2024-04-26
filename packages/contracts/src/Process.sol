// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.21;

import {SafeCastUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import {PluginUUPSUpgradeable} from "@aragon/osx-commons-contracts/src/plugin/PluginUUPSUpgradeable.sol";
import {ProposalUpgradeable} from "@aragon/osx-commons-contracts/src/plugin/extensions/proposal/ProposalUpgradeable.sol";
import {IDAO} from "@aragon/osx-commons-contracts/src/dao/IDAO.sol";

import {ProcessPermissionLib} from "./ProcessPermissionLib.sol";

interface IProcess {
    function createProposal(
        bytes calldata _metadata,
        IDAO.Action[] calldata _actions,
        uint256 _allowFailureMap
    ) external;

    function approveProposal(uint256 _proposalId, bool _tryExecution) external;

    function executeProposal(uint256 _proposalId) external;
}

/// @title Process
/// @dev Release 1, Build 1
abstract contract Process is PluginUUPSUpgradeable, IProcess, ProposalUpgradeable {
    using SafeCastUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct Proposal {
        bool executed;
        EnumerableSetUpgradeable.AddressSet approvers;
        IDAO.Action[] actions;
        uint256 allowFailureMap;
    }

    error InvalidCaller(address caller);
    error ApprovedAlready(address caller);
    error ApprovalThresholdNotMet(uint256 limit, uint256 actual);

    uint256 internal approvalThreshold;
    EnumerableSetUpgradeable.AddressSet internal bodies;
    mapping(uint256 proposalId => Proposal data) internal proposals;

    /// @notice Initializes the plugin when build 1 is installed.
    function initialize(
        IDAO _dao,
        uint256 _approvalThreshold,
        address[] memory _bodies
    ) external initializer {
        __PluginUUPSUpgradeable_init(_dao);

        approvalThreshold = _approvalThreshold;

        for (uint256 i; i < _bodies.length; ) {
            bodies.add(_bodies[i]);
            unchecked {
                ++i;
            }
        }
    }

    // External functions.
    function createProposal(
        bytes calldata _metadata,
        IDAO.Action[] calldata _actions,
        uint256 _allowFailureMap
    ) external virtual onlyBody {
        _createProposal({
            _metadata: _metadata,
            _actions: _actions,
            _allowFailureMap: _allowFailureMap
        });
    }

    function approveProposal(uint256 _proposalId, bool _tryExecution) external onlyBody {
        _approveProposal({_proposalId: _proposalId, _tryExecution: _tryExecution});
    }

    function executeProposal(uint256 _proposalId) external onlyBody {
        _executeProposal({_proposalId: _proposalId});
    }

    modifier onlyBody() {
        _checkBody();
        _;
    }

    function _checkBody() internal view {
        if (!bodies.contains(msg.sender)) {
            revert InvalidCaller({caller: msg.sender});
        }
    }

    function _createProposal(
        bytes calldata _metadata,
        IDAO.Action[] calldata _actions,
        uint256 _allowFailureMap
    ) internal virtual;

    function _approveProposal(uint256 _proposalId, bool _tryExecution) internal virtual;

    function _executeProposal(uint256 _proposalId) internal virtual;

    // -------------
    // BORING THINGS
    // -------------

    /// @notice Disables the initializers on the implementation contract to prevent it from being left uninitialized.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice The [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface ID of the contract.
    bytes4 internal constant PROCESS_INTERFACE_ID =
        this.initialize.selector ^
            this.createProposal.selector ^
            this.approveProposal.selector ^
            this.executeProposal.selector;

    /// @notice Checks if this or the parent contract supports an interface by its ID.
    /// @param _interfaceId The ID of the interface.
    /// @return Returns `true` if the interface is supported.
    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(PluginUUPSUpgradeable, ProposalUpgradeable) returns (bool) {
        return _interfaceId == PROCESS_INTERFACE_ID || super.supportsInterface(_interfaceId);
    }

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[47] private __gap;
}
