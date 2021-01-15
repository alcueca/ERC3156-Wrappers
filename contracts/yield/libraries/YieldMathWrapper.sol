// SPDX-License-Identifier: GPL-3.0-or-later
// Taken from https://github.com/yieldprotocol/fyDai
pragma solidity ^0.7.5;
import "./YieldMath.sol";


/**
 * Wrapper for Yield Math Smart Contract Library, with return values for reverts.
 */
contract YieldMathWrapper {
  /**
   * Calculate the amount of fyDai a user would get for given amount of DAI.
   *
   * @param daiReserves DAI reserves amount
   * @param fyDaiReserves fyDai reserves amount
   * @param daiAmount DAI amount to be traded
   * @param timeTillMaturity time till maturity in seconds
   * @param k time till maturity coefficient, multiplied by 2^64
   * @param g fee coefficient, multiplied by 2^64
   * @return the amount of fyDai a user would get for given amount of DAI
   */
  function fyDaiOutForDaiIn (
    uint128 daiReserves, uint128 fyDaiReserves, uint128 daiAmount,
    uint128 timeTillMaturity, int128 k, int128 g)
  public pure returns (bool, uint128) {
    return (
      true,
      YieldMath.fyDaiOutForDaiIn (
        daiReserves, fyDaiReserves, daiAmount, timeTillMaturity, k, g));
  }

  /**
   * Calculate the amount of DAI a user would get for certain amount of fyDai.
   *
   * @param daiReserves DAI reserves amount
   * @param fyDaiReserves fyDai reserves amount
   * @param fyDaiAmount fyDai amount to be traded
   * @param timeTillMaturity time till maturity in seconds
   * @param k time till maturity coefficient, multiplied by 2^64
   * @param g fee coefficient, multiplied by 2^64
   * @return the amount of DAI a user would get for given amount of fyDai
   */
  function daiOutForFYDaiIn (
    uint128 daiReserves, uint128 fyDaiReserves, uint128 fyDaiAmount,
    uint128 timeTillMaturity, int128 k, int128 g)
  public pure returns (bool, uint128) {
    return (
      true,
      YieldMath.daiOutForFYDaiIn (
        daiReserves, fyDaiReserves, fyDaiAmount, timeTillMaturity, k, g));
  }

  /**
   * Calculate the amount of fyDai a user could sell for given amount of DAI.
   *
   * @param daiReserves DAI reserves amount
   * @param fyDaiReserves fyDai reserves amount
   * @param daiAmount DAI amount to be traded
   * @param timeTillMaturity time till maturity in seconds
   * @param k time till maturity coefficient, multiplied by 2^64
   * @param g fee coefficient, multiplied by 2^64
   * @return the amount of fyDai a user could sell for given amount of DAI
   */
  function fyDaiInForDaiOut (
    uint128 daiReserves, uint128 fyDaiReserves, uint128 daiAmount,
    uint128 timeTillMaturity, int128 k, int128 g)
  public pure returns (bool, uint128) {
    return (
      true,
      YieldMath.fyDaiInForDaiOut (
        daiReserves, fyDaiReserves, daiAmount, timeTillMaturity, k, g));
  }

  /**
   * Calculate the amount of DAI a user would have to pay for certain amount of
   * fyDai.
   *
   * @param daiReserves DAI reserves amount
   * @param fyDaiReserves fyDai reserves amount
   * @param fyDaiAmount fyDai amount to be traded
   * @param timeTillMaturity time till maturity in seconds
   * @param k time till maturity coefficient, multiplied by 2^64
   * @param g fee coefficient, multiplied by 2^64
   * @return the amount of DAI a user would have to pay for given amount of
   *         fyDai
   */
  function daiInForFYDaiOut (
    uint128 daiReserves, uint128 fyDaiReserves, uint128 fyDaiAmount,
    uint128 timeTillMaturity, int128 k, int128 g)
  public pure returns (bool, uint128) {
    return (
      true,
      YieldMath.daiInForFYDaiOut (
        daiReserves, fyDaiReserves, fyDaiAmount, timeTillMaturity, k, g));
  }

}