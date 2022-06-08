// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DateTimeLibrary.sol";

import "hardhat/console.sol";

contract MoonFomoV3 is Ownable {
    using SafeMath for uint256;
    IERC20 MoondayToken;
    uint256 public roundCount;
    uint256 public dollarIncrement = 200000;
    uint256 public initialPrice = 256200000000000;
    uint256 public maxlatestholders = 6;
    uint256 public hoursForRound = 10;
    uint256 public secondsIncrement = 1000;
    address payable public _owner;

    struct RoundData{
      uint256 timer;
      uint256 ticketCount;
      uint256 jackpot;
      uint256 holderPool;
      mapping(address => uint256) ticketsOwned;
      mapping(address => uint256) claimList;
      mapping(address => uint256) reclaimed;
      mapping(uint256 => address) ticketOwners;
      bool ended;
      address payable maxticketsholder;
      address[] latestholders;
    }

    mapping(uint256 => RoundData) public rounds;
    mapping(uint256 => uint256) public jackpotClaimed;

    event RoundStarted(uint256 round, uint256 endingTime);
    event RoundAddedTokens(uint256 round, uint256 newJackpot);
    event TicketBought(address buyer, uint256 ticketNumber, uint256 ticketPrice);
    event RoundEnded(uint256 round, uint256 jackpot, uint256 tickets);
    event TicketClaimed(uint256 round, address buyer, uint256 claimAmount);
    event DividendClaimed(uint256 round, address claimant, uint256 dividendAmount);

    constructor(
      address payable owner_, 
      address payable _moondayTokenAddress
      ) {
      _owner = owner_;

      MoondayToken = IERC20(_moondayTokenAddress);
    }

    /// Starts a round and adds transaction to jackpot
    /// @dev increments round count, initiates timer and loads jackpot
    function initRound(uint _amount) external payable onlyOwner {
      require(roundCount == 0 || rounds[roundCount].ended, "Previous Round Not Ended!");

      roundCount++;
      MoondayToken.transferFrom(msg.sender, address(this), _amount);
      rounds[roundCount].jackpot += _amount;
      rounds[roundCount].timer = DateTimeLibrary.addHours(block.timestamp, hoursForRound);

      emit RoundStarted(roundCount, rounds[roundCount].timer);
    }

    /// Add tokens to jackpot
    /// @dev no increments round count, no initiates timer and only increase the tokens
    function addTokensToRound(uint _amount) external payable onlyOwner {
      require(!rounds[roundCount].ended, "Round already ended!");
      require(_amount > 0, "Invalid amount");

      MoondayToken.transferFrom(msg.sender, address(this), _amount);
      rounds[roundCount].jackpot += _amount;

      emit RoundAddedTokens(roundCount, rounds[roundCount].jackpot);
    }

    /// Starts a round and adds transaction to jackpot
    /// @dev increments round count, initiates timer and loads jackpot
    function setPricing(uint256 _initialPrice, uint256 _dollarIncrement) external onlyOwner {
      require(rounds[roundCount].timer < block.timestamp, "Previous Round Not Ended!");

      initialPrice = _initialPrice;
      dollarIncrement = _dollarIncrement;
    }

    /// Calculate owner of ticket
    /// @dev calculates ticket owner
    /// @param _round the round to query
    /// @param _ticketIndex the ticket to query
    /// @return owner of ticket
    function getTicketOwner(uint256 _round, uint256 _ticketIndex) public view returns(address) {
      return rounds[_round].ticketOwners[_ticketIndex];
    }

    /// Calculate tickets owned by user
    /// @dev calculates tickets owned by user
    /// @param _round the round to query
    /// @param _user the user to query
    /// @return total tickets owned by user
    function getTicketsOwned(uint256 _round, address _user) public view returns(uint256) {
      return rounds[_round].ticketsOwned[_user];
    }

    /// Get ticket reimbursment amount by user
    /// @dev calculates returnable ticket cost to user
    /// @param _round the round to query
    /// @param _user the user to query
    /// @return ticket reimbursment amount for user
    function getClaimList(uint256 _round, address _user) public view returns(uint256) {
      return rounds[_round].claimList[_user];
    }

    /// Get dividends claimed user
    /// @dev calculates returnable ticket cost to user
    /// @param _round the round to query
    /// @param _user the user to query
    /// @return dividend claimed by user
    function getReclaim(uint256 _round, address _user) public view returns(uint256) {
      return rounds[_round].reclaimed[_user];
    }

    /// Calculate ticket cost
    /// @dev calculates ticket price based on current holder pool
    /// @return current cost of ticket
    function calcTicketCost(uint256 _amount) public view returns(uint256) {
      uint additionalPool = 0;
      uint256 sumCost = 0;
      uint256 holderPool = rounds[roundCount].holderPool;
      for(uint256 x = 0; x < _amount; x++){
        sumCost += initialPrice + holderPool.add(additionalPool).div(dollarIncrement);
        additionalPool = sumCost.div(10);        
      }
      return sumCost;
    }

    /// Buy a ticket
    /// @dev purchases a ticket and distributes funds
    /// @return ticket index
    function buyTicket(uint256 _amount) external payable returns(uint256){
      // require(rounds[roundCount].timer > block.timestamp, "Round Ended!");
      require(!rounds[roundCount].ended, "Round already ended!");
      require(_amount > 0, "Invalid amount");

      uint256 ticketPrice = calcTicketCost(_amount);
      MoondayToken.transferFrom(msg.sender, address(this), ticketPrice);

      rounds[roundCount].jackpot += ticketPrice.mul(20).div(100);
      rounds[roundCount].holderPool += ticketPrice.mul(10).div(100);
      rounds[roundCount].claimList[msg.sender] += ticketPrice.sub(ticketPrice.div(5)).sub(ticketPrice.div(10));
      rounds[roundCount].ticketsOwned[msg.sender] += _amount;

      for(uint256 x = 0; x < _amount; x++){
        rounds[roundCount].ticketOwners[rounds[roundCount].ticketCount] = msg.sender;
        rounds[roundCount].ticketCount++;
      }

      if (rounds[roundCount].maxticketsholder == address(0) || 
        rounds[roundCount].ticketsOwned[msg.sender] > rounds[roundCount].ticketsOwned[rounds[roundCount].maxticketsholder]) {
        rounds[roundCount].maxticketsholder = payable(msg.sender);
      }

      if (rounds[roundCount].latestholders.length >= maxlatestholders) {
        for (uint256 i = 0; i < rounds[roundCount].latestholders.length - 1; i++) {
            rounds[roundCount].latestholders[i] = rounds[roundCount].latestholders[i + 1];
        }
        rounds[roundCount].latestholders.pop();
      }
      rounds[roundCount].latestholders.push(msg.sender);

      rounds[roundCount].timer += secondsIncrement;

      emit TicketBought(msg.sender, rounds[roundCount].ticketCount, ticketPrice);
      return rounds[roundCount].ticketCount;
    }


    /// Set the increment seconds
    /// @dev can change the additional seconds for each ticket purchase
    function setIncrementSeconds(uint256 _seconds) external onlyOwner {
      secondsIncrement = _seconds * 1000;
    }

    /// Set the round period hours
    /// @dev can change the round period hours for each rounds
    function setHoursForRound(uint256 _hours) external onlyOwner {
      hoursForRound = _hours;
    }

    /// End the current round
    /// @dev concludes round and pays owner
    function endRound() external onlyOwner {
      require(!rounds[roundCount].ended, "Round already ended!");

      uint256 claimMaxTicketHolder = rounds[roundCount].jackpot.mul(40).div(100);
      uint256 claimLatestTicketHolders = rounds[roundCount].jackpot.sub(claimMaxTicketHolder);
      MoondayToken.transfer(rounds[roundCount].maxticketsholder, claimMaxTicketHolder);

      uint256 _index = 0;
      address[] memory latestholders = new address[](maxlatestholders);
      for (uint256 i = 0; i < rounds[roundCount].latestholders.length; i++) {
          if (rounds[roundCount].latestholders[i] != rounds[roundCount].maxticketsholder) {
            latestholders[_index] = rounds[roundCount].latestholders[i];
            _index++;
            if (_index >= maxlatestholders) break;
          }
      }

      for (uint256 i = 0; i < _index; i++) {
        MoondayToken.transfer(payable(latestholders[i]), claimLatestTicketHolders.div(_index));
      }

      rounds[roundCount].ended = true;
      emit RoundEnded(roundCount, rounds[roundCount].jackpot, rounds[roundCount].ticketCount);
    }

    /// Calculate total dividends for a round
    /// @param _round the round to query
    /// @param _ticketHolder the user to query
    /// @dev calculates dividends minus reinvested funds
    /// @return totalDividends total dividends
    function calcDividends(uint256 _round, address _ticketHolder) public view returns(uint256 totalDividends) {
      if(rounds[_round].ticketCount == 0){
        return 0;
      }
      totalDividends = rounds[_round].ticketsOwned[_ticketHolder].mul(rounds[_round].holderPool).div(rounds[_round].ticketCount);
      totalDividends = totalDividends.sub(rounds[_round].reclaimed[_ticketHolder]);
      return totalDividends;
    }

    /// Calculate total payout for a round
    /// @param _round the round to claim
    /// @param _ticketHolder the user to query
    /// @dev calculates jackpot earnings, dividends and ticket reimbursment
    /// @return totalClaim total claim
    function calcPayout(uint256 _round, address _ticketHolder) public view returns(uint256 totalClaim) {
      if(rounds[_round].claimList[_ticketHolder] == 0){
        return 0;
      }
      totalClaim = calcDividends(_round, _ticketHolder);
      totalClaim += rounds[_round].claimList[_ticketHolder];
      return totalClaim;
    }

    /// Claim total dividends and winnings earned for a round
    /// @param _round the round to claim
    /// @dev calculates payout and pays user
    function claimPayout(uint256 _round) external {
      require(rounds[_round].timer < block.timestamp, "Round Not Ended!");
      require(rounds[_round].claimList[msg.sender] > 0, "You Have Already Claimed!");

      (uint256 payout) = calcPayout(_round, msg.sender);

      MoondayToken.transfer(msg.sender, payout);

      rounds[_round].claimList[msg.sender] = 0;

      emit TicketClaimed(_round, msg.sender, payout);
    }

    /// Claim total dividends in the current round
    /// @param _amount the amount to claim
    /// @dev calculates payout and pays user
    function claimDividends(uint256 _amount) external{
      require(calcDividends(roundCount, msg.sender) >= _amount, "Insufficient Dividends Available!");

      rounds[roundCount].reclaimed[msg.sender] += _amount;
      MoondayToken.transfer(msg.sender, _amount);

      emit DividendClaimed(roundCount, msg.sender, _amount);
    }

    /// Buy a ticket with dividends
    /// @dev purchases a ticket with dividends and distributes funds
    /// @return ticket index
    function reinvestDividends(uint256 _amount) external returns(uint256){
      require(calcDividends(roundCount, msg.sender) >= calcTicketCost(_amount), "Insufficient Dividends Available!");
      require(rounds[roundCount].timer > block.timestamp, "Round Ended!");

      emit TicketBought(msg.sender, rounds[roundCount].ticketCount, _amount);
      return(rounds[roundCount].ticketCount);
    }
}
