//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

contract Lottery{
    address payable[] public players;       //Lists all the addresses of who contributed to the lottery
    address public manager;                 //Address of the one who manages the lottery
    uint endtime;                           //endtime of the lottery
    uint starttime;                         //start time of the lottery
    
    constructor(uint _time){
        manager=msg.sender;                 //initializes the person who starts the lottery as the manager
        starttime = block.timestamp;        //starttime is time of current block when initialized
        endtime = starttime + _time;        //endtime is defined by the manager in constructor
    }
    
    receive() external payable{
        require(msg.value == 1 ether, "You must deposit exactly one ether"); //can deposit exactly one ether
        require(msg.sender != manager, "You are the manager");              //depositor cannot be the manager
        require(block.timestamp<= endtime, "The lottery has ended");        //deposit must be made before time ends
        players.push(payable(msg.sender));                                  //push the player to the array of players after depositing
    }
    
    function getBalance()public view returns(uint){                             //returns the balance of the contract
        require(msg.sender == manager, "You must be the manager to view this"); //only accessible for manager
        return address(this).balance;
    }
    
    function random()private view returns(uint){    //generates a psuedo random number
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    function gettimeLeft() public view returns(uint){   //returns time left to deposit ether in lottery
        if (block.timestamp>= endtime){
            return 0;
        }
        else{
            return endtime-block.timestamp;
        }
    }
    
    function pickWinner() public returns(address){
        require(msg.sender == manager, "Manager must pick winner"); //manager is the only one that can initialize the winner
        require(block.timestamp >= endtime); //must be past the time given to deposit into the lottery
        
        uint r = random();
        address payable winner;
        uint index = r % players.length;    //finds random index in array of players with modulus operator
        winner = players[index];
        uint fee = (getBalance())/20;       //calculates fee as 5% of the pot
        payable(manager).transfer(fee);     //gives the fee to the manager
        winner.transfer(getBalance());      //transfers the remainding balance to the winner
        players = new address payable[](0); //makes a new array for the players array
        
        return winner;                      //returns the winner
    }
}
