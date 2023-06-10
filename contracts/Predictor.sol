// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// todos--
// enter the match(by paying min amount),
// get the current matches from chianlink functions,
//automate the excutions using chainlink keepers,
// provide a option to withdraw the amount to their accounts.

//imports
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

/* Errors */
error Predictor__notEnoughFeeEntered(uint256 entryFee);
error Raffle__UpkeepNotNeeded();
error Predictor__inValidContest();
error Predictor__notEnoughBalance();

/**@title sports predictor smartcontract
 * @author Sandeep Reddy
 * @notice This contract is for betting/predicting the results of the match.
 * @dev This contract implements the Chainlink automations
 * and Chainlink functions for fetching the live matches & its results.
 */

contract sportsPredictor is AutomationCompatibleInterface {

    /* Type declarations */
    enum result {
        won_by_teamA,
        won_by_teamB,
        Draw_or_noResult
    }

    enum matchStatus {
        Yet_to_Start,
        in_Progress,
        Finished
    }

    /* state Variables */
    struct ContestDetails {
        mapping(address => PlayerStake) playerStakes;
        uint256 totalAmount_A;
        uint256 totalAmount_B;
        result contestResult;
    }

    struct PlayerStake {
        uint256 teamA;
        uint256 teamB;
    }

    struct Game {
        uint256 matchId;
        string teamA;
        string teamB;
        matchStatus status;
    }

    mapping(uint256 => ContestDetails) private contestEntrances;
    Game[] private ContestsId;
    mapping(address => uint256) private Winnings;
    uint256 private immutable i_entryFee;

    // chainlink automation varaiables
    uint256 private immutable interval;
    uint256 private lastTimeStamp;

    /* Events */
    event Ongoing_Contests(
        uint256 matchId,
        string teamA,
        string teamB,
        matchStatus status
    );
    event Contest_Status(
        uint256 matchId,
        matchStatus status,
        result contestResult
    );

    /* Functions */
    constructor(uint256 entranceFee, uint256 updateInterval) {
        i_entryFee = entranceFee;

        // had faced issues while fetchings api from chainlink functions which is in closed beta.
        // untill, hardcoded the contests and events.
        ContestsId.push(
            Game(11223, "india", "australia", matchStatus.Yet_to_Start)
        );
        emit Ongoing_Contests(
            11223,
            "india",
            "australia",
            matchStatus.Yet_to_Start
        );

        ContestsId.push(
            Game(12124, "india", "england", matchStatus.Yet_to_Start)
        );

        // Emit an event when contest is created
        emit Ongoing_Contests(
            12124,
            "india",
            "england",
            matchStatus.Yet_to_Start
        );

        ContestsId.push(
            Game(12546, "england", "australia", matchStatus.Yet_to_Start)
        );

        emit Ongoing_Contests(
            12546,
            "england",
            "australia",
            matchStatus.Yet_to_Start
        );

        interval = updateInterval;
        lastTimeStamp = block.timestamp;
    }

    /**
     * @notice this randomNum function generates the random number(ofcourse it can be tampered) in a desired range.
     * @dev This is the function intented to use for temporary purpose,
     *  had faced issues while fetchings api from chainlink functions which is in closed beta.
     * untill, random num generator replaces it.
     */

    function randomNum(uint256 range) internal view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(block.difficulty, block.timestamp))
            ) % range;
    }

    /**
     * @notice this createContest fuction creates the contests automatically after fetching results from chainlink functions.
     * @dev had faced issues while fetchings api from chainlink functions which is in closed beta.
     * untill, hardcoded the contests and events.
     */

    function createContest() private {
        uint256 randNum = randomNum(100000);
        ContestsId.push(
            Game(randNum, "TeamA", "TeamB", matchStatus.Yet_to_Start)
        );

        emit Ongoing_Contests(
            randNum,
            "TeamA",
            "TeamB",
            matchStatus.Yet_to_Start
        );
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The contract has ETH.
     * 2. Implicity, your subscription is funded with LINK.
     */

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }
    

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */

    function performUpkeep(bytes calldata /* performData */) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded();
        }

        // this loop currently hardcoded to chage the results for given time interval
        // gonna replace it with chainlink functions

        for (uint i = 0; i < ContestsId.length; i++) {
            if (ContestsId[i].status == matchStatus.in_Progress) {
                ContestsId[i].status = matchStatus.Finished;
                declareResult(i);
            } else if (ContestsId[i].status == matchStatus.Yet_to_Start) {
                ContestsId[i].status = matchStatus.in_Progress;
                emit Contest_Status(
                    i,
                    matchStatus.in_Progress,
                    result.Draw_or_noResult
                );
            }
        }

        createContest();

        lastTimeStamp = block.timestamp;
        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    }

    /**
     * @dev isValidContest is to check the contest is valid.
     */

    function isValidContest(uint256 _contestId) private view returns (bool) {
        for (uint256 i = 0; i < ContestsId.length; i++) {
            if (
                ContestsId[i].matchId == _contestId &&
                ContestsId[i].status == matchStatus.Yet_to_Start
            ) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice enterContest function is let you enter the contest.
     * @dev This is the function which let players enter the contest with minimum of enterance fee.
     * player has ability to place bet on both the teams, his stake is added accordingly
     */

    function enterContest(
        uint256 _contestId,
        string memory _team
    ) public payable {
        if (msg.value < i_entryFee) {
            revert Predictor__notEnoughFeeEntered(i_entryFee);
        }

        if (!isValidContest(_contestId)) {
            revert Predictor__inValidContest();
        }

        ContestDetails storage contest = contestEntrances[_contestId];
        PlayerStake storage playerStake = contest.playerStakes[msg.sender];

        if (
            keccak256(abi.encodePacked(_team)) ==
            keccak256(abi.encodePacked("teamA"))
        ) {
            contest.totalAmount_A += msg.value;
            playerStake.teamA += msg.value;
        } else {
            contest.totalAmount_B += msg.value;
            playerStake.teamB += msg.value;
        }
    }

    /**
     * @notice declareResult function is used to declare the result of the contest.
     * @dev This is the fake result simulater function ,
     *  which declares the result of the contest on random basis.
     * --- usually the results fetched from offchain functions.
     */

    function declareResult(uint256 _contestId) private {
        uint256 randNum = randomNum(3);
        ContestDetails storage contest = contestEntrances[_contestId];

        if (randNum == 0) {
            contest.contestResult = result.won_by_teamA;
            emit Contest_Status(
                _contestId,
                matchStatus.Finished,
                result.won_by_teamA
            );
        } else if (randNum == 1) {
            contest.contestResult = result.won_by_teamB;
            emit Contest_Status(
                _contestId,
                matchStatus.Finished,
                result.won_by_teamB
            );
        } else {
            contest.contestResult = result.Draw_or_noResult;
            emit Contest_Status(
                _contestId,
                matchStatus.Finished,
                result.Draw_or_noResult
            );
        }
    }

    /**
     * @notice fetchBalance function is used to fetch the balance from winnings.
     * @dev this function calculates the winnings from finished matches.
     * -- the logic "(playerStake.teamA * contest.totalAmount_B) / contest.totalAmount_A", gives the winning stake/percentage of TeamA-player in total amount of TeamB.
     * by adding above result with "playerStake.teamA" gives the total winnings of player who placed bet on teamA.
     * for contest resulting Draw/no_result, the placed bets add to winnings accordingly.
     */

    function fetchBalance() public returns (uint256) {
        uint256 totalWinnings;
        for (uint i = 0; i < ContestsId.length; i++) {
            if (ContestsId[i].status == matchStatus.Finished) {
                ContestDetails storage contest = contestEntrances[i];
                PlayerStake storage playerStake = contest.playerStakes[
                    msg.sender
                ];

                if (contest.totalAmount_A != 0 || contest.totalAmount_B != 0) {
                    if (playerStake.teamA != 0 || playerStake.teamB != 0) {
                        if (contest.contestResult == result.won_by_teamA) {
                            totalWinnings +=
                                (playerStake.teamA * contest.totalAmount_B) /
                                contest.totalAmount_A +
                                playerStake.teamA;
                        } else if (
                            contest.contestResult == result.won_by_teamB
                        ) {
                            totalWinnings +=
                                (playerStake.teamB * contest.totalAmount_A) /
                                contest.totalAmount_B +
                                playerStake.teamB;
                        } else {
                            totalWinnings +=
                                playerStake.teamA +
                                playerStake.teamB;
                        }
                        playerStake.teamA = 0;
                        playerStake.teamB = 0;
                    }
                }
            }
        }
        Winnings[msg.sender] += totalWinnings;
        return Winnings[msg.sender];
    }

    function withDrawBalance() public {
        uint256 balance = Winnings[msg.sender];
        if (balance <= 0) {
            revert Predictor__notEnoughBalance();
        }

        Winnings[msg.sender] = 0;

        payable(msg.sender).transfer(balance);
        // with transfer, if transaction fails, it is automatically reverted.
        //incase of send or call(returns bool), we have to call require expictly.
    }

    //getters

    function getEntranceFee() public view returns (uint256) {
        return i_entryFee;
    }

    function getBalance() public view returns (uint256) {
        return Winnings[msg.sender];
    }

/**
     * @notice getContestStake function gives the placed bet/stake of player. 
     */

    function getContestStake(
        uint256 _contestId,
        address _player
    ) public view returns (uint256, uint256, uint256, uint256) {
        if (!isValidContest(_contestId)) {
            revert Predictor__inValidContest();
        }
        ContestDetails storage contest = contestEntrances[_contestId];
        PlayerStake storage playerStake = contest.playerStakes[_player];
        return (
            contest.totalAmount_A,
            contest.totalAmount_B,
            playerStake.teamA,
            playerStake.teamB
        );
    }

    // function getTotalAmount(
    //    uint256 _contestId,
    // ) public view returns (uint256, uint256) {
    //     ContestDetails storage contest = contestEntrances[_contestId];
    //     return (contest.totalAmount_A, contest.totalAmount_B);
    // }

    // function getPlayerStake(
    //     uint256 _contestId,
    //     address _player
    // ) public view returns (uint256, uint256) {
    //     ContestDetails storage contest = contestEntrances[_contestId];
    //     PlayerStake storage playerStake = contest.playerStakes[_player];
    //     return (playerStake.teamA, playerStake.teamB);
    // }
}
