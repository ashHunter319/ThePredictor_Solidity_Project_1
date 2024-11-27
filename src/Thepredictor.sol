//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

import {ScoreBoard} from "./ScoreBoard.sol";
import {Address} from "./../openzeppelin-contracts/contracts/utils/Address.sol";


contract ThePredictor{
    using Address for address payable;

    uint256 private constant START_TIME = 1723752000;

    enum Status{
        Unkmowm,
        Pending,
        Approved,
        Canceled
    }

    mapping(address player => Status) public playerStatus;

    address public organizer;
    uint256 public entranceFees;
    address[] public players;
    ScoreBoard public scoreBoard;
    uint256 public predectionFee;


    error invalid_entranceFees();
    error TimeLine_over();
    error noDouble_register();
    error ThePredicter__NotEligibleForWithdraw();
    error Unauthorized_organizer();
    error Limit_exceed();
    error predection_closed();
    error invalid_predectionFees();
    error notEligible();

    constructor( address _scoreBoard, uint256 _entranceFees, uint256 _predectionFee){
        organizer = msg.sender;
        entranceFees = _entranceFees;
        predectionFee = _predectionFee;
        scoreBoard = ScoreBoard(_scoreBoard);
    }
    
        
    function register() external payable  {
        if(msg.value == entranceFees){
            revert invalid_entranceFees();
        }
        
        if(block.timestamp > START_TIME - 14400 ) {
            revert TimeLine_over();
        }

        if(playerStatus[msg.sender] != Status.Pending){
            revert noDouble_register();
    }

    playerStatus[msg.sender]=Status.Pending;
    }
   
   function cancelRegistraion() public {
    if (playerStatus[msg.sender] == Status.Pending){
        (bool success,)=msg.sender.call{value:entranceFees}("");
        require(success, "Failed to Withdraw");
        playerStatus[msg.sender] = Status.Canceled;
        return;

    }

    revert ThePredicter__NotEligibleForWithdraw();
   }

   function approvePlayer (address player) public {
    if(msg.sender != organizer){
        revert Unauthorized_organizer();
    }
    if(players.length >= 30){
        revert Limit_exceed();
    }

    if(playerStatus[player] == Status.Pending) {
        
        playerStatus[player] = Status.Approved;
        players.push(player);
    }


   }

   function makePredection(uint256 matchNumber, ScoreBoard.Result predection ) public payable {

    if(msg.value != predectionFee){
        revert invalid_predectionFees();
    }

    if(block.timestamp >= START_TIME + matchNumber * 68400 - 68400){
        revert predection_closed();
    }

    scoreBoard.confirmPredictionPayment(msg.sender, matchNumber );
    scoreBoard.setPrediction(msg.sender, matchNumber, predection);

   }

   function withdrawPredictionFees() public {
    if(msg.sender != organizer){
        revert Unauthorized_organizer();
    }
     uint256 fees = address(this).balance - players.length * entranceFees;
     (bool success, ) = msg.sender.call{value:fees}("");
     require(success,"Failed To Withdraw");


   }

   function withdraw() public{
    if(!scoreBoard.isEligibleForReward(msg.sender)){
    revert notEligible();
   }

   int8 score = scoreBoard.getPlayerScore(msg.sender);

   int8 max_score = -1;
   int256 totalPositiveScore = 0;

   for (uint256 i = 0; i < players.length; i++){

     int8 cscore = scoreBoard.getPlayerScore(players[i]);
     if(max_score > cscore) max_score = cscore;
     if(cscore > 0) totalPositiveScore = totalPositiveScore + cscore; 
  }

  if( max_score > 0 && score <= 0){
    revert ThePredicter__NotEligibleForWithdraw();
  }

  uint256 shares = uint8(score);
  uint256 totalShares = uint256(totalPositiveScore);
  uint256 rewards = 0;

  rewards = max_score < 0 ? entranceFees : (shares * players.length * entranceFees) / totalShares ;

  if(rewards > 0) {
   scoreBoard.clearPredictionsCount(msg.sender);
   (bool success,) = msg.sender.call{value:rewards}("");
   require(success,"Failed To Withdraw");
    }
  }

}