// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Stakeable{
    constructor() {
        stakeholders.push();
    }

    struct Stakeholder{
      address user;
      uint256 toWithdraw;
      uint lastClaimed;
      Stake[] address_stakes; //Why "address_stakes" name?
    }

    struct Stake {
      address user; //Why we need address of user here, when we have it on stakeholder struct? UPD: WE NEED THAT TO INTERACT WITH THE EVENTS (SEE Staked event)
      uint amount;
      uint since;
      uint256 claimable;
    }

    struct StakingSummary{
         uint256 total_amount;
         Stake[] stakes;
    }

    Stakeholder[] internal stakeholders;

    mapping(address => uint256) internal stakes;

    event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);


    function _addStakeholder(address staker) internal returns (uint256) {
        require(staker != address(0), "Cannot stake from zero address");

        stakeholders.push();
        uint256 userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakeholders[userIndex].toWithdraw = 0;

        stakes[staker] = userIndex;
        return userIndex; 
    }

    function _stake(uint256 _amount) internal {

        uint256 index = stakes[msg.sender];
        uint256 timestamp = block.timestamp;

        if(index == 0){
            index = _addStakeholder(msg.sender);
        }

        stakeholders[index].address_stakes.push(Stake({
            user: msg.sender,
            amount: _amount, 
            since: timestamp,
            claimable: 0
            })
        );

        emit Staked(msg.sender, _amount, index, timestamp);
    }

    function _claim() internal {
        uint256 user_index = stakes[msg.sender];

        require(user_index != 0, "The user is not a stakeholder yet");

        Stake[] memory userStakes = stakeholders[user_index].address_stakes;

        uint256 toWithdrawSum = 0;
        uint256 newStakedSum = 0;
//        uint256 firstStakeToKeepIndex = userStakes.length;

        for(uint s = 0; s < userStakes.length; s++) {
            if (block.timestamp - userStakes[s].since > 1 days) {
                uint256 availableReward = calculateReward(userStakes[s]);
                toWithdrawSum += availableReward;
                newStakedSum += userStakes[s].amount;
            } else {
 //               firstStakeToKeepIndex = s;
                newStakedSum += userStakes[s].amount;
                //return;
            }
        }

//        stakeholders[user_index].address_stakes.length = 3;
//        stakeholders[user_index].address_stakes = stakeholders[user_index].address_stakes[firstStakeToKeepIndex:];
        delete stakeholders[user_index].address_stakes;
        stakeholders[user_index].address_stakes.push(Stake({
                user: msg.sender,
                amount: newStakedSum,
                since: block.timestamp,
                claimable: 0
            })
        );
        stakeholders[user_index].toWithdraw += toWithdrawSum;
        stakeholders[user_index].lastClaimed = block.timestamp;
    }

    function _withdraw() internal returns(uint256){
        uint256 user_index = stakes[msg.sender];
        uint256 toWithdraw = 0;

        require(user_index != 0, "The user is not a stakeholder yet");
        require(block.timestamp - stakeholders[user_index].lastClaimed > 1 days, "Can't withdraw if less than 1 day passed after last claim");
        require(stakeholders[user_index].toWithdraw != 0, "Nothing to withdraw");

        toWithdraw = stakeholders[user_index].toWithdraw;
        stakeholders[user_index].toWithdraw = 0;

        return toWithdraw;
    }

    function _claimAndWithdraw(uint amount) internal {
        _claim();
        require(amount > 0, "Can't withdraw nothing");

        uint256 user_index = stakes[msg.sender];
        require(user_index != 0, "The user is not a stakeholder yet");

        StakingSummary memory stakingSum = _stakingSummary();
        require((stakeholders[user_index].toWithdraw + stakingSum.total_amount) <= amount, "Can't withdraw more that you own");


        //Badly expensive. Maybe could be done in more efficient way

        if(amount < stakeholders[user_index].toWithdraw) {
            uint256 diffToStake = stakeholders[user_index].toWithdraw - amount;
            _stake(diffToStake);

        } else if (amount > stakeholders[user_index].toWithdraw) {

            uint diffToWithdraw = amount - stakeholders[user_index].toWithdraw;

            for (uint256 s = stakeholders[user_index].address_stakes.length-1; s >= stakeholders[user_index].address_stakes.length; s--){
                uint256 stakeAmount = stakeholders[user_index].address_stakes[s].amount;

                if (diffToWithdraw <= stakeAmount) {
                    if (stakeAmount - diffToWithdraw == 0) {
//                        stakeholders[user_index].address_stakes = stakeholders[user_index].address_stakes[:s];
                        stakeholders[user_index].address_stakes.pop();
                        return;
                    } else {
                        stakeholders[user_index].address_stakes[s].amount = stakeAmount - diffToWithdraw;
                        return;
                    }
                } else {
                    diffToWithdraw = diffToWithdraw - stakeAmount;
                    stakeholders[user_index].address_stakes.pop();
                }

            }

            stakeholders[user_index].toWithdraw = amount;
        }
    }


//    function _withdrawStake(uint256 amount, uint256 index) internal returns(uint256){
//        uint256 user_index = stakes[msg.sender];
//
//        Stake memory current_stake = stakeholders[user_index].address_stakes[index];
//
//        require(current_stake.amount >= amount, "Staking: Cannot withdraw more than you have staked");
//
//         uint256 reward = calculateReward(current_stake);
//         current_stake.amount = current_stake.amount - amount;
//         if(current_stake.amount == 0){
//             delete stakeholders[user_index].address_stakes[index];
//         }else {
//            stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
//            stakeholders[user_index].address_stakes[index].since = block.timestamp;
//         }
//
//         return amount+reward;
//     }


    function calculateReward(Stake memory _current_stake) internal view returns(uint256){

        uint256 APY = 15;
        uint256 amount = _current_stake.amount;
        
        uint256 diff = (block.timestamp - _current_stake.since) / 1 hours;
        uint256 hoursInYear = 8760;

        uint x = 100 * hoursInYear;
        return (diff  * amount * APY) / x;
    }

    function _stakingSummary() internal view returns(StakingSummary memory){
        uint256 totalStakeAmount;

        uint256 user_index = stakes[msg.sender];
        require(user_index != 0, "The user is not a stakeholder yet");

        StakingSummary memory summary = StakingSummary({
            total_amount: 0, 
            stakes: stakeholders[user_index].address_stakes
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
