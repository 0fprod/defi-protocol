// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/interfaces/AggregatorV3Interface.sol";

library OracleLib {
    error OracleLib__UnsafePrice();

    uint256 private constant TIMEOUT = 5 minutes;

    function safePrice(AggregatorV3Interface _priceFeed)
        internal
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        (uint80 roundId, int256 price, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            _priceFeed.latestRoundData();

        if (updatedAt == 0 || answeredInRound < roundId) {
            revert OracleLib__UnsafePrice();
        }
        
        uint256 secondsSince = block.timestamp - updatedAt;
        if (secondsSince > TIMEOUT) revert OracleLib__UnsafePrice();

        return (roundId, price, startedAt, updatedAt, answeredInRound);
    }

    function getTimeouts() internal pure returns (uint256) {
        return TIMEOUT;
    }
}
