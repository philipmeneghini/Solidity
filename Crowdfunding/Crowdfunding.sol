//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

contract CrowdFunding{
    mapping(address => uint) public contributors;//mapping showing who contributed and how much
    address public admin;                       //admin is the address who initializes and starts the CrowdFunding
    uint public numberofContributors;           //number of people contributing money to the crowdfunding campaign
    uint public minimumContribution;            //minimum amount a person is allowed to contribute to the crowdfunding campaign
    uint public deadline;                       //time when the crowdfunding campaign is finished
    uint public goal;                           //how much money is suppose to be raised
    uint public raisedAmount;                   //how much money was actually raised
    struct Request{                             //A request on how to spend the raised money which is publically available for contributors to see and vote on
        string description;                     //Describes the nature of the request and what the money will be put towards
        address payable recipient;              //The address or person who will recieve the money
        uint value;                             //The amount of the raised money that will be contributed
        bool completed;                         //Whether or not the request is completed
        uint numvotesfor;                       //How many votes for this proposal
        mapping(address => bool) voters;
    }
    
    mapping(uint => Request) public requests;   //A mapping of all the requests
    uint public numRequests;                    //The number of requests made
    
    constructor(uint _goal, uint _deadline, uint mincont){
        goal = _goal;
        deadline = block.timestamp + _deadline;
        minimumContribution= mincont;
        admin=msg.sender;                       //admin is the one who initializes the contract
    }
    
    //All events are used to emit a special signature on the blockchain when somone contributes to the campaign votes on a request or makes a request
    event ContributeEvent(address _sender, uint value);
    event CreateRequestEvent(string _description, address _recipient, uint value);
    event MakePaymentEvent(address _recipient, uint _value);
    
    function contribute() public payable{
        //contribution must be made before deadline and be equal to or more than the minimum amount
        require(block.timestamp < deadline, "Deadline has passed");
        require(msg.value>= minimumContribution, "Minimum Contribution not met");
        
        if(contributors[msg.sender]==0){
            numberofContributors++;     //increment the number of contributors if this person has not contributed yet
        }
        
        contributors[msg.sender]+= msg.value;
        raisedAmount += msg.value;
        
        emit ContributeEvent(msg.sender, msg.value);    //emit an event once the money has been transfered
    }
    
    receive() payable external{         //Makes this contract payable
        contribute();
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;       //returns balance of function
    }
    
    function getRefund()public{
        require(block.timestamp > deadline && raisedAmount < goal);
        require(contributors[msg.sender]>0);
        
        //If the amount raised during the deadline was less than the goal then each contributor can request their money back
        
        address payable recipient= payable(msg.sender);
        uint value = contributors[msg.sender];
        recipient.transfer(value);
        contributors[msg.sender] = 0;
    }
    
    modifier onlyAdmin(){   //modifier for a function that only the admin can call
        require(msg.sender == admin, "Only admin can call this function!");
        _;
    }
    
    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin{
        Request storage newRequest =requests[numRequests];      //Stores the new struct in storage
        numRequests++;
        
        newRequest.description = _description;
        newRequest.recipient= _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.numvotesfor = 0;
        //emits an event when a new Request is created
        emit CreateRequestEvent(_description, _recipient, _value);
    }
    
    function newvote(uint ind)public{
        require(contributors[msg.sender]>0, "You must be a contributor to vote");
        Request storage thisRequest = requests[ind];
        require(thisRequest.voters[msg.sender]==false, "You have already voted!");
        thisRequest.numvotesfor+= contributors[msg.sender];     //vote is weighted to how much they contributed
        thisRequest.voters[msg.sender]=true;        //indicates that this person has already voted
    }
    
    function makePayment(uint _requestNo)public onlyAdmin{
        require(raisedAmount>= goal);                               //Raised amount must be above or equal to the goal
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false, "request already completed");
        require(thisRequest.numvotesfor>(getBalance())/2);          //Must have over 50% of the votes to make the payment
        payable(thisRequest.recipient).transfer(thisRequest.value);//transfers the value over to the intended party
        requests[_requestNo].completed == true;
        //emits an event when some of the money has been spent for the cause
        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }
}
        
