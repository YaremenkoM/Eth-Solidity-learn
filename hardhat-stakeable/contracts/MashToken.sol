// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Stakeable.sol";

contract MashToken is ERC20, Ownable, Stakeable {
    constructor(uint256 initialSupply) ERC20("MashToken", "MASH") {
        _mint(msg.sender, initialSupply);
    }


    function stake(uint256 _amount) external{
      require(_amount < balanceOf(msg.sender), "Cannot stake more than you own");
      require(_amount > 0, "Need to stake smth, cant stake nothing"); //this require was in stakeable contract (is it ok to put it here?)

      _stake(_amount);
      _burn(msg.sender, _amount);
    }

    function withdrawStake(uint256 amount, uint256 stake_index) external {
      uint256 amount_to_mint = _withdrawStake(amount, stake_index);
      _mint(msg.sender, amount_to_mint);
    }

    function claim(uint256 index) external {
      _claim(index);
    }

    function withdraw(uint amount, uint index) external{
      uint256 amount_to_mint = _withdraw(amount, index);
      _mint(msg.sender, amount_to_mint);
    }
}