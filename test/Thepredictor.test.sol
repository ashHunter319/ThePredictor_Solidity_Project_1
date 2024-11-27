//SPDX-License-Idenntifier : MIT

pragma solidity ^0.8.13;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {ThePredictor} from "../src/Thepredictor.sol";
import {ScoreBoard} from "../src/ScoreBoard.sol";
import {Strings} from "../openzeppelin-contracts/contracts/utils/Strings.sol";

contract TestPredictor is Test{

    ThePredictor public predictor;
    ScoreBoard public scoreBoard;

    address public organizer = makeAddr("organizer");
    address public stranger = makeAddr("stranger");

    error AllSeatsAre_full();
    error Incoorect_entryFee();
    error DeadlineOver();
    error CannotRegistorTwice();
    error Cannot_withdraw();
    error ScoreBoard__UnauthorizedAccess();
    error ThePredictor_IncorrectPredectionfee();
    error Predection_timeIsOver();
    error cannotWithdrawTwice();
    error cannotWithdrawWithNegativePoints();



    function setUp ()public {
     vm.startPrank(organizer);
     scoreBoard = new ScoreBoard();
     predictor  = new ThePredictor(
        address(scoreBoard),
            0.04 ether,
            0.0001 ether);

        scoreBoard.setPredictor(address(predictor));

        vm.stopPrank();

    }

    function test_registration() public {
        vm.startPrank(stranger);
        vm.deal(stranger, 1 ether);
        predictor.register{value: 0.04 ether}();
        vm.stopPrank();

        assertEq(stranger.balance, 0.96 ether);
    }

    function test_playersAreLimited () public{
        for(uint256 i=0; i < 30; i++){
            address user = makeAddr(string.concat("user", Strings.toString(i)));
            vm.startPrank(user);
            vm.deal(user, 1 ether);
            predictor.register{value: 0.4 ether};
            vm.stopPrank();

            vm.startPrank(organizer);
            predictor.approvePlayer(user);
            vm.stopPrank();
      
        }

        vm.startPrank(stranger);
        vm.deal(stranger, 1 ether);
        predictor.register{value: 0.4 ether}();
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(AllSeatsAre_full.selector)

        );

        vm.startPrank(organizer);
        predictor.approvePlayer(stranger);
        vm.stopPrank();
    }

    function test_cannotEnterWithIncorrectFee () public{

     vm.expectRevert(
            abi.encodeWithSelector(Incoorect_entryFee.selector)
    );

        vm.startPrank(stranger);
        vm.warp(1);
        vm.deal(stranger, 1 ether);
        predictor.register{value: 0.01 ether}();
        vm.stopPrank();
    }

    function test_cannotJoin_afterDeadline() public{
    vm.expectRevert(
      abi.encodeWithSelector(DeadlineOver.selector)
    );
        vm.startPrank(stranger);
        vm.deal(stranger, 1 ether);
        vm.warp(1723752222);
        predictor.register{value: 0.0 ether}();
        vm.stopPrank();

    }

    function test_CannotRegsitorTwice() public { 
     

        vm.startPrank(stranger);
        vm.warp(1);
        vm.deal(stranger, 1 ether);
        predictor.register{value:  0.04 ether}();
           vm.expectRevert(
            abi.encodeWithSelector(CannotRegistorTwice.selector)
        );
        vm.warp(2);
        predictor.register{value:  0.04 ether}();
        vm.stopPrank();
    }

    function test_canRegisterAfterCancelation() public{
        vm.startPrank(stranger);
        vm.warp(1);
        vm.deal(stranger, 1 ether);
        predictor.register{value: 0.04 ether}();
        vm.warp(2);
        predictor.cancelRegistraion();
        vm.warp(3);
        predictor.register{value: 0.04 ether}();
        vm.stopPrank();

        assertEq(stranger.balance, 0.96 ether);

    }

    function  test_UnapprovedCanCancel() public {
        vm.startPrank(stranger);
        vm.warp(1);
        vm.deal(stranger, 1 ether);
        predictor.register{value: 0.04 ether}();
        vm.warp(10);
        predictor.cancelRegistraion();
        vm.stopPrank();

        assertEq(stranger.balance, 1 ether);

    }

    function test_approvedCannotWithdraw() public {
     vm.startPrank(stranger);
     vm.warp(1);
     vm.deal(stranger, 1 ether);
     predictor.register{value: 0.04 ether};
     vm.stopPrank();

     vm.startPrank(organizer);
     vm.warp(2);
     predictor.approvePlayer(stranger);
     vm.stopPrank();

     vm.expectRevert(abi.encodeWithSelector(Cannot_withdraw.selector));

     vm.startPrank(stranger);
     predictor.withdraw();
     vm.stopPrank();
    
    }

    function test_playersCannotScore() public {
        vm.expectRevert(
            abi.encodeWithSelector(ScoreBoard__UnauthorizedAccess.selector)
        );
        vm.startPrank(stranger);
        scoreBoard.setResult(0, ScoreBoard.Result.First);
        vm.stopPrank();
    }

    function test_scoreAreCorrect() public {
        vm.startPrank(stranger);
        vm.deal(stranger, 0.0003 ether);
        vm.stopPrank();
        
        vm.startPrank(organizer);
        vm.warp(2);
        scoreBoard.setResult(0, ScoreBoard.Result.First);
        vm.stopPrank();

        vm.startPrank(stranger);
        predictor.makePredection{value: 0.0001 ether}(
            0,
            ScoreBoard.Result.First
        );
        vm.stopPrank();

        vm.startPrank(organizer);
        vm.warp(3);
        scoreBoard.setResult(1, ScoreBoard.Result.Draw);
        vm.stopPrank();

        vm.startPrank(stranger);
        predictor.makePredection{value: 0.0001 ether}(
            1, ScoreBoard.Result.Second
        );
        vm.stopPrank();

        vm.startPrank(organizer);
        vm.warp(4);
        scoreBoard.setResult(2, ScoreBoard.Result.First);
        vm.stopPrank();

        vm.startPrank(stranger);
        predictor.makePredection{value: 0.0001 ether}(
            2, ScoreBoard.Result.First
        );
        vm.stopPrank();

        vm.startPrank(organizer);
        vm.warp(5);
        scoreBoard.setResult(3, ScoreBoard.Result.Draw);
        vm.stopPrank();

        assertEq(scoreBoard.getPlayerScore(stranger), 3);

    }

    function test_predectionFeesWithdrawl() public {
        vm.startPrank(stranger);
        vm.warp(1);
        vm.deal(stranger, 1 ether);
        predictor.register{value: 0.04 ether}();
        vm.stopPrank();

        vm.startPrank(organizer);
        vm.warp(2);
        predictor.approvePlayer(stranger);
        vm.stopPrank();

        vm.startPrank(stranger);
        vm.warp(3);
        predictor.makePredection{value: 0.0001 ether}(
            0,
            ScoreBoard.Result.Draw
        );
        predictor.makePredection{value: 0.0001 ether}(
            1,
            ScoreBoard.Result.Draw
        );
        vm.stopPrank();

        vm.startPrank(organizer);
        vm.warp(3);
        predictor.withdrawPredictionFees();
        vm.stopPrank();

        assertEq(organizer.balance, 0.0002 ether);
    }

    function test_makePredectionWithIncorrectPredectionFee() public {
        vm.startPrank(stranger);
        vm.warp(1);
        vm.deal(stranger, 1 ether);
        predictor.register{value: 0.04 ether}();
        vm.stopPrank();

        vm.startPrank(organizer);
        vm.warp(2);
        predictor.approvePlayer(stranger);
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector
            (
                ThePredictor_IncorrectPredectionfee.selector
            )
            );

        vm.startPrank(stranger);
        vm.warp(3);
        predictor.makePredection{value: 0.002 ether}(
            0,
            ScoreBoard.Result.Draw
        );

        vm.stopPrank();                                                                                                                                               
    }
   
   function test_makePredectionAfterDeadine() public {
    vm.startPrank(stranger);
    vm.warp(1);
    vm.deal(stranger, 1 ether);
    predictor.register{value: 0.04 ether}();
    vm.stopPrank();

    vm.startPrank(organizer);
    vm.warp(2);
    predictor.approvePlayer(stranger);
    vm.stopPrank();

    vm.warp(1723752222);
    vm.expectRevert(
        abi.encodeWithSelector(Predection_timeIsOver.selector)
    );

    vm.startPrank(stranger);
    vm.warp(3);
    predictor.makePredection{value: 0.0001 ether}(
        0, ScoreBoard.Result.Draw
    );

    vm.stopPrank();

   }

   function test_rewardDistributionWithAllWrongPredections() public {
        address stranger2 = makeAddr("stranger2");
        address stranger3 = makeAddr("stranger3");

        vm.startPrank(stranger);
        vm.deal(stranger, 1 ether);
        predictor.register{value: 0.04 ether}();
        vm.stopPrank();

        vm.startPrank(stranger2);
        vm.deal(stranger2, 1 ether);
        predictor.register{value: 0.04 ether}();
        vm.stopPrank();

        vm.startPrank(stranger3);
        vm.deal(stranger3, 1 ether);
        predictor.register{value: 0.04 ether}();
        vm.stopPrank();

        vm.startPrank(organizer);
        predictor.approvePlayer(stranger);
        predictor.approvePlayer(stranger2);
        predictor.approvePlayer(stranger3);
        vm.stopPrank();

        vm.startPrank(stranger);
        predictor.makePredection{value: 0.0001 ether}(
            1,
            ScoreBoard.Result.Draw
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            2,
            ScoreBoard.Result.Draw
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            3,
            ScoreBoard.Result.Draw
        );

        vm.stopPrank();

        vm.startPrank(stranger2);
        predictor.makePredection{value: 0.0001 ether}(
            1,
            ScoreBoard.Result.Draw
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            2,
            ScoreBoard.Result.Draw
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            3,
            ScoreBoard.Result.Draw
        );

        vm.stopPrank();

        vm.startPrank(stranger3);
        predictor.makePredection{value: 0.0001 ether}(
            1,
            ScoreBoard.Result.Draw
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            2,
            ScoreBoard.Result.Draw
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            3,
            ScoreBoard.Result.Draw
        );

        vm.stopPrank();

        vm.startPrank(organizer);
        scoreBoard.setResult(0, ScoreBoard.Result.First);
        scoreBoard.setResult(1, ScoreBoard.Result.First);
        scoreBoard.setResult(2, ScoreBoard.Result.First);
        scoreBoard.setResult(3, ScoreBoard.Result.First);
        scoreBoard.setResult(4, ScoreBoard.Result.First);
        scoreBoard.setResult(5, ScoreBoard.Result.First);
        scoreBoard.setResult(6, ScoreBoard.Result.First);
        scoreBoard.setResult(7, ScoreBoard.Result.First);
        scoreBoard.setResult(8, ScoreBoard.Result.First);
        vm.stopPrank();

        vm.startPrank(organizer);
        predictor.withdrawPredictionFees();
        vm.stopPrank();

        vm.startPrank(stranger);
        predictor.withdraw();
        vm.stopPrank();
        assertEq(stranger.balance, 0.9997 ether);

        vm.startPrank(stranger2);
        predictor.withdraw();
        vm.stopPrank();
        assertEq(stranger2.balance, 0.9997 ether);

        vm.startPrank(stranger3);
        predictor.withdraw();
        vm.stopPrank();
        assertEq(stranger3.balance, 0.9997 ether);

        assertEq(address(predictor).balance, 0 ether);

   }


        
    function test_cannotWithdrawrewardTwice() public {
        address stranger2 = makeAddr("stranger2");
        address stranger3 = makeAddr("stranger3");

        vm.startPrank(stranger);
        vm.deal(stranger, 1 ether);
        predictor.register{value: 0.04 ether}();
        vm.stopPrank();

        vm.startPrank(stranger2);
        vm.deal(stranger2, 1 ether);
        predictor.register{value: 0.04 ether}();
        vm.stopPrank();

        vm.startPrank(stranger3);
        vm.deal(stranger3, 1 ether);
        predictor.register{value: 0.04 ether}();
        vm.stopPrank();

        vm.startPrank(organizer);
        predictor.approvePlayer(stranger);
        predictor.approvePlayer(stranger2);
        predictor.approvePlayer(stranger3);
        vm.stopPrank();

        vm.startPrank(stranger);
        predictor.makePredection{value: 0.0001 ether}(
            1,
            ScoreBoard.Result.Draw
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            2,
            ScoreBoard.Result.Draw
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            3,
            ScoreBoard.Result.Draw
        );

        vm.stopPrank();

        vm.startPrank(stranger2);
        predictor.makePredection{value: 0.0001 ether}(
            1,
            ScoreBoard.Result.Draw
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            2,
            ScoreBoard.Result.Draw
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            3,
            ScoreBoard.Result.Draw
        );

        vm.stopPrank();

        vm.startPrank(stranger3);
        predictor.makePredection{value: 0.0001 ether}(
            1,
            ScoreBoard.Result.Draw
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            3,
            ScoreBoard.Result.Draw
        );

        vm.stopPrank();

        vm.startPrank(organizer);
        scoreBoard.setResult(0, ScoreBoard.Result.First);
        scoreBoard.setResult(1, ScoreBoard.Result.First);
        scoreBoard.setResult(2, ScoreBoard.Result.First);
        scoreBoard.setResult(3, ScoreBoard.Result.First);
        scoreBoard.setResult(4, ScoreBoard.Result.First);
        scoreBoard.setResult(5, ScoreBoard.Result.First);
        scoreBoard.setResult(6, ScoreBoard.Result.First);
        scoreBoard.setResult(7, ScoreBoard.Result.First);
        scoreBoard.setResult(8, ScoreBoard.Result.First);
        vm.stopPrank();

        vm.startPrank(organizer);
        predictor.withdrawPredictionFees();
        vm.stopPrank();

        vm.startPrank(stranger);
        predictor.withdraw();
        vm.stopPrank();
        assertEq(stranger.balance, 0.9997 ether);

        vm.expectRevert(
            abi.encodeWithSelector(cannotWithdrawTwice.selector)
        );

        vm.startPrank(stranger);
        predictor.withdraw();
        vm.stopPrank();
   }

   function test_cannotWithdrawWithNegativePoints() public {
        address stranger2 = makeAddr("stranger2");
        address stranger3 = makeAddr("stranger3");

        vm.startPrank(stranger);
        vm.deal(stranger, 1 ether);
        predictor.register{value: 0.04 ether}();
        vm.stopPrank();

        vm.startPrank(stranger2);
        vm.deal(stranger2, 1 ether);
        predictor.register{value: 0.04 ether}();
        vm.stopPrank();

        vm.startPrank(stranger3);
        vm.deal(stranger3, 1 ether);
        predictor.register{value: 0.04 ether}();
        vm.stopPrank();

        vm.startPrank(organizer);
        predictor.approvePlayer(stranger);
        predictor.approvePlayer(stranger2);
        predictor.approvePlayer(stranger3);
        vm.stopPrank();

        vm.startPrank(stranger);
        predictor.makePredection{value: 0.0001 ether}(
            1,
            ScoreBoard.Result.Draw
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            2,
            ScoreBoard.Result.Draw
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            3,
            ScoreBoard.Result.Draw
        );

        vm.stopPrank();

        vm.startPrank(stranger2);
        predictor.makePredection{value: 0.0001 ether}(
            1,
            ScoreBoard.Result.Draw
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            2,
            ScoreBoard.Result.First
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            3,
            ScoreBoard.Result.First
        );

        vm.stopPrank();

        vm.startPrank(stranger3);
        predictor.makePredection{value: 0.0001 ether}(
            1,
            ScoreBoard.Result.First
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            2,
            ScoreBoard.Result.First
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            3,
            ScoreBoard.Result.Draw
        );

        vm.stopPrank();

        vm.startPrank(organizer);
        scoreBoard.setResult(0, ScoreBoard.Result.First);
        scoreBoard.setResult(1, ScoreBoard.Result.First);
        scoreBoard.setResult(2, ScoreBoard.Result.First);
        scoreBoard.setResult(3, ScoreBoard.Result.First);
        scoreBoard.setResult(4, ScoreBoard.Result.First);
        scoreBoard.setResult(5, ScoreBoard.Result.First);
        scoreBoard.setResult(6, ScoreBoard.Result.First);
        scoreBoard.setResult(7, ScoreBoard.Result.First);
        scoreBoard.setResult(8, ScoreBoard.Result.First);
        vm.stopPrank();

        vm.startPrank(organizer);
        predictor.withdrawPredictionFees();
        vm.stopPrank();

        vm.startPrank(stranger);
        predictor.withdraw();
        vm.stopPrank();
        assertEq(stranger.balance, 0.9997 ether);

        vm.expectRevert(
            abi.encodeWithSelector(cannotWithdrawWithNegativePoints.selector)
        );

        vm.startPrank(stranger);
        predictor.withdraw();
        vm.stopPrank();

   }

   function test_rewardsDistributionIsCorrect() public {
        address stranger2 = makeAddr("stranger2");
        address stranger3 = makeAddr("stranger3");

        vm.startPrank(stranger);
        vm.deal(stranger, 1 ether);
        predictor.register{value: 0.04 ether}();
        vm.stopPrank();

        vm.startPrank(stranger2);
        vm.deal(stranger2, 1 ether);
        predictor.register{value: 0.04 ether}();
        vm.stopPrank();

        vm.startPrank(stranger3);
        vm.deal(stranger3, 1 ether);
        predictor.register{value: 0.04 ether}();
        vm.stopPrank();

        vm.startPrank(organizer);
        predictor.approvePlayer(stranger);
        predictor.approvePlayer(stranger2);
        predictor.approvePlayer(stranger3);
        vm.stopPrank();

        vm.startPrank(stranger);
        predictor.makePredection{value: 0.0001 ether}(
            1,
            ScoreBoard.Result.Draw
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            2,
            ScoreBoard.Result.Draw
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            3,
            ScoreBoard.Result.Draw
        );

        vm.stopPrank();

        vm.startPrank(stranger2);
        predictor.makePredection{value: 0.0001 ether}(
            1,
            ScoreBoard.Result.Draw
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            2,
            ScoreBoard.Result.First
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            3,
            ScoreBoard.Result.First
        );

        vm.stopPrank();

        vm.startPrank(stranger3);
        predictor.makePredection{value: 0.0001 ether}(
            1,
            ScoreBoard.Result.First
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            2,
            ScoreBoard.Result.First
        );
        
        predictor.makePredection{value: 0.0001 ether}(
            3,
            ScoreBoard.Result.First
        );

        vm.stopPrank();

        vm.startPrank(organizer);
        scoreBoard.setResult(0, ScoreBoard.Result.First);
        scoreBoard.setResult(1, ScoreBoard.Result.First);
        scoreBoard.setResult(2, ScoreBoard.Result.First);
        scoreBoard.setResult(3, ScoreBoard.Result.First);
        scoreBoard.setResult(4, ScoreBoard.Result.First);
        scoreBoard.setResult(5, ScoreBoard.Result.First);
        scoreBoard.setResult(6, ScoreBoard.Result.First);
        scoreBoard.setResult(7, ScoreBoard.Result.First);
        scoreBoard.setResult(8, ScoreBoard.Result.First);
        vm.stopPrank();

        vm.startPrank(organizer);
        predictor.withdrawPredictionFees();
        vm.stopPrank();

        vm.startPrank(stranger2);
        predictor.withdraw();
        vm.stopPrank();
        assertEq(stranger2.balance, 0.9997 ether);

        vm.startPrank(stranger3);
        predictor.withdraw();
        vm.stopPrank();
        assertEq(stranger3.balance, 1.0397 ether);

        assertEq(address(predictor).balance, 0 ether);

   }

}