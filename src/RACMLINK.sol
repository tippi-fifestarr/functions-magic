// SPDX-License-Identifier: MIT
// the original RAGMATIC deployed on MATIC Amoy testnet at: 0x145Ea65c9e7A97028dfeD9F1F0fA71D5bA5dd00B
// this one will move us closer to the goal, explained in readme.md
pragma solidity 0.8.19;
// In the game of D&D, creating a new character can be a lot of fun, or take ages and prevent you from playing
// This contract is a simple example of how you can use Chainlink VRF to generate a random character
// A character has 6 ability scores, a class, a name, an alignment, and a background
// Also, there are Traits, Ideals, Bonds, and Flaws, but we'll keep it simple for now
// The character's name, class and background are chosen from on-chain arrays of strings in other contracts
// The ability scores are generated from a single random number using a bitshift and modulo

import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {OpenSourceRandomNames} from "./OSRN.sol";
import {OpenSourceRandomBackstory} from "./OSRB.sol";
import {OpenSourceRandomClasses} from "./OSRC.sol";

/**
 * @title VRF 2.5 example subscription contract for generating random characters
 */
contract QuickCharacterMATICLink is VRFConsumerBaseV2Plus {
    AggregatorV3Interface internal dataFeed;
    /**
     * Network: Amoy Testnet
     * Aggregator: LINK/USD
     * Address: 0xc2e2848e28B9fE430Ab44F55a8437a33802a219C
     */
    IVRFCoordinatorV2Plus COORDINATOR;
    OpenSourceRandomNames public randomNamesContract;
    OpenSourceRandomBackstory public randomBackstoryContract;
    OpenSourceRandomClasses public randomClassesContract;

    uint256 s_subscriptionId = 66118018734431823761931892674738616830700589109524327019309541755328276452105;
    bytes32 keyHash = 0x816bedba8a50b294e5cbd47842baf240c2385f2eaf719edbd4f250a137a8c899;
    // refactor code or use https://github.com/cgewecke/hardhat-gas-reporter 
    uint32 callbackGasLimit = 135000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 2; // 1 into 6 ability scores + 1 for class
     // USD price per character
    uint256 public pricePerCharacterUSD = 20 * 1e16; // For testing $0.20, assuming price feed uses 18 decimal places.


    struct Character {
        uint256 randomWord;
        uint256[6] abilities;
        string class;
        string playerName;
        string name;
        string alignment;
        string background;
        uint8 swaps;
    }

    mapping(uint256 => address) requestToSender;
    mapping(address => Character) public characters;

    event CharacterCreated(address owner, uint256 requestId);
    event CharacterUpdated(address owner, string alignment, string background);
    event ScoresSwapped(address owner);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event RandomWordSaved(address owner);
    event RandomContractsSet(address randomNamesContract, address randomBackstoryContract, address randomClassesContract);


    constructor() VRFConsumerBaseV2Plus(0x343300b5d84D444B2ADc9116FEF1bED02BE49Cf2)
 {
        COORDINATOR = IVRFCoordinatorV2Plus(
            0x343300b5d84D444B2ADc9116FEF1bED02BE49Cf2
        );
        dataFeed = AggregatorV3Interface(0xc2e2848e28B9fE430Ab44F55a8437a33802a219C);
    }

        /**
     * Returns the latest answer using the Chainlink data feed on MATIC testnet
     */
    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    // Function to get the cost in ETH for creating a character
    function getCharacterCostInLINK() public view returns (uint256) {
        int linkPrice = getChainlinkDataFeedLatestAnswer(); // Price of 1 ETH in USD (with 18 decimals)
        require(linkPrice > 0, "Link price is non-positive");
        return (pricePerCharacterUSD * 1e18) / uint256(linkPrice); // Returns cost in wei
    }

    // function to set both contracts at once
    function setRandomContracts(address _randomNamesContract, address _randomBackstoryContract, address _randomClassesContract) external {
        randomNamesContract = OpenSourceRandomNames(_randomNamesContract);
        randomBackstoryContract = OpenSourceRandomBackstory(_randomBackstoryContract);
        randomClassesContract = OpenSourceRandomClasses(_randomClassesContract);
        emit RandomContractsSet(_randomNamesContract, _randomBackstoryContract, _randomClassesContract);
    }

    function createCharacter(string calldata playerName) external {
        // check that the random contracts are set
        require(address(randomNamesContract) != address(0) && address(randomBackstoryContract) != address(0) && address(randomClassesContract) != address(0), "Random contracts not set");
        require(characters[msg.sender].randomWord == 0, "Character already created, use finalizeCharacterDetails");
        uint256 requestId = COORDINATOR.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        characters[msg.sender].playerName = playerName;
        requestToSender[requestId] = msg.sender;
        emit CharacterCreated(msg.sender, requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
    address owner = requestToSender[requestId];
    require(characters[owner].randomWord == 0, "Random words already fulfilled");

    characters[owner].randomWord = randomWords[0];
    characters[owner].class = getClass(randomWords[1]);

    emit RequestFulfilled(requestId, randomWords);
    emit RandomWordSaved(owner);
    }

    function finalizeCharacterDetails(string calldata alignment) external {
    require(characters[msg.sender].randomWord != 0, "Random words not fulfilled");

    uint256 randomWord = characters[msg.sender].randomWord;
    for (uint i = 0; i < 6; ++i) {
        uint256 chunk = (randomWord >> (i * 32)) & 0xFFFFFFFF; // Extract 32-bit chunks
        characters[msg.sender].abilities[i] = (chunk % 16) + 3; // Score range: 3-18
    }
    
    // mod a value between 0-19 from the random word
    uint256 randomNumber = randomWord % 20;
    characters[msg.sender].name = randomNamesContract.names(randomNumber);
    characters[msg.sender].alignment = alignment;
    randomNumber = (randomWord >> 32) % 15;
    characters[msg.sender].background = randomBackstoryContract.backstories(randomNumber);    

    emit CharacterUpdated(msg.sender, alignment, characters[msg.sender].background);
    }

    function updateCharacterDetails(string calldata name, string calldata alignment, string calldata background) external {
        require(characters[msg.sender].randomWord != 0, "Random words not fulfilled");

        if (bytes(name).length > 0) {
            characters[msg.sender].name = name;
        }
        if (bytes(alignment).length > 0) {
            characters[msg.sender].alignment = alignment;
        }
        if (bytes(background).length > 0) {
            characters[msg.sender].background = background;
        }
        emit CharacterUpdated(msg.sender, alignment, background);
    }

    function swapScores(uint8 index1, uint8 index2) external {
        require(characters[msg.sender].swaps < 3, "Max swaps reached");
        require(index1 < 6 && index2 < 6, "Invalid index");

        (characters[msg.sender].abilities[index1], characters[msg.sender].abilities[index2]) = 
        (characters[msg.sender].abilities[index2], characters[msg.sender].abilities[index1]);
        characters[msg.sender].swaps++;
        emit ScoresSwapped(msg.sender);
    }

    function getClass(uint256 randomNumber) private view returns (string memory) {
        return randomClassesContract.classes(randomNumber % 13);
    }

    // because the ability scores are stored as an array, they aren't easily readable
    // this function allows us to get the ability scores of a character
    function getCharacterAbilities(address owner) external view returns (uint256[6] memory) {
        return characters[owner].abilities;
    }
}