// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.8;

import {SafeCastUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import {PluginUUPSUpgradeable} from "@aragon/osx-commons-contracts/src/plugin/PluginUUPSUpgradeable.sol";
import {IDAO} from "@aragon/osx-commons-contracts/src/dao/IDAO.sol";

import {Process} from "./Process.sol";

contract EvansProcess is Process {
    using SafeCastUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    function _createProposal(
        bytes calldata _metadata,
        IDAO.Action[] calldata _actions,
        uint256 _allowFailureMap
    ) internal override {
        uint64 currentTimestamp64 = block.timestamp.toUint64();

        // Create the proposal ID and emit an event.
        uint256 proposalId = _createProposal({
            _creator: _msgSender(),
            _metadata: _metadata,
            _startDate: currentTimestamp64,
            _endDate: currentTimestamp64, // TODO
            _actions: _actions,
            _allowFailureMap: _allowFailureMap
        });

        // Store the proposal
        Proposal storage proposal_ = proposals[proposalId];
        proposal_.actions = _actions;
        proposal_.allowFailureMap = _allowFailureMap;
    }

    function _approveProposal(uint256 _proposalId, bool _tryExecution) internal override {
        // Approve the proposal with the calling body.
        bool success = proposals[_proposalId].approvers.add(msg.sender);

        // Revert if the approval happened already.
        if (!success) {
            revert ApprovedAlready({caller: msg.sender});
        }

        // Optionally, try execution.
        if (_tryExecution) {
            _executeProposal(_proposalId);
        }
    }

    function _executeProposal(uint256 _proposalId) internal override {
        // Check the execution criteria.
        uint256 approvalCount = proposals[_proposalId].approvers.length();
        if (approvalCount < approvalThreshold) {
            revert ApprovalThresholdNotMet({limit: approvalThreshold, actual: approvalCount});
        }

        // Execute the proposal through the DAO's executor.
        _executeProposal(
            dao(),
            _proposalId,
            proposals[_proposalId].actions,
            proposals[_proposalId].allowFailureMap
        );
    }
}

//contract PolygonsDreamProcess is Process {}
