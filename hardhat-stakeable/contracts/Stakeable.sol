// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Stakeable{
    constructor() {
        stakeholders.push();
    }

    struct Stakeholder{
      address user;
      Stake[] address_stakes; //Why "address_stakes" name?
    }

    struct Stake {
      address user; //Why we need address of user here, when we have it on stakeholder struct?
      uint amount;
      uint since;
      uint256 claimable;
      uint256 toWithdraw;
    }

    struct StakingSummary{
         uint256 total_amount;
         Stake[] stakes;
     }

    
    
    Stakeholder[] internal stakeholders;

    mapping(address => uint256) internal stakes;

    event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);



    function _addSteakholder(address staker) internal returns (uint256) {
        require(staker > address(0), "Cannot stake from zero address");

        stakeholders.push();
        uint256 userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker] = userIndex;
        return userIndex; 
    }

    function _stake(uint256 _amount) internal {

        uint256 index = stakes[msg.sender];
        uint256 timestamp = block.timestamp;

        if(index == 0){
            index = _addSteakholder(msg.sender);
        }

        stakeholders[index].address_stakes.push(Stake({
            user: msg.sender, 
            amount: _amount, 
            since: timestamp,
            claimable: 0,
            toWithdraw: 0
            })
        );

        emit Staked(msg.sender, _amount, index, timestamp);
    }

    function _claim(uint256 index) internal {
        uint256 user_index = stakes[msg.sender];

        Stake memory current_stake = stakeholders[user_index].address_stakes[index];

        require(index < stakeholders[user_index].address_stakes.length, "Non-existent stake");

         uint256 reward = calculateReward(current_stake);

         if(current_stake.amount != 0){
            stakeholders[user_index].address_stakes[index].toWithdraw = reward;
            stakeholders[user_index].address_stakes[index].since = block.timestamp; 
         }
    }

    function _withdraw(uint amount, uint index) internal returns(uint256){
        uint256 user_index = stakes[msg.sender];

        Stake memory current_stake = stakeholders[user_index].address_stakes[index];

        require(current_stake.toWithdraw >= amount, "Staking: Cannot withdraw more that was claimed");

        bool canWithdraw = block.timestamp - current_stake.since > 1 days;
        if (canWithdraw) {
            stakeholders[user_index].address_stakes[index].toWithdraw -= amount;
            return amount;
        } else {
            return 0;
        }
        
    }

    

    function _withdrawStake(uint256 amount, uint256 index) internal returns(uint256){
        uint256 user_index = stakes[msg.sender];

        Stake memory current_stake = stakeholders[user_index].address_stakes[index];

        require(current_stake.amount >= amount, "Staking: Cannot withdraw more than you have staked");

         uint256 reward = calculateReward(current_stake);
         current_stake.amount = current_stake.amount - amount;
         if(current_stake.amount == 0){
             delete stakeholders[user_index].address_stakes[index];
         }else {
            stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
            stakeholders[user_index].address_stakes[index].since = block.timestamp;    
         }

         return amount+reward;

     }


    function calculateReward(Stake memory _current_stake) internal view returns(uint256){

        uint256 APY;
        uint256 amount = _current_stake.amount;
        if (amount < 100) {
            APY = 15;
        } else if (amount >= 100 && amount <= 1000) {
            APY = 16;
        } else if (amount >= 1000 && amount <= 1500) {
            APY = 17;
        } else {
            APY = 18;
        }
        
        uint256 diff = (block.timestamp - _current_stake.since) / 1 hours;
        uint256 hoursInYear = 8760;

        uint x = 100 * hoursInYear;
        return (diff  * amount * APY) / x;
    }

    function hasStake(address _staker) public view returns(StakingSummary memory){
        uint256 totalStakeAmount; 

        StakingSummary memory summary = StakingSummary({
            total_amount: 0, 
            stakes: stakeholders[stakes[_staker]].address_stakes
        });

        for (uint256 s = 0; s < summary.stakes.length; s += 1){
           uint256 availableReward = calculateReward(summary.stakes[s]);
           summary.stakes[s].claimable = availableReward;
           totalStakeAmount = totalStakeAmount + summary.stakes[s].amount;
       }

       summary.total_amount = totalStakeAmount;
        return summary;
    }

}
