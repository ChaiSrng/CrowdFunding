// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CrowdFunding {
    mapping(address => uint) public contributors;
    address public manager;
    uint public minContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmt;
    uint public noOfContributors;
    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }
    mapping(uint => Request) public requests;
    uint public numRequests;

    constructor(uint _target,uint _deadline){
        target = _target;
        deadline = block.timestamp+_deadline;  //block.timestamp gives the time taken to create the block(in sec), so say 10 sec then 10 + (60  * 60 i.e for 1 hr) 3600 = 3610 will be the deadline
        minContribution = 100 wei;
        manager = msg.sender;
    }

    function sendEth() public payable{
        require(block.timestamp < deadline,"Deadline has passed");
        require(msg.value>= minContribution,"Minimum contribution is not met");

        if(contributors[msg.sender] == 0){  //check for 1st time contributor, if yes adding him to the list of contributors
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value; //adding the contributed at to contributor address
        //we need to keep in mind tat for 51% of contributors count we should take the contributor address into count and the number of times a contributor has contributed. Hence adding the values sent by a contributor in his account.
        raisedAmt += msg.value; //taking the amt to the total amt contribution
    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public{
        require(block.timestamp> deadline && raisedAmt < target, "You are not eligible for refund");
        require(contributors[msg.sender] > 0,"No contributed amount reflected!!");
        address payable user = payable(msg.sender); //making user payable so we can use transfer on the address
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    modifier onlyManager(){
        require(msg.sender == manager, "Only Manager can call this function!");
        _;
    }

    function createRequests(string memory _description, address payable _recipient, uint _value) public onlyManager{
        Request storage newRequest = requests[numRequests]; //need to use storage for struct type
        numRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
        //in the function "createRequests" we can add "require" like "_value <= raisedAmount"
    }

    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender] > 0,"You must be a contributor");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender] == false, "You have already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
        //require(requests[_requestNo] > -1, "You're trying to vote to a non-existing request");
        //require(block.timestamp < deadline ,"Voting has been ended");
    }

    function makePayment(uint _requestNo) public onlyManager{
        require(raisedAmt>= target);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false,"The request has been completed");
        require(thisRequest.noOfVoters > noOfContributors/2,"Majority of contributors does not support this request");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;        
    }
}