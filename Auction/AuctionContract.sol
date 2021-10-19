//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

contract Auction{                               //contract used to deploy multiple auction instances
    address public owner= msg.sender;           //owner is the one who initiated this contract
    AuctionInstance[] public auctions;          //AuctionInstance is an array of all the Auctions deployed currently
    
    function deployAuction(uint time) public{            //deploy Auction initializes a new Auction contract and pushes it to the array of Auctions
        //must define how long the auction will go for in seconds
        AuctionInstance auctionin = new AuctionInstance(msg.sender, time);
        auctions.push(auctionin);
    }
}

contract AuctionInstance{
    address payable public owner;
    uint startTime;
    uint endTime;
    
    enum State {Started, Running, Ended, Canceled}      //4 states for this contract
    State public auctionState;
    
    uint public highestBindingBid;
    address payable public highestBidder;
    
    mapping(address => uint) private bids;   //mappings points addresses to the corresponding amount that they bid
    
    uint bidIncrement;      //how much the bid will increment if a higher bid is placed
    
    
    constructor(address eoa, uint time){
        owner=payable(eoa);     //owner is the one who initialized the auction
        auctionState= State.Running;    //set state initially to running
        startTime = block.timestamp;    //set block start time as the time the contract was constructed
        endTime = startTime + time;
        bidIncrement = 100;             //bid incrmenet is 100 wei
    }
    
    modifier notOwner(){                                        //modifier to make sure the sender is not the owner
        require(msg.sender != owner);
        _;
    }
    
    modifier afterStart(){                                      //modifier to make sure the auction has started
        require(block.timestamp >= startTime);
        _;
    }
    
    modifier beforeEnd(){                                       //modifier to make sure the auction hasn't ended yet
        require(block.timestamp<= endTime);
        _;
    }
    
    function getBid(address person)public view returns(uint){   //returns the amount bid for each person
        if(person != highestBidder){
            return bids[person];
        }
        else{
            return highestBindingBid;                           //for highstbidder we display the binding bid and not their actual bid
        }
    }
    
    function min(uint a, uint b)pure internal returns(uint){        //internal min method to extract the minimum value of two values
        if(a>=b){
            return b;
        }
        else{
            return a;
        }
    }
    
    modifier onlyOwner(){                                       //modifier to make sure the sender is the owner
        require(msg.sender ==owner);
        _;
    }
    
    function cancelAuction() public onlyOwner{                  //function cancels the auction only the owner can do this
        auctionState=State.Canceled;
    }
    
    function timeLeft() public view returns(uint){              //gives the time left in the auction
        if( endTime > block.timestamp){                     //make sure it does not display a negative number
            return endTime - block.timestamp;
        }
        return 0;
    }
    
    function placeBid() public payable notOwner afterStart beforeEnd{       //make sure if someone places a bid they are not the owner and the bid is still going
        require(auctionState== State.Running);                  //require the state to be running
        require(msg.value >=100);                               //minimum amount of 100 wei can be bid
        
        uint currentBid= msg.value + bids[msg.sender];
        require(currentBid> highestBindingBid);                 //current bid must be higher than the current highest binding bid
        
        bids[msg.sender]= currentBid;
        
        if(currentBid<= bids[highestBidder]){
            highestBindingBid= min(currentBid + bidIncrement, bids[highestBidder]); //increments the binding bid by the increment if highest bidder has more bidder
            //if bid is tied then highest bidder will still win the bid because they put their bid in first
        }else{
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement); //if current bid is larger than highest bid then previous highest bid gets incremented and becomes the highest binding bid
            highestBidder = payable(msg.sender);                                    //highest bidder becomes the cender of the current bid
        }
    }
    
    function finalizeAuction() public onlyOwner{                    //only the owner can finalize the auction after time has run out
        require(auctionState == State.Canceled || block.timestamp > endTime);
        require(msg.sender == owner);
        
        if(auctionState == State.Canceled){
            auctionState = State.Ended;
        }else{
            owner.transfer(highestBindingBid);
            bids[highestBidder]-=highestBindingBid;     //takes highest bindingbid from the highest bidder for the auction item
            auctionState = State.Ended;                 //changes the auction state to ended
        }
    }

    function recieveMoney() public{             //each player must call this function to recieve their money back
        require(bids[msg.sender]>=0);
        require(auctionState == State.Ended);   //state must be endeed and the auction must be finalized by the owner first
        
        payable(msg.sender).transfer(bids[msg.sender]);
        bids[msg.sender]=0;
    }
}
