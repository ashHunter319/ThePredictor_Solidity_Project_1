//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

contract ScoreBoard{
        
        uint256 constant START_TIME = 1723752000;
        uint256 private constant NUM_MATCHES = 9;

    enum Result{
        Pending,
        First,
        Draw,
        Second
    }

    struct PlayerPrediction{
        Result[NUM_MATCHES] predections;
        bool[NUM_MATCHES] isPaid;
        uint8 predectionsCount;
    }

    error ScoreBoard_UnauthorizedAccess();

    address owner;
    address thePredictor;
    mapping (address player => PlayerPrediction) playerPredictions;

    modifier onlyOwner() {
        if(msg.sender != owner){
            revert ScoreBoard_UnauthorizedAccess();
        }
        _;
    }

    modifier onlyThePredictor(){
    if ( msg.sender != thePredictor){
        revert ScoreBoard_UnauthorizedAccess();
    }
        _;
    }

    constructor (){
        owner = msg.sender;
    }

    Result[NUM_MATCHES] private results;

    function setPredictor(address _thePredictor) public onlyOwner{
        thePredictor = _thePredictor;
    }

     function setResult(uint256 MatchNumber, Result result) public onlyOwner{
     results[MatchNumber] = result;
     }

     function confirmPredictionPayment(address player, uint256 matchNumber) public view onlyThePredictor{

       playerPredictions[player].isPaid[matchNumber] == true;

     }

     function setPrediction(address player, uint256 MatchNumber, Result result) public {

       if(block.timestamp <= START_TIME * 64800 - 64800)

       playerPredictions[player].predections[MatchNumber]=result;
       playerPredictions[player].predectionsCount=0;
       for(uint256 i=0; i < NUM_MATCHES; i++)
       {
       if(
        playerPredictions[player].predections[i] != Result.Pending && playerPredictions[player].isPaid[i]
        )
       ++playerPredictions[player].predectionsCount;       
       }

       }

       function clearPredictionsCount(address player ) public onlyThePredictor{
       
             playerPredictions[player].predectionsCount = 0;
        
       }

       function getPlayerScore(address player) public view returns(int8 score){

        for(uint256 i=0; i < NUM_MATCHES; i++){
            if(playerPredictions[player].isPaid[i] && playerPredictions[player].predections[i] != Result.Pending)
            score += playerPredictions[player].predections[i] == results[i] ? int8(2) : -1;
            }
        }

        function isEligibleForReward(address player) public view returns(bool){

            return results[NUM_MATCHES -1] != Result.Pending && playerPredictions[player].predectionsCount > 1;
        
        }
     }

    