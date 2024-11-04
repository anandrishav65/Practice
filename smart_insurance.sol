// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract InsuranceContract {
    address public insurer;

    struct Policy {
        address policyholder;
        uint256 premium;
        uint256 coverage;
        uint256 duration;
        bool active;
        uint256 lastpremiumpaid;
        uint256 endDate;
    }

    struct Claim {
        uint256 amount;
        bool approved;
        bool paid;
        string reason;
    }

    mapping(address => Policy) public policies;
    mapping(address => Claim) public claims;

    modifier onlyInsurer() {
        require(msg.sender == insurer, "Not authorized");
        _;
    }

    // Events for logging and transparency
    event PolicyIssued(address indexed policyholder, uint256 coverage,uint256 duration);
    event PremiumPaid(address indexed policyholder, uint256 amount);
    event ClaimSubmitted(address indexed policyholder, uint256 amount);
    event ClaimApproved(address indexed policyholder);
    event ClaimPaid(address indexed policyholder, uint256 amount);

    constructor() {
        insurer = msg.sender;
    }

    function issuePolicy(address _policyholder, uint256 _premium, uint256 _coverage, uint256 _duration) external onlyInsurer {
        uint256 startDate=block.timestamp;
        uint256 endDate= startDate + (_duration*1 days);
        policies[_policyholder] = Policy(_policyholder, _premium, _coverage, _duration, true,startDate,endDate);
        emit PolicyIssued(_policyholder,_coverage,_duration);
    }

    function payPremium() external payable {
        require(policies[msg.sender].active, "Policy inactive");
        require(msg.value == policies[msg.sender].premium, "Incorrect premium");
        require(block.timestamp <= policies[msg.sender].endDate, "Policy has expired");
        policies[msg.sender].lastpremiumpaid= block.timestamp;
        emit PremiumPaid(msg.sender, msg.value);
    }

    function submitClaim(uint256 _amount,string memory reason) external {
        require(policies[msg.sender].policyholder == msg.sender, "Only policyholder can submit claim");
        require(policies[msg.sender].active, "Policy inactive");
        require(_amount <= policies[msg.sender].coverage, "Claim amount exceeds coverage");
        claims[msg.sender] = Claim(_amount, false,false,reason);
        emit ClaimSubmitted(msg.sender,_amount);
    }

    function approveClaim(address _policyholder) external onlyInsurer {
        require(!claims[_policyholder].approved, "Claim already approved");
        require(!claims[_policyholder].paid, "Claim already paid");
        claims[_policyholder].approved = true;
        emit ClaimApproved(_policyholder);

    }

    function payClaim(address payable _policyholder) external payable onlyInsurer {
        require(claims[_policyholder].approved, "Claim not approved");
        require(!claims[_policyholder].paid, "Claim already paid");
        _policyholder.transfer(claims[_policyholder].amount);
        claims[_policyholder].paid=true;
        emit ClaimPaid(_policyholder,claims[_policyholder].amount);

    }
}
