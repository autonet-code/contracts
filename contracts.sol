
pragma solidity ^0.7.0;
// SPDX-License-Identifier: MIT
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
// // import "@openzeppelin/contracts/introspection/IERC1820Implementer.sol";
// // import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC1820Implementer.sol";
// // import "http://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.1-solc-0.7/contracts/introspection/ERC1820Implementer.sol";
// // import "http://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.1-solc-0.7/contracts/introspection/IERC1820Registry.sol";
// import "@openzeppelin/contracts/introspection/IERC1820Registry.sol";
import "http://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.1-solc-0.7/contracts/token/ERC721/ERC721.sol";
import "http://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.1-solc-0.7/contracts/token/ERC777/ERC777.sol";
import "http://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.1-solc-0.7/contracts/token/ERC777/IERC777Sender.sol";
import "http://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.1-solc-0.7/contracts/token/ERC777/IERC777Recipient.sol";
import "http://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.1-solc-0.7/contracts/introspection/ERC1820Implementer.sol";
import "http://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.1-solc-0.7/contracts/introspection/IERC1820Registry.sol";

//https://soliditydeveloper.com/erc-777
contract Agent is ERC721 {
    uint256 public nextTokenId;
    address public admin;
    address public project;   // shall the admin be the project. For now: Yes!
    string private endpoint;
    
    constructor() ERC721("Autonet Project", "ATP") {
        admin = msg.sender;
        project = admin;
    }

    function mint(address to) external {
        require(msg.sender == admin, "only admin");
        _safeMint(to, nextTokenId);
        nextTokenId++;
    }
    
    function getEndpoint() external view returns(string memory) {
        require(msg.sender==project, "only the parent Preoject can get the endpoint for this token");
        return endpoint;
    }
    
    function setEndpoint(string memory _endpoint) external returns(bool) {
        require(msg.sender==project, "only the parent Preoject can get the endpoint for this token");
        endpoint = _endpoint;
        return true;
    }

    function _baseURI() internal pure returns (string memory) {
        return "https://us-central1-afterme-850af.cloudfunctions.net/NFT/";
    }
}

contract Project is IERC777Recipient{
    Agent model;
    string code;
    string public name;
    string private endpoint;
    MainToken banu; 
    Source source;
    address payable sourceContractAddress;
    
    enum status { investing, training, validating, mature}
    status projectStatus;
    address founder;
    address deployer;
    mapping(address => uint256) public shares;
    uint256 public spentOnTraining;
    uint256 public availableShares = 930 * (10**3);
    uint256 public founderShares = 70 * (10**3);
    uint256 public initialTrainingCost = 1547 * (10**15);
    uint256 public pricePerShare = initialTrainingCost / availableShares;
    uint256 public fundingGoal;
    uint256 public founderDividendPermille;
    
    mapping(address => uint256) public subscription;  // ATNbalance
    uint256 lastPayout;

    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH
        = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;
        
    mapping(address => uint256) private _balances;
    
    constructor(
        address adresaLaBanu,
        address adresaLaSource,
        string memory _name,
        string memory _code,
        address _founder,
        uint256 _fundingGoal,
        uint256 _founderDividendPermille
    ) payable {
        banu = MainToken(adresaLaBanu);
        sourceContractAddress = payable(adresaLaSource);
        source = Source(sourceContractAddress);
        founder = _founder;
        founderDividendPermille = _founderDividendPermille;
        fundingGoal = _fundingGoal;
        projectStatus = _reachedFundingGoal() ? status.training : status.investing; 
        
        deployer = msg.sender;
        name = _name;
        code = _code;
        shares[founder] = founderShares;
        
        _erc1820.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
        
    }

    
    function changeCodeUrl(string memory url) external onlyDeployerOrFounder {
        code = url;
    }
    
    function transferFoundership(address newFounder) external onlyDeployerOrFounder {
        founder = newFounder;
    }
    
    function completeTraining(string memory api) public {
        if (projectStatus == status.training){
            projectStatus = status.validating;
            // now starts the validation. 
            // here we just declare validation completed
            endpoint=api;
            completeValidation();
        }
    }
    
    function completeValidation() public {
        if (projectStatus == status.validating){
            projectStatus = status.mature;
            model = new Agent();
            model.mint(address(this));
            model.setEndpoint(endpoint);
        }
    }
    
    function subscribe(uint256 ATNamount) external payable {
        // maybe invest can be changed in the future
        source.invest(msg.sender, address(this), ATNamount, msg.value);
        subscription[msg.sender] += ATNamount;
    }
    
    function requestEndpoint() external returns (string memory) {
        require(subscription[msg.sender]>0, "not enough funds in your subscription!");
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

    


    function invest(uint256 ATNamount) public payable hasAvailableShares {
        require(
            ATNamount / pricePerShare <= availableShares,
            "Can't buy more than he available shares"
        );
        source.registerHookForAccount(msg.sender);
        source.invest(msg.sender, address(this), ATNamount, msg.value);
        if (_reachedFundingGoal()){
            projectStatus = status.training;
            source.startTraining(address(this), code);
        } 
    }

    
    function addToShares(address investor, uint256 ATNamount, uint256 ETHamount) 
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
    
    function tokensReceived ( address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
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

    modifier noSoonerThanDaily() {
        require(
            block.timestamp >= lastPayout + 86400,
            "Last payout was less than 24 hours ago."
        );
        _;
    }

    modifier hasAvailableShares() {
        require(availableShares > 0, "No available shares for this project");
        _;
    }
    
    modifier onlyDeployerOrFounder() {
        require((msg.sender==founder || msg.sender==deployer), "You are neither the founder nor the deployer of this project.");
        _;
    }
    
}

contract User {
    address public owner;
    MainToken banu;
    Source source;
    asset[] assets;

    constructor(address adresaLaBanu, address adresaLaOwner, address adresaLaSource) {
        require(msg.sender==adresaLaSource, 'only the source contract can deploy the user');
        owner = adresaLaOwner;
        source = Source(msg.sender);
        banu = MainToken(adresaLaBanu);
    }

    struct asset {
        address cine;
        uint256 ce;
    }

    function balanceETH() public view returns (uint256) {
        return address(this).balance;
    }

    function balanceATN() public view returns (uint256) {
        return banu.balanceOf(address(this));
    }

    // function getAssets() public view returns (asset[] memory) {
    //     return assets;
    // }

    function sellShares(address assetAddress, uint64 amount) public onlyOwner {
        for (uint8 i = 0; i < assets.length; i++) {
            if (assets[i].cine == assetAddress) {
                if (amount <= assets[i].ce) {
                    assets[i].ce = assets[i].ce - amount;
                }
            }
        }
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(banu.transfer(owner, amount));
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the owner of the contract can call this function."
        );
        _;
    }

    function createProject(
        string memory _name,
        string memory _code,
        uint256 _fundingGoal,
        uint256 _founderDividendPermille
    ) public onlyOwner {
        address project = source.createProject(
            _name,
            _code,
            _fundingGoal,
            _founderDividendPermille
        );
        asset memory bun = asset(address(project), 70000);
        assets.push(bun);
    }
}

contract Source is IERC777Sender, ERC1820Implementer {
    // SPDX-License-Identifier: MIT
    mapping(address => address) public users;
    address public owner;
    MainToken banu;
    address[] public projects;
    address public tokenAddress;
    // mapping(address => uint256) investors;
    uint256 sold;
    
    mapping(address => bool) private _isRegisteredProject;
    bytes32 constant private TOKENS_SENDER_INTERFACE_HASH =
        0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895;
    
    
    event StartTraining(address project, string repo);
    
    constructor() payable {
        sold = 0;
        owner = msg.sender;
        banu = new MainToken();
        tokenAddress = address(banu);
        banu.imprima(1 * (10**6));
    }

    function clear() public {
        users[msg.sender] = 0x0000000000000000000000000000000000000000;
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
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        // do stuff
        uint256 a = 1;
    }

    function allProjects() public view returns (address[] memory) {
        return projects;
    }

    // function addUser(address contractAddress, address userAddress) external {
    //     users[userAddress] = contractAddress;
    // }
    
    function createUser() public payable returns (address) {
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
    
    function balanceETH() public view returns (uint256) {
        return address(this).balance;
    }


    function createProject(
        string memory _name,
        string memory _code,
        uint256 _fundingGoal,
        uint256 _founderDividendPermille
    ) public payable returns (address) {
        Project project = new Project(
            address(banu),
            address(this),
            _name,
            _code,
            address(msg.sender),
            _fundingGoal,
            _founderDividendPermille            
        );
        _registerProject(address(project));
        return (address(project));
    }
    
    function _registerProject(address project) internal {
        projects.push(project);
        _isRegisteredProject[project] = true;
    }

    function invest(address investor, address project, uint256 ATNamount, uint256 ETHamount) public payable{
        
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

    function buy() public payable {
        uint256 cashu = msg.value * 1000;
        require(
            sold + cashu < banu.totalSupply(),
            "Total supply limit was reached. Trade amongst yourselves now."
        );
        require(cashu < 500 * (10**18), "Can't buy more than 500 ATN.");
        banu.transfer(msg.sender, cashu);
    }

    function sell(uint256 amount) public payable {
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