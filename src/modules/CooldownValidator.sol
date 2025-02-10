// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../interfaces/IERC7579Account.sol";
import "../interfaces/IERC7579Module.sol";
import "../lib/ModeLib.sol";
import "../lib/ExecutionLib.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

contract CooldownValidator is IValidator {
    using ExecutionLib for bytes;

    error InvalidExec();

    mapping(address => bool) internal _initialized;

    // stores the last transaction timestamp for each account
    mapping(address => uint256) private lastTxnTimestamp;

    // cooldown period for each account transaction
    uint256 public constant COOLDOWN_PERIOD = 3 minutes;

    // error message for validation failure due to pending cooldown period
    error CooldownPeriodPending();

    function onInstall(
        bytes calldata // data
    )
        external
        override
    {
        if (isInitialized(msg.sender)) revert AlreadyInitialized(msg.sender);
        _initialized[msg.sender] = true;
    }

    function onUninstall(
        bytes calldata // data
    )
        external
        override
    {
        if (!isInitialized(msg.sender)) revert NotInitialized(msg.sender);
        _initialized[msg.sender] = false;
    }

    function isInitialized(address smartAccount) public view override returns (bool) {
        return _initialized[smartAccount];
    }

    function isModuleType(uint256 moduleTypeId) external pure override returns (bool) {
        return moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 //  userOpHash
    )
        external
        pure
        override
        returns (uint256 validationCode)
    {
        // get the function selector that will be called by EntryPoint
        // bytes4 execFunction = bytes4(userOp.callData[:4]);

        // get the mode
        CallType callType = CallType.wrap(bytes1(userOp.callData[4]));
        bytes calldata executionCalldata = userOp.callData[36:];
        if (callType == CALLTYPE_BATCH) {
            executionCalldata.decodeBatch();
        } else if (callType == CALLTYPE_SINGLE) {
            executionCalldata.decodeSingle();
        }
        return VALIDATION_SUCCESS;
    }

    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    )
        external
        view
        override
        returns (bytes4)
    { }

    /// @dev ERC1271 signature validation along with cooldown period
    function isValidCooldownSignature(
        address sender,
        bytes32 hash,
        bytes calldata data
    )
        external
        returns (bytes4)
    { 
        if(block.timestamp >= lastTxnTimestamp[sender] + COOLDOWN_PERIOD) {
            revert CooldownPeriodPending();
        }
        lastTxnTimestamp[sender] = block.timestamp;

        return IERC1271(sender).isValidSignature(hash, data);
    }
}
