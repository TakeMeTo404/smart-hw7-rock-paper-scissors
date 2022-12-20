// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface RPS {
    function create(uint256 toBet, address payable player1, address payable player2)
    external
    returns(uint256 gameId);
}

contract Caller{
    RPS rpsAddress;

    constructor(address _rpsAddress){
        rpsAddress = RPS(_rpsAddress);
    }

    function createGameWithMyself(uint256 toBet) public returns(uint256 gameId) {
        return rpsAddress.create(toBet, payable(msg.sender), payable(msg.sender));
    }
}
