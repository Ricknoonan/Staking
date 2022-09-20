// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    mapping(address => uint256) public balances;
    address[] private s_funders;
    uint256 public s_initialTimeStamp;
    uint256 public constant s_threshold = 0.003 ether;
    uint256 public constant s_deadline = 72 hours;
    bool public s_thresholdReached = false;
    bool public s_endState = false;

    event Stake(address, uint256);
    event Received(address, uint256);

    error Staker_TimeNotUp(uint256);
    error Staker_BalanceTooLow();
    error Stake_ThresholdReached();
    error Staker_TimesUp();
    error Staker_EndStateReached();

    ExampleExternalContract public exampleExternalContract;

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
        s_initialTimeStamp = block.timestamp;
    }

    receive() external payable {
        stake();
        emit Received(msg.sender, msg.value);
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

    function stake() public payable checkTimesUp checkEndState {
        balances[msg.sender] += msg.value;
        s_funders.push(msg.sender);
        if (address(this).balance >= s_threshold) {
            s_thresholdReached = true;
        }
        emit Stake(msg.sender, msg.value);
    }

    function execute() public payable checkTimeLeft checkEndState {
        if (s_thresholdReached) {
            for (
                uint256 funderIndex = 0;
                funderIndex < s_funders.length;
                funderIndex++
            ) {
                address funder = s_funders[funderIndex];
                balances[funder] = 0;
            }
            s_funders = new address[](0);
            exampleExternalContract.complete{value: address(this).balance}();
            s_endState = true;
        }
    }

    function withdraw() public payable checkTimeLeft checkEndState {
        if (s_thresholdReached) {
            revert Stake_ThresholdReached();
        }
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            uint256 amount;
            if (funder == msg.sender) {
                amount = balances[funder];
                delete balances[funder];
                (bool success, ) = funder.call{value: amount}("");
                require(success, "Withdraw Failed");
            }
        }
        s_endState = true;
    }

    function timeLeft() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - s_initialTimeStamp;
        if (timeElapsed < s_deadline) {
            return s_deadline - timeElapsed;
        }
        return 0;
    }

    modifier checkTimeLeft() {
        uint256 timeRemaing = timeLeft();
        if (timeRemaing > 0) {
            revert Staker_TimeNotUp(timeRemaing);
        }
        _;
    }

    modifier checkTimesUp() {
        uint256 timeRemaing = timeLeft();
        if (timeRemaing == 0) {
            revert Staker_TimesUp();
        }
        _;
    }

    modifier checkEndState() {
        if (s_endState) {
            revert Staker_EndStateReached();
        }
        _;
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

    // Add the `receive()` special function that receives eth and calls stake()
}
