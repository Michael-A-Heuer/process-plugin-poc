// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.8;

/// @title ProcessPermissionLib
/// @author Aragon X - 2024
/// @notice A library containing the permission constants of the Process plugin.
/// @custom:security-contact sirt@aragon.org
library ProcessPermissionLib {
    /// @notice The ID of the permission required to call the `createProposal` function.
    bytes32 public constant CREATE_PROPOSAL_PERMISSION_ID = keccak256("CREATE_PROPOSAL_PERMISSION");

    /// @notice The ID of the permission required to call the `executeProposal` function.
    bytes32 public constant EXECUTE_PERMISSION_ID = keccak256("EXECUTE_PERMISSION");
}
