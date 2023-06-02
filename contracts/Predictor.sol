// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// todos--
// enter the match(by paying min amount),
// get the current matches from chianlink functions,
//automate the excutions using chainlink keepers,
// provide a option to transfer the amount to their accounts.

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

// Errors
error Predictor__notEnoughFeeEntered(uint256 entryFee);
error Predictor__notAnOwner();
error Raffle__UpkeepNotNeeded();
error Predictor__inValidContest();
error Predictor__notEnoughBalance();

contract gamePredictor is AutomationCompatibleInterface {
    /* state Variables */

    enum result {
        won_by_teamA,
        won_by_teamB,
        Draw_or_noResult
    }

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

    enum matchStatus {
        Yet_to_Start,
        in_Progress,
        Finished
    }

    struct Game {
        uint256 matchId;
        string teamA;
        string teamB;
        bool isValidContest;
        matchStatus status;
        // string result;
    }

    mapping(uint256 => ContestDetails) private contestEntrances;
    // mapping(uint256 => Game) contests;
    Game[] private ContestsId;
    uint256 private immutable i_entryFee;
    mapping(address => uint256) private Winnings;

    // address payable[] private s_Players;
    uint256 public totalEntries;
    address public owner;

    // chainlink automation varaiables

    uint256 private immutable interval;
    uint256 private lastTimeStamp;

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

    // event ContestEntry(
    //     address indexed contestant,
    //     uint256 contestId,
    //     string teamPicked
    // );

    // event ContestResult(
    //     string contestName,
    //     string winningTeam,
    //     uint256 totalPayout
    // );

    constructor(uint256 entranceFee, uint256 updateInterval) {
        i_entryFee = entranceFee;

        // had faced issues while fetchings api from chainlink functions which is in closed beta.
        // untill, hardcoded the contests and events.
        ContestsId.push(
            Game(11223, "india", "australia", true, matchStatus.Yet_to_Start)
        );
        emit Ongoing_Contests(
            11223,
            "india",
            "australia",
            matchStatus.Yet_to_Start
        );

        ContestsId.push(
            Game(12124, "india", "england", true, matchStatus.Yet_to_Start)
        );

        emit Ongoing_Contests(
            12124,
            "india",
            "england",
            matchStatus.Yet_to_Start
        );

        ContestsId.push(
            Game(12546, "england", "australia", true, matchStatus.Yet_to_Start)
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

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Predictor__notAnOwner();
        }
        _;
    }

    function randomNum(uint256 range) internal view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(block.difficulty, block.timestamp))
            ) % range;
    }

    function createContest() private {
        uint256 randNum = randomNum(100000);
        ContestsId.push(
            Game(randNum, "TeamA", "TeamB", true, matchStatus.Yet_to_Start)
        );

        emit Ongoing_Contests(
            randNum,
            "TeamA",
            "TeamB",
            matchStatus.Yet_to_Start
        );
    }

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

    function performUpkeep(bytes calldata /* performData */) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded();
        }
        // require(upkeepNeeded, "Time interval not met");

        //not needed for a moment
        // for (uint i = 0; i < ContestsId.length; i++) {
        //     if (ContestsId[i].status == matchStatus.Finished) {
        //         ContestsId[i] = ContestsId[ContestsId.length - 1];
        //         ContestsId.pop();
        //     }
        // }

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

    // function MatchProgress(string memory _contestName) public onlyOwner {
    //     require(isValidContest(_contestName), "Invalid contest name.");
    //     MatchDetails storage contest = ContestEntry[msg.sender][_contestName];

    //     // contest.result = matchResult;

    //     emit matchProgress(_contestName, _winningTeam, address(this).balance);
    // }

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

    function fetchBalance() public onlyOwner {
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
    }

    function withDrawBalance() public {
        uint256 balance = Winnings[msg.sender];
        if (balance <= 0) {
            revert Predictor__notEnoughBalance();
        }

        Winnings[msg.sender] = 0;

        payable(msg.sender).transfer(Winnings[msg.sender]);
        // with transfer if transaction fails, it is automatically reverted.
        //incase of send or call(returns bool), we have to call require expictly.
    }

    //getters

    function getEntranceFee() public view returns (uint256) {
        return i_entryFee;
    }

    function getBalance() public view returns (uint256) {
        return Winnings[msg.sender];
    }

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
    //     string memory _contestName
    // ) public view returns (uint256, uint256) {
    //     ContestDetails storage contest = contestEntrances[_contestName];
    //     return (contest.totalAmount_A, contest.totalAmount_B);
    // }

    // function getPlayerStake(
    //     string memory _contestName,
    //     address _player
    // ) public view returns (uint256, uint256) {
    //     ContestDetails storage contest = contestEntrances[_contestName];
    //     PlayerStake storage playerStake = contest.playerStakes[_player];
    //     return (playerStake.teamA, playerStake.teamB);
    // }
}
