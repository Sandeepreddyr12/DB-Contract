// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


// todos--
// enter the match(by paying min entrance Fee),
// get the current matches from chianlink functions,
//automate the excutions using chainlink keepers,
// provide a option to withdraw the winnings to their respective accounts.

//imports
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

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

contract sportsPredictor {
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
    // uint256 private immutable interval;
    // uint256 private lastTimeStamp;

    /* Events */
    event Ongoing_Contests(
        uint256 matchId,
        string teamA,
        string teamB,
        string status
    );
    event Contest_Status(uint256 matchId, string status, string contestResult);

    event Enter_Contest(
        address player,
        uint256 matchId,
        string team,
        uint256 value
    );

    /* Functions */
    constructor(uint256 entranceFee) {
        i_entryFee = entranceFee;

        // interval = updateInterval;
        // lastTimeStamp = block.timestamp;

        createContest();
    }

    /**
     * @notice this randomNum function generates the random number(ofcourse it can be tampered) in a desired range.
     * @dev This is the function intented to use for temporary purpose,
     *  had faced issues while fetchings api from chainlink functions which is in closed beta.
     * untill, random num generator replaces it.
     */

    function randomNum(uint256 range) private view returns (uint256) {
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
        uint256 randNum = randomNum(1000000);

        // had faced issues while fetchings api from chainlink functions which is in closed beta.
        // untill, hardcoded the contests and events.

        ContestsId.push(
            Game(randNum, "India", "Australia", matchStatus.Yet_to_Start)
        );
        emit Ongoing_Contests(randNum, "India", "Australia", "Yet_to_Start");

        ContestsId.push(
            Game(randNum + 1, "Newzealand", "England", matchStatus.Yet_to_Start)
        );

        // Emit an event when contest is created
        emit Ongoing_Contests(
            randNum + 1,
            "Newzealand",
            "England",
            "Yet_to_Start"
        );

        ContestsId.push(
            Game(
                randNum + 2,
                "SouthAfrica",
                "Srilanka",
                matchStatus.Yet_to_Start
            )
        );

        emit Ongoing_Contests(
            randNum + 2,
            "SouthAfrica",
            "Srilanka",
            "Yet_to_Start"
        );
    }

    //Below is the automated chainlink code, the same task can be achieved manually on chainlink's website.
    // The code has been commented out instead of removing it to prevent future re-use.

    // /**
    //  * @dev This is the function that the Chainlink Keeper nodes call
    //  * they look for `upkeepNeeded` to return True.
    //  * the following should be true for this to return true:
    //  * 1. The contract has ETH.
    //  * 2. Implicity, your subscription is funded with LINK.
    //  */

    // function checkUpkeep(
    //     bytes memory /* checkData */
    // )
    //     public
    //     view
    //     override
    //     returns (bool upkeepNeeded, bytes memory /* performData */)
    // {
    //     upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    //     // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    //     return (upkeepNeeded, "0x0");
    // }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */

    // function performUpkeep(bytes calldata /* performData */) external override {
    //     //We highly recommend revalidating the upkeep in the performUpkeep function
    //     (bool upkeepNeeded, ) = checkUpkeep("");
    //     if (!upkeepNeeded) {
    //         revert Raffle__UpkeepNotNeeded();
    //     }

    //     // this loop currently hardcoded to chage the results for given time interval
    //     // gonna replace it with chainlink functions

    //     for (uint i = 0; i < ContestsId.length; i++) {
    //         if (ContestsId[i].status == matchStatus.in_Progress) {
    //             ContestsId[i].status = matchStatus.Finished;
    //             declareResult(i);
    //         } else if (ContestsId[i].status == matchStatus.Yet_to_Start) {
    //             ContestsId[i].status = matchStatus.in_Progress;
    //             emit Contest_Status(
    //                 i,
    //                 matchStatus.in_Progress,
    //                 result.Draw_or_noResult
    //             );
    //         }
    //     }

    //     createContest();

    //     lastTimeStamp = block.timestamp;
    //     // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    // }

    /**
     * @dev below is an chainlink upkeep function. which get triggered by chain link oracles.
     */

    function performUpkeep() public {
        // this loop currently hardcoded to chage the results for given time interval
        // gonna replace it with chainlink functions

        for (uint i = 0; i < ContestsId.length; i++) {
            if (ContestsId[i].status == matchStatus.in_Progress) {
                ContestsId[i].status = matchStatus.Finished;
                declareResult(ContestsId[i].matchId);
            } else if (ContestsId[i].status == matchStatus.Yet_to_Start) {
                ContestsId[i].status = matchStatus.in_Progress;
                emit Contest_Status(
                    ContestsId[i].matchId,
                    "in_Progress",
                    "on_going"
                );
            }
        }

        createContest();

        // lastTimeStamp = block.timestamp;
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
        emit Enter_Contest(msg.sender, _contestId, _team, msg.value);
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
            emit Contest_Status(_contestId, "Finished", "won_by_teamA");
        } else if (randNum == 1) {
            contest.contestResult = result.won_by_teamB;
            emit Contest_Status(_contestId, "Finished", "won_by_teamB");
        } else {
            contest.contestResult = result.Draw_or_noResult;
            emit Contest_Status(_contestId, "Finished", "Draw_or_noResult");
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
                ContestDetails storage contest = contestEntrances[
                    ContestsId[i].matchId
                ];
                PlayerStake storage playerStake = contest.playerStakes[
                    msg.sender
                ];

                if (contest.totalAmount_A != 0 || contest.totalAmount_B != 0) {
                    if (playerStake.teamA != 0 || playerStake.teamB != 0) {
                        if (contest.contestResult == result.won_by_teamA) {
                            // carefully while doing divisions/percentages in soliidty, it doesn't supports floating point numbers.
                            // here in below case, calculations are safe, unless there is a slight chance,
                            // when contest totalAmount value greater than thousands of billion ether, which is virtually impossible.

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

    function withDrawWinnigs() public {
        uint256 balance = Winnings[msg.sender];
        if (balance <= 0) {
            revert Predictor__notEnoughBalance();
        }

        Winnings[msg.sender] = 0;

        payable(msg.sender).transfer(balance);
        // with transfer, if transaction fails, it is automatically reverted.
        //incase of send or call(returns bool), we have to call require expictly.
    }

    //  function to withdraw contract balance

    //     function withdraw() public onlyOwner {
    //         uint256 amount = address(this).balance;
    //         if (amount <= 0) {
    //             revert Predictor__notEnoughBalance();
    //         }

    //         payable(msg.sender).transfer(amount);
    //         // with transfer, if transaction fails, it is automatically reverted.
    //         //incase of send or call(returns bool), we have to call require expictly.
    //     }

    //getters

    function getEntranceFee() public view returns (uint256) {
        return i_entryFee;
    }

    // function getUpdateInterval() public view returns (uint256) {
    //     return interval;
    // }

    function getBalance() public view returns (uint256) {
        return Winnings[msg.sender];
    }

    /**
     * @notice getContestStake function gives the placed bet/stake of player.
     */

    function getPlayerStake(
        uint256 _contestId
    ) public view returns (uint256, uint256, uint256, uint256) {
        // not needed
        // if (!isValidContest(_contestId)) {
        //     revert Predictor__inValidContest();
        // }
        ContestDetails storage contest = contestEntrances[_contestId];
        PlayerStake storage playerStake = contest.playerStakes[msg.sender];
        return (
            contest.totalAmount_A,
            contest.totalAmount_B,
            playerStake.teamA,
            playerStake.teamB
        );
    }

    function getTeamStake(
        uint256 _contestId
    ) public view returns (uint256, uint256) {
        // not needed
        // if (!isValidContest(_contestId)) {
        //     revert Predictor__inValidContest();
        // }
        ContestDetails storage contest = contestEntrances[_contestId];
        return (contest.totalAmount_A, contest.totalAmount_B);
    }
}
