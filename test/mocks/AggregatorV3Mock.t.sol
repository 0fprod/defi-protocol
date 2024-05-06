// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/interfaces/AggregatorV3Interface.sol";

contract AggregatorV3Mock is AggregatorV3Interface {
    struct Round {
        uint80 id;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    uint8 private immutable i_decimals;
    string private i_description;
    uint256 private constant i_version = 1;
    uint256 latestRoundId;

    mapping(uint256 index => Round round) rounds;

    constructor(uint8 _decimals, string memory _description, int256 initialPrice) {
        i_decimals = _decimals;
        i_description = _description;
        _updateRoundData(initialPrice);
    }

    function updateRoundData(int256 _answer) external {
        _updateRoundData(_answer);
    }

    function _updateRoundData(int256 _answer) internal {
        latestRoundId++;
        uint256 decimalsMultiplier = 10 ** uint256(i_decimals);
        _answer = _answer * int256(decimalsMultiplier);
        rounds[latestRoundId] = Round({
            id: uint80(latestRoundId),
            answer: _answer,
            startedAt: block.timestamp,
            updatedAt: block.timestamp,
            answeredInRound: uint80(latestRoundId)
        });
    }

    function decimals() external view override returns (uint8) {
        return i_decimals;
    }

    function description() external view override returns (string memory) {
        return i_description;
    }

    function version() external pure override returns (uint256) {
        return i_version;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        Round memory round = rounds[_roundId];
        return (round.id, round.answer, round.startedAt, round.updatedAt, round.answeredInRound);
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        Round memory round = rounds[latestRoundId];
        return (round.id, round.answer, round.startedAt, round.updatedAt, round.answeredInRound);
    }

    function latestAnswer() external view returns (int256) {
        return rounds[latestRoundId].answer;
    }
}
