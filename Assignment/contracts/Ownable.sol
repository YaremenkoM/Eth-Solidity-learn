// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed prevOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: only owner can call this function");
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns(address) {
        return _owner;
    }

    //renounce - to give up, refuse
    function renounceOwnership() public onlyOwner{
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address toOwner) public onlyOwner {
        _transferOwnership(toOwner);
    }

    function _transferOwnership(address toOwner) internal {
        require(toOwner != address(0), "Can't transfer ownership to zero address");
        emit OwnershipTransferred(_owner, toOwner);
        _owner = toOwner;
    }

}