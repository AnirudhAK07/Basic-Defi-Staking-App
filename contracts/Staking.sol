//stake:lock tokens into our smart contract



//withdraw:unlock tokens and pullout

//claimReward:users get their reward tokens

//whats a good reward mechanism

//whats a good reward math

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Staking__TransferFailed();
error Staking__NeedsMoreThanZer();

contract Staking {
    IERC20 public s_stakingToken;
    IERC20 public s_rewardToken;
    //someone address->how much they staked
    mapping(address=>uint256) public s_balances;
    //a mapping of how much each address has been paid
    mapping(address=>uint256) public s_userRewardPerTokenPaid;
    //a mapping of how much rewards each adress has
    mapping(address=>uint256) public s_rewards;

    uint256 public constant REWARD_RATE=100;
    uint256 public s_totalSupply;
    uint256 public s_rewardPerTokenStored;
    uint256 public s_lastUpdateTime;

    modifier updateReward(address account){
        //how much reward per token?
        //last timestamp
        //12-1,user earned x tokens
        s_rewardPerTokenStored=rewardPerToken();
        s_lastUpdateTime=block.timestamp; 
        s_rewards[account]=earned(account);
        s_userRewardPerTokenPaid[account]=s_rewardPerTokenStored;
        _;

    }

    modifier moreThanZero(uint256 amount){
        if (amount==0){
            revert Staking__NeedsMoreThanZer();
        }
        _;
    }

    constructor(address stakingToken,address rewardToken){
            s_stakingToken=IERC20(stakingToken);
            s_rewardToken=IERC20(rewardToken);
    }

    function earned(address account) public view returns(uint256){
        uint256 currentBalance=s_balances[account];
        //how much they have paid already
        uint256 amountPaid=s_userRewardPerTokenPaid[account];
        uint256 currentRewardPerToken=rewardPerToken();
        uint256 pastRewards =s_rewards[account];

        uint256 _earned=(currentBalance*(currentRewardPerToken-amountPaid))/1e18+pastRewards;
        return _earned;
    }

    //based on how long most recent snap
    function rewardPerToken() public view returns(uint256){
            if(s_totalSupply==0){
                return s_rewardPerTokenStored;

            }
            return s_rewardPerTokenStored+(((block.timestamp-s_lastUpdateTime)*REWARD_RATE*1e18)/s_totalSupply);
    }


    //do we allow any tokens-not allow any token
    //chainlink stuff to convert prices between tokens
    //or just a specific token-yes

    function stake(uint256 amount) external updateReward(msg.sender) moreThanZero(amount){
        //keep track how much this user staked
        //total
        //transfer tokens to contract
        s_balances[msg.sender]=s_balances[msg.sender]+amount;
        s_totalSupply=s_totalSupply+amount;
        bool success=s_stakingToken.transferFrom(msg.sender,address(this),amount);
        //require(success,"Failed");
        if(!success){
            revert Staking__TransferFailed();
        }
    }

    function withdraw(uint256 amount)external updateReward(msg.sender) moreThanZero(amount){
            s_balances[msg.sender]=s_balances[msg.sender]-amount;
            s_totalSupply=s_totalSupply-amount;
            bool success=s_stakingToken.transfer(msg.sender,amount);
            //bool success=s_stakingToken.transferFrom(address(this),msg.sender,amount);
            if(!success){
                revert Staking__TransferFailed();
            }
    }

    function claimReward() external updateReward(msg.sender){

        uint256 reward=s_rewards[msg.sender];
        bool success=s_rewardToken.transfer(msg.sender,reward);
        if(!success){
            revert Staking__TransferFailed();
        }
        //how much reward they get?
        //the contract is going to emit x tokens per second
        //and disperse them to all token stakers
        //
        //100t/s
        //staked: 50 staked tokens,20 staked tokens,30 staked tokens
        //rewards: 50 reward tokens,20 reward tokens,30 reward tokens
        //
        //staked:100,50,20,30(total=200)
        //rewards:50,25,10,15
        //
        //why not 1:1 bankrupt


        //5 s,1 person had 100 token staked =reward 500 tokens
        //6s ,2 person have 100 tokens staked each
        //person1:550
        //person2:50
        //ok between 1-5s,person 1 got 500 tokens
        //ok at 6s ,person1 get 50 tokens





    }
}