// SPDX-License-Identifier: MIT
// This is a Solidity contract that uses Chainlink's FunctionsClient to request and receive data from an external JavaScript function.
// The contract is designed to generate a backstory for a character in a role-playing game.
// It imports the RanCharacter contract to get the random character stats that are sent to the JavaScript function.
pragma solidity >=0.7.0;

// Importing necessary Chainlink contracts
import { FunctionsClient } from "lib/chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import { ConfirmedOwner } from "lib/chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import { FunctionsRequest } from "lib/chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

// Importing the contract that generates random character stats
import { RanCharacter } from "src/RanCharacter.sol";

// The FunctionsConsumer contract inherits from the FunctionsClient and ConfirmedOwner contracts.
contract FunctionsConsumer is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    // The DON ID for the Functions DON to which the requests are sent
    bytes32 public donId;
    // The latest backstory generated for a character
    string public latestBackstory;

    // Event that is emitted when a new backstory is generated
    event BackstoryGenerated(string latestBackstory);

    // The latest request ID, response, and error from the FunctionsClient
    bytes32 public latestRequestId;
    bytes public latestResponse;
    bytes public latestError;

    // The constructor sets the router and DON ID for the FunctionsClient, and sets the contract owner
    constructor(
        address router,
        bytes32 _donId
    ) FunctionsClient(router) ConfirmedOwner(msg.sender) {
        donId = _donId;
    }

    function requestBackstory(
        string memory characterClass,
        string memory characterRace,
        string memory characterName,
        string memory characterAlignment,
        string memory characterBackground,
        uint256[6] memory characterAbilities,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) external onlyOwner {
        FunctionsRequest.Request memory req = FunctionsRequest.init();
        req.setJsSourceCode("backstory-request.js");
        req.setStringArgs(
            [characterClass, characterRace, characterName, characterAlignment, characterBackground]
        );
        req.setUintArgs(characterAbilities);
        latestRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            callbackGasLimit,
            donId
        );
    }

    // Function to handle the response from the JavaScript function. The response is the generated backstory for the character.
    // This function is overridden from the FunctionsClient contract.
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        latestResponse = response;
        latestError = err;

        latestRequestId = requestId;
        latestBackstory = string(abi.encodePacked(response));
        emit BackstoryGenerated(latestBackstory);
    }
}