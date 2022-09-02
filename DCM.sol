
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/utils/Counters.sol";

contract DCM {

    using Counters for Counters.Counter;
    Counters.Counter private _projectIds;

    enum ProjectStatus {
        INITIATED,
        INREVIEW,
        COMPLETED
    }

    struct DAO {
        string name;
        string description;
        address uniqueAddress; //For eventual gating purposes
        uint numBounties;
    }

    struct Contributor {
        address user;
        string name;
        string description;
        string linkedIn;
        string github;
        uint avgRatePerHour;
        uint numProjects;
    }

    struct Project {
        uint id;
        string name;
        string description;
        uint maxCompensation;
        uint startDate;
        uint endDate;
        address dao;
        address user;
        ProjectStatus status;
    }

    Contributor[] contributors;
    Project[] projects;

    event EscrowCreated(address indexed escrowAddress, uint indexed amount, uint indexed projectId);
    event EscrowSettled(uint projectId);

    //DAO -> Project ID Mapping
    mapping(address => uint[]) daoToProjectsMap;

    //Project -> Escrow Contract
    mapping(uint => address) projectToEscrowMap;

    //Project ID -> Project Struct
    mapping(uint => Project) projectIdToProjectMap;

    //User ID -> User Struct
    mapping(address => Contributor) contributorIdToUserMap;

    modifier onlyDao(address _dao, uint _id) {
        uint isDao = false;
        for(uint i = 0; i < daoToProjectsMap[_dao]; i++){
            if(_id == daoToProjectsMap[_dao][i]) {
                isDao = true;
            }
        }

        require(isDao, "The project doesn't belong to this DAO");
        _;
    }
    //***************** Write functions *****************//
    
    //Add a new contributor
    function createContributor(string memory _name, string memory _description, string memory _linkedIn, string memory _github, uint _averageRatePerHour) public returns(address) {
        userIdToUserMap[msg.sender] = Contributor(msg.sender, _name, _description, _linkedIn, _github, _averageRatePerHour, 0);
        contributors.push(userIdToUserMap[msg.sender]);

        return msg.sender;
    }

    function createProject(string memory _name, string memory _description, uint _maxCompensation, uint _startDate, uint _endDate, address _dao, address _contributor) internal returns(uint) {
        _projectIds.increment();
        uint projectId = _projectIds.current();

        projectIdToProjectMap[projectId] = Project(projectId, _name, _description, _maxCompensation, _startDate, _endDate, _dao, _contributor, ProjectStatus.INREVIEW);

        projects.push(projectIdToProjectMap[projectId]);

        return projectId;
    }

    //Current logic states that the one who is invited is auomatically going to work on the project, not for productio/// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param Documents a parameter just like in doxygen (must be followed by parameter name)
    // MaxConmpensation = x*10^18
    function inviteContributor(address contributor, string memory _name, string memory _description, uint _maxCompensation, uint _startDate, uint _endDate) public payable {
        //1. Create a Project
        uint projectId = createProject(_name, _description, _maxCompensation, _startDate, _endDate, msg.sender, contributor);
        daoToProjectsMap[msg.sender].push(projectId);

        //2. Spin up an escrow with maxCompensation
        Escrow escrowContract = new Escrow(_maxCompensation, projectId, _startDate, _endDate, contributor, msg.sender);
        projectToEscrowMap[projectId] = address(escrowContract);

        //3. Transfer money into Escrow contract once it is created.
        address(escrowContract).transfer(_maxCompensation);

        emit EscrowCreated(address(escrowContract), _maxCompensation, projectId);
    }

    function approveProject(uint projectId) external onlyDao(msg.sender, projectId) {
        Escrow escrowContract = Escrow(projectToEscrowMap[projectId]);
        escrowContract.settle();

        Project storage project = projectIdToProjectMap[projectId];
        project.status = ProjectStatus.COMPLETED;

        emit EscrowSettled(projectId);

    }

    //******************* Read functions *****************//

    function getAllProjects() public returns(Project[] memory) {
        return projects;
    }

    function getAllContributors() public returns(Contributor[] memory) {
        return contributors;
    } 

    function getProjectFromId(uint projectId) public returns(Project memory) {
        return projectIdToProjectMap[projectId];
    }

}

contract DCMEscrow {
    uint amount;
    uint projectId;
    uint projectStartDate;
    uint projectEndDate;
    address payer;
    address payee;

    enum Status {
        CREATED,
        SETTLED
    }

    modifier onlyPayee() {
        require(msg.sender == payee);
    }

    constructor(uint _amount, uint _projectId, uint _projectStartDate, uint _projectEndDate, address _payee, address _payer) payable {
     amount = _amount;
     projectId = _projectId;
     projectStartDate = _projectStartDate;
     projectEndDate = _projectEndDate;
     payer = _payer;
     payee = _payee;

    }

    function settle() public {
        requires(balance(this) == amount, "The Escrow contract does not have any balance");
        payable(payee).transfer(balance(this));
    }

    function cancelEscrow() onlyPayee {
        requires(balance(this) == amount, "The Escrow contract does not have any balance");
        payable(payer).transfer(balance(this));
    }

}
