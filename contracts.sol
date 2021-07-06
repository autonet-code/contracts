pragma solidity ^0.7.0;
import "http://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.1-solc-0.7/contracts/token/ERC721/ERC721.sol";
import "http://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.1-solc-0.7/contracts/token/ERC721/IERC721Receiver.sol";
import "http://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.1-solc-0.7/contracts/token/ERC777/ERC777.sol";
import "http://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.1-solc-0.7/contracts/token/ERC777/IERC777Sender.sol";
import "http://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.1-solc-0.7/contracts/token/ERC777/IERC777Recipient.sol";
import "http://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.1-solc-0.7/contracts/introspection/ERC1820Implementer.sol";
import "http://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.1-solc-0.7/contracts/introspection/IERC1820Registry.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

//https://soliditydeveloper.com/erc-777
contract Agent is ERC721 {
    uint256 public nextTokenId;
    address public admin;
    // address public project;   // shall the admin be the project. For now: Yes!
    string private endpoint;  // TODO set private
    
    constructor() ERC721("Autonet Project", "ATP") {
        admin = msg.sender;
    }

    function mint(address to) external {
        require(msg.sender == admin, "only admin");
        _safeMint(to, nextTokenId);
        nextTokenId++;
    }
    
    function getEndpoint() external view returns(string memory) {
        require(msg.sender==admin, "only the parent Preoject can get the endpoint for this token");
        return endpoint;
    }
    
    function setEndpoint(string memory _endpoint) external returns(bool) {
        require(msg.sender==admin, "only the parent Preoject can get the endpoint for this token");
        endpoint = _endpoint;
        return true;
    }

    function _baseURI() internal pure returns (string memory) {
        return "https://us-central1-afterme-850af.cloudfunctions.net/NFT/";
    }
}


// * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol)
contract Project is IERC777Recipient, IERC721Receiver{
    
    using SafeMath for uint256;
    Agent model;
    string code;
    string public name;
    string private endpoint;
    MainToken banu; 
    address private tokenAddress;
    // Source source;
    // AgentFactory agentFactory;
    
    address payable sourceContractAddress;
    
    enum status { investing, training, validating, mature}
    enum subscriberStatus {depleted, active, blocked }
    struct subscriberData {
        uint256 balance;
        uint256 ratePerSecond;
        subscriberStatus status;
        uint256 lastTimeStamp;  // last time something changed in the escrow account balance
    }
    status projectStatus;
    address public founder;
    address public deployer;
    EscrowFactory escrowFactory;
    address private escrow;
    address public modelAddress;
    
    mapping(address => uint256) public shares;
    mapping(address => subscriberData) subscriber;
    address[] public subscribers;
    
    uint256[] public ratePerTarif;  // rate per seconds. Each entry is a different tarif, labelled by natural numbers.
    uint256 public defaultDripRate = 12 * (10**14);
    
    uint256 public spentOnTraining;
    uint256 public availableShares = 930 * (10**3);
    uint256 public founderShares = 70 * (10**3);
    uint256 public initialTrainingCost = 1547 * (10**15);
    uint256 public pricePerShare = initialTrainingCost / availableShares;
    uint256 public fundingGoal;
    
    // uint256 public founderDividendPermille;
    
    uint256 lastPayout;

    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH
        = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;
    
    
    constructor(
        address adresaLaBanu,
        address adresaLaSource,
        string memory _name,
        string memory _code,
        address _founder,
        uint256 _fundingGoal
    ) payable {
        tokenAddress = adresaLaBanu;
        banu = MainToken(adresaLaBanu);
        sourceContractAddress = payable(adresaLaSource);
        // source = Source(sourceContractAddress);
        founder = _founder;
        // founderDividendPermille = _founderDividendPermille;
        fundingGoal = _fundingGoal;
        projectStatus = _reachedFundingGoal() ? status.training : status.investing; 
        
        deployer = msg.sender;
        name = _name;
        code = _code;
        shares[_founder] = founderShares;
        
        // set default tarif from source contract 
        ratePerTarif.push(defaultDripRate);
        
        _erc1820.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
        
        escrowFactory = new EscrowFactory();
        // agentFactory = new AgentFactory();
        escrow = escrowFactory.createEscrow(tokenAddress);
        
        
    }

    function setNewTarif(uint256 newDripRate) public onlyDeployerOrFounder {
        ratePerTarif.push(newDripRate);
    }
    
    function getTarifs(uint256 tarif) public view returns (uint256){
        return ratePerTarif[tarif];
    }
    
    function getEscrow() public view returns(address) {
        return escrow;
    }
    
    function getProjectStatus() public view returns (string memory) {
        if (projectStatus == status.investing){
            return "investing";
        } else if (projectStatus == status.training){
            return "training";
        } else if (projectStatus == status.validating) {
            return "validating";
        } else if (projectStatus == status.mature) {
            return "mature";
        } else {
            return "not known";
        }
    }
    
    function changeCodeUrl(string memory url) external onlyDeployerOrFounder {
        code = url;
    }
    
    function transferAdmin(address newAdmin) external onlyDeployerOrFounder {
        founder = newAdmin;
    }
    
    function completeTraining(string memory api) external {
        if (projectStatus == status.training){
            projectStatus = status.validating;
            // now starts the validation. 
            // here we just declare validation completed
            endpoint=api;
            this.completeValidation(); // TODO: Should be called from outside (this is just mock-up)
        }
    }
    
    function completeValidation() external {
        if (projectStatus == status.validating){
            projectStatus = status.mature;
            model = new Agent();
            model.mint(address(this));  // mints it to the project 
            // model = agentFactory.createModel(address(this));
            model.setEndpoint(endpoint);
        }
    }
    
    
    
    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) external override returns (bytes4)
    {
        
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
    
    function subscribeFromUserAccount(uint256 ATNamount, uint256 tarif) external {
        uint256 ATNdripRatePerSecond = ratePerTarif[tarif];
        require(ATNdripRatePerSecond>0, "no free lunch");
        _subscribe(msg.sender, ATNamount, ATNdripRatePerSecond);
    }
    
    function subscribeFromExternallyOwnedAccount(uint256 ATNamount, uint256 tarif)  external {
        uint256 ATNdripRatePerSecond = ratePerTarif[tarif];
        // address user = Source(sourceContractAddress).getUser(msg.sender);
        require(ATNdripRatePerSecond>0, "no free lunch");
        _subscribe(Source(sourceContractAddress).getUser(msg.sender), ATNamount, ATNdripRatePerSecond);
    }
    
    /*
    Must be called by a user contract.
    */
    function _subscribe(address user, uint256 ATNamount, uint256 dripRate) internal {
        Source(sourceContractAddress).subscribe(user, escrow, ATNamount);
        // TODO: first execute a drip with the old rate in case there is still some ATN in the subscription.
        subscriber[user].balance += ATNamount;
        subscriber[user].ratePerSecond = dripRate;
        subscriber[user].status = (subscriber[user].balance>0? subscriberStatus.active: subscriberStatus.depleted);
        subscriber[user].lastTimeStamp = block.timestamp;
    }
    
    function unsubscribeFromUserAccount() external {
        _unsubscribe(msg.sender);
    }
    
    function unsubscribeFromExternallyOwnedAccount()  external {
        _unsubscribe(Source(sourceContractAddress).getUser(msg.sender));
    }
    
    function _unsubscribe(address user) internal {
        // calculate how much gets repayed to the user 
        (uint256 escrowBalanceOfProject,
         uint256 escrowBalanceOfUser) = getEscrowBalanceSplit(user);
        subscriber[user].balance = 0;
        subscriber[user].status = subscriberStatus.depleted;
        // update the lastTimeStamp;
        subscriber[user].lastTimeStamp = block.timestamp;
        Source(sourceContractAddress).unsubscribe(user, escrow, address(this), escrowBalanceOfProject, escrowBalanceOfUser);
    }
    
    function withdrawSurplusFromEscrow() public {
        uint256 totalWithdraw = 0;
        for (uint256 j; j<subscribers.length; j++){
            if (subscriber[subscribers[j]].status != subscriberStatus.active){
                continue;
            }
            (uint256 escrowBalanceOfProject, ) = getEscrowBalanceSplit(subscribers[j]);
            totalWithdraw += escrowBalanceOfProject;
            subscriber[subscribers[j]].balance -= escrowBalanceOfProject;
            subscriber[subscribers[j]].lastTimeStamp = block.timestamp;
        }
        Source(sourceContractAddress).withdrawFromEscrow(escrow, totalWithdraw); 
    }
    
    
    function getEscrowBalanceSplit(address user) public returns (uint256, uint256) {
        uint256 ATNfees = subscriber[user].ratePerSecond.mul(block.timestamp.sub(subscriber[user].lastTimeStamp));
        if (subscriber[user].balance > ATNfees) {
            return (ATNfees, subscriber[user].balance.sub(ATNfees));
        } else {
            subscriber[user].status = subscriberStatus.depleted;
            return (subscriber[user].balance.sub(ATNfees), uint256(0));
        } 
    }
    
    function getWithdrawableBalanceUser(address user) external returns(uint256){
        
        require(msg.sender==user, "only user can query this!");
        ( ,uint256 escrowBalanceOfUser) = getEscrowBalanceSplit(user);
        return banu.balanceOf(user) + escrowBalanceOfUser;
    }
    
    function requestEndpoint(address user) external view returns (string memory) {
        require(msg.sender==user, "only user can query this!");
        require(subscriber[user].status == subscriberStatus.active, "not enough funds.");
        return model.getEndpoint();
    }
    
    
    function balanceATN() public view returns (uint256) {
        return banu.balanceOf(address(this));
    }

    function balanceETH() public view returns (uint256) {
        return address(this).balance;
    }

    function append(
        string memory a,
        string memory b,
        string memory c
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }

    


    function invest(uint256 ATNamount) public payable {
        require(
            ATNamount / pricePerShare <= availableShares && availableShares>0,
            "Can't buy more than he available shares"
        );
        Source(sourceContractAddress).registerHookForAccount(msg.sender);
        Source(sourceContractAddress).invest(msg.sender, address(this), ATNamount, msg.value);
        if (_reachedFundingGoal()){
            projectStatus = status.training;
            Source(sourceContractAddress).startTraining(address(this), code);
        } 
    }

    
    function addToShares(address investor, uint256 ATNamount, uint256 /*ETHamount*/) 
        external
    {   
        require(msg.sender==sourceContractAddress, "only the source contract may change the shares");
        shares[investor] += ATNamount / pricePerShare;
        
    }
    

    function _reachedFundingGoal() internal view returns (bool) {
        if (projectStatus==status.investing && balanceATN()<fundingGoal){
            return false;
        }
        return true;
    }
    
    function tokensReceived ( address /*operator*/,
        address /*from*/,
        address /*to*/,
        uint256 /*amount*/,
        bytes calldata /*userData*/,
        bytes calldata /*operatorData*/
    ) external override {
        require(msg.sender == address(banu), "Invalid token");
        // ceva = "there you have it";
        // investors[from] = amount;
        // operator = from;
        //   like approve + transferFrom, but only one tx
    }

    // function payDividends()public{
    //     uint256 total=banu.balanceOf(address(this));
    //     for (uint256 i=0;i<shareholders.length;i++){
    //         // banu.transfer(shareholders[i]);
    //     }
    // }

    // modifier noSoonerThanDaily() {
    //     require(
    //         block.timestamp >= lastPayout + 86400,
    //         "Last payout was less than 24 hours ago."
    //     );
    //     _;
    // }

    // modifier hasAvailableShares() {
    //     require(availableShares > 0, "No available shares for this project");
    //     _;
    // }
    
    modifier onlyDeployerOrFounder() {
        require((msg.sender==founder || msg.sender==deployer), "You are neither the founder nor the deployer of this project.");
        _;
    }
    
}



    
contract User is IERC777Recipient{
    address public owner;
    MainToken banu;
    Source source;
    asset[] assets;
    subscription[] subscriptions;
    mapping(address => uint256) projectIds;
    uint256 public balanceInEscrow;
    enum subscriptionStatus {inactive, active}

    struct asset {
        address cine;
        uint256 ce;
    }
    
    struct subscription {
        address project;
        address escrow;
        uint256 tarif;
        subscriptionStatus status;
    }

    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH
        = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;
        
        
    constructor(address adresaLaBanu, address adresaLaOwner, address adresaLaSource) {
        require(msg.sender==adresaLaSource, 'only the source contract can deploy the user');
        owner = adresaLaOwner;
        source = Source(msg.sender);
        banu = MainToken(adresaLaBanu);
        
        _erc1820.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
    }
    

    function balanceETH() public view returns (uint256) {
        return address(this).balance;
    }

    function balanceATN() public view returns (uint256) {
        // this is the balance of this account plus the balance from the subscriptions
        return banu.balanceOf(address(this));
    }

    function getSubscriptionStatus(address project) public view returns (uint256) {
        return uint256(subscriptions[projectIds[project]].status);
    }
    // function getAssets() public view returns (asset[] memory) {
    //     return assets;
    // }
    
    function subscribe(address project, uint256 ATNamount, uint256 tarif) public onlyOwner {
        Project projectInstance = Project(project);
        projectInstance.subscribeFromUserAccount(ATNamount, tarif);
        
        projectIds[project] = subscriptions.length;  // TODO: Avoid creating two subscriptions for the same project
        subscriptions.push(subscription(project, projectInstance.getEscrow(), tarif, subscriptionStatus.active));
    }
    
    function unsubscribe(address project) public onlyOwner {
        subscriptions[projectIds[project]].status = subscriptionStatus.inactive;
        Project projectInstance = Project(project);
        projectInstance.unsubscribeFromUserAccount();
    }
    
    function requestEndpoint(address project) public view onlyOwner returns (string memory) {
        Project projectInstance = Project(project);
        return projectInstance.requestEndpoint(address(this));
    }

    function sellShares(address assetAddress, uint64 amount) public onlyOwner {
        for (uint8 i = 0; i < assets.length; i++) {
            if (assets[i].cine == assetAddress) {
                if (amount <= assets[i].ce) {
                    assets[i].ce = assets[i].ce - amount;
                }
            }
        }
    }
    
    
    function getBalanceInEscrow(address project) public returns (uint256){
        Project projectInstance = Project(project);
        return projectInstance.getWithdrawableBalanceUser(address(this));
        
    }
    
    function getBalanceFromAllEscrows() public onlyOwner returns(uint256) {
        uint256 _balanceInEscrow = 0;
        for (uint256 i=0; i<subscriptions.length; i++){
            if (subscriptions[i].status == subscriptionStatus.active){
                _balanceInEscrow += getBalanceInEscrow(subscriptions[i].project);
            }
        }
        balanceInEscrow = _balanceInEscrow;
        return _balanceInEscrow;
    }
    
    function getBalanceOnInstantUnsubscription() public onlyOwner returns(uint256){
        
        return getBalanceFromAllEscrows() + balanceATN();
    }
    
    function withdraw(uint256 amount) public onlyOwner {
        // should withdraw the remaining stuff that sits in escrow aswell.
        require(banu.transfer(owner, amount));
    }
    
    function withdrawAll() public onlyOwner {
        require(banu.transfer(owner, banu.balanceOf(address(this))));
    }
    
    function unsubscribeAll() public onlyOwnerOrThis {
        for (uint256 i=0; i<subscriptions.length; i++){
            unsubscribe(subscriptions[i].project);
        }    
    }
    
    function unsubscribeAllAndWithdraw() public onlyOwner {
        unsubscribeAll();
        withdrawAll();
    }
    

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the owner of the contract can call this function."
        );
        _;
    }
    
    modifier onlyOwnerOrThis() {
        require(
            msg.sender == owner || msg.sender == address(this),
            "onlyOwnerOrThis."
        );
        _;
    }

    function createProject(
        string memory _name,
        string memory _code,
        uint256 _fundingGoal
    ) public onlyOwner {
        address project = source.createProject(
            _name,
            _code,
            msg.sender,
            _fundingGoal
        );
        asset memory bun = asset(project, 70000);
        assets.push(bun);
    }
    
    function invest(address project, uint256 ATNamount) external {
        Project(project).invest(ATNamount);
    }
    
    
    function tokensReceived ( address /*operator*/,
        address /*from*/,
        address /*to*/,
        uint256 /*amount*/,
        bytes calldata /*userData*/,
        bytes calldata /*operatorData*/
    ) external override {
        // ceva = "there you have it";
        // investors[from] = amount;
        // operator = from;
        //   like approve + transferFrom, but only one tx
    }
    
}

contract Source is IERC777Sender, ERC1820Implementer {
    // SPDX-License-Identifier: MIT
    mapping(address => address) public users;
    // mapping(address => address) public projectEscrows;
    address public owner;
    MainToken banu;
    ProjectFactory projectFactory;
    // TokenFactory tokenFactory;
    address[] public projects;
    address public tokenAddress;
    uint256 sold;
    mapping(address => bool) private _isRegisteredProject;
    bytes32 constant private TOKENS_SENDER_INTERFACE_HASH =
        0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895;
    event StartTraining(address project, string repo);
    
    constructor() payable {
        sold = 0;
        owner = msg.sender;
        projectFactory = new ProjectFactory();
        // tokenFactory = new TokenFactory();
        banu = new MainToken();
        tokenAddress = address(banu);
        banu.imprima(1 * (10**6));
    }

    function clear() public {
        users[msg.sender] = 0x0000000000000000000000000000000000000000;
    }
    

    function getUser(address _owner) external view returns (address) {
        return users[_owner];
    }

    function registerHookForAccount(address account) public {
        _registerInterfaceForAddress(
            TOKENS_SENDER_INTERFACE_HASH,
            account
        );
    }
    
    function startTraining(address project, string memory repo) external {
        require(_isRegisteredProject[project], "Not registered Project");
        emit StartTraining(project, repo);
    }
    
    function tokensToSend(
        address /* operator */,
        address /*from*/,
        address /*to*/,
        uint256 /*amount*/,
        bytes calldata /*userData*/,
        bytes calldata /*operatorData*/
    ) external pure override {
        // do stuff
        // uint256 a = 1;
    }

    function allProjects() external view returns (address[] memory) {
        return projects;
    }

    // function addUser(address contractAddress, address userAddress) external {
    //     users[userAddress] = contractAddress;
    // }
    
    function createUser() external payable returns (address) {
        User user = new User(tokenAddress, msg.sender, address(this));
        users[msg.sender] = address(user);
        return address(user);
    }

    // function balanceETH() public view returns (uint256) {
    //     return address(this).balance;
    // }

    //https://www.youtube.com/watch?v=CVdZ09iqQj
    function balanceATN() public view returns (uint256) {
        return banu.balanceOf(address(this));
    }
    
    function balanceETH() external view returns (uint256) {
        return address(this).balance;
    }


    function createProject(
        string memory _name,
        string memory _code,
        address _founder,
        uint256 _fundingGoal
    ) external payable returns (address) {
        address project = projectFactory.createProject(address(banu),
            _name,
            _code,
            _founder,
            _fundingGoal);
        _registerProject(project);
        return project;
    }
    
    function _registerProject(address project) internal {
        projects.push(project);
        _isRegisteredProject[project] = true;
    }

    function invest(address investor, address project, uint256 ATNamount, uint256 ETHamount) external payable{
        
        banu.operatorSend(investor, project, ATNamount, "", "");
        
        uint256 ethValue = msg.value + ETHamount;
        bool success = true;
        if (ethValue>0){
            // also send the eth along with it 
            (success,  ) = payable(project).call{value: ethValue}("");
        }
        
        Project fundedProject = Project(project);
        fundedProject.addToShares(investor, ATNamount, (success ? ethValue : 0));

    }
    
    
    
    function subscribe(address user, address escrow, uint256 ATNamount) external {
        require(_isRegisteredProject[msg.sender], "only Projects!");
        banu.operatorSend(user, escrow, ATNamount, "", "");
    }
    
    function unsubscribe(address user, address escrow, address project, uint256 projectATNPayback, uint256 userATNPayback) external {
        require(_isRegisteredProject[msg.sender], "only Projects!");
        banu.operatorSend(escrow, user, userATNPayback, "", "");
        banu.operatorSend(escrow, project, projectATNPayback, "", "");
    }
    
    function withdrawFromEscrow(address escrow, uint256 ATNamount) external {
        banu.operatorSend(escrow, msg.sender, ATNamount, "", "");
    }

    function buy() external payable {
        uint256 cashu = msg.value * 1000;
        require(
            sold + cashu < banu.totalSupply(),
            "Supply limit reached."
        );
        require(cashu < 500 * (10**18), "< 500 ATN!");
        banu.transfer(msg.sender, cashu);
    }

    function sell(uint256 amount) external payable {
        banu.operatorSend(msg.sender, address(this), amount, "", "");
    }
    
    receive() external payable {} 
    
    
}

contract MainToken is ERC777 {
    address owner;
    address[] ops = [msg.sender];

    constructor() ERC777("AUTONET", "ATN", ops) {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the owner of the contract can call this function."
        );
        _;
    }

    function imprima(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount * (10**uint256(decimals())), "", "");
    }
}



contract Escrow is IERC777Recipient {

    // event Deposited(address indexed payee, uint256 weiAmount);
    // event Withdrawn(address indexed payee, uint256 weiAmount);
    address public tokenAddress;
    mapping(address => uint256) private _cumulativeDeposits;  // doesnt account for withdrawls so its useless, officially!
    
    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH
        = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;
    
    constructor (address adresaLaBanu) {
        _erc1820.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
        tokenAddress = adresaLaBanu;
    }

    function depositsOf(address payee) public view returns (uint256) {
        return _cumulativeDeposits[payee];
    }
    
    function ATNamount() public view returns (uint256) {
       MainToken banu = MainToken(tokenAddress);
       return banu.balanceOf(address(this));
    }

    
    function tokensReceived ( address /*operator*/,
        address from,
        address /*to*/,
        uint256 amount,
        bytes calldata /*userData*/,
        bytes calldata /*operatorData*/
    ) external override {
        
        _cumulativeDeposits[from] += amount;
        // emit Deposited( payee, amount);
    }
}

contract ProjectFactory {
    function createProject(address adresaLaBanu,
        string memory _name,
        string memory _code,
        address _founder,
        uint256 _fundingGoal) external returns (address) {
        return address(new Project(adresaLaBanu, msg.sender, _name, _code, _founder, _fundingGoal));
    }
}


contract TokenFactory {
        
    function createATN() external returns (MainToken) {
        MainToken banu = new MainToken();
        return banu;
    }
}

contract EscrowFactory {
        
    function createEscrow(address adresaLaBanu) external returns (address) {
        return address(new Escrow(adresaLaBanu));
    }
}
