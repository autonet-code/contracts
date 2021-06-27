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

    constructor() ERC721("Autonet Project", "ATP") {
        admin = msg.sender;
    }

    function mint(address to) external {
        require(msg.sender == admin, "only admin");
        _safeMint(to, nextTokenId);
        nextTokenId++;
    }

    function _baseURI() internal pure returns (string memory) {
        return "https://us-central1-afterme-850af.cloudfunctions.net/NFT/";
    }
}

contract Project is IERC777Recipient{
    Agent model;
    string code;
    string public picurl;
    string public category;
    string public name;
    string public description;
    string public catpicgit;
    MainToken banu; 
    Source source;
    address sourceContractAddress;
    bool mature = false;
    mapping(address => uint256) public shareholders;
    uint256 public spentOnTraining;
    uint256 public availableShares = 930000;
    uint256 initialTrainingCost = 1547000000000000000;
    uint256 pricePerShare;
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
        string memory _description,
        string memory _picurl,
        string memory _category,
        address founder
    ) payable {
        banu = MainToken(adresaLaBanu);
        sourceContractAddress = adresaLaSource;
        source = Source(adresaLaSource);
        
        _erc1820.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
        
        pricePerShare = initialTrainingCost / 930000;
        name = _name;
        code = _code;
        category = _category;
        description = _description;
        picurl = _picurl;
        shareholders[founder] = 70000;
        catpicgit = append(category, picurl, code);
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

    function details()
        public
        view
        returns (
            string memory,
            string memory,
            string memory
        )
    {
        return (name, description, catpicgit);
    }

    function invest(uint256 ATNamount) public payable hasAvailableShares {
        require(
            ATNamount / pricePerShare <= availableShares,
            "Can't buy more than he available shares"
        );
        // banu.transferFrom(msg.sender, address(this), amount);
        source.registerHookForAccount(msg.sender);
        source.invest(msg.sender, address(this), ATNamount, msg.value);
        // if (shareholders[msg.sender] > 0) {
        //     shareholders[msg.sender] = shareholders[msg.sender] + uint256(ATNamount / pricePerShare);
        // }
    }

    
    function addToShares(address investor, uint256 ATNamount, uint256 ETHamount) 
        external
    {   
        require(msg.sender==sourceContractAddress, "only the source contract may change the shares");
        shareholders[investor] += ATNamount / pricePerShare;
        
    }
    

    function tokensReceived(
        address operator,
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
    
}

contract User {
    address public owner;
    MainToken banu;
    Source source;
    asset[] assets;

    constructor(address adresaLaBanu, address adresaLaOwner, address adresaLaSource) {
        owner = adresaLaOwner;
        if (msg.sender==adresaLaSource){
            source = Source(msg.sender);
        } else {
            source = Source(adresaLaSource);
            source.addUser(msg.sender);
        }
        
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
        string memory _description,
        string memory _code,
        string memory _iconurl,
        string memory _category
    ) public onlyOwner {
        address project = source.createProject(
            _name,
            _description,
            _code,
            _iconurl,
            _category
        );
        asset memory bun = asset(address(project), 70000);
        assets.push(bun);
    }
}

contract Source is IERC777Sender, ERC1820Implementer {
    // SPDX-License-Identifier: MIT
    string public ceva = "nu stiu";
    mapping(address => address) public users;
    address public sefu;
    MainToken banu;
    address[] public projects;
    uint256 initialPrice = 1000000000000000;
    address public tokenAddress;
    mapping(address => uint256) investors;
    uint256 sold;
    
    // TODO: DELETE THE FOLLOWING TWO ATTRIBUTES
    uint256 public _tokenFirstSentAmount;
    bytes public _userData;

    bytes32 constant private TOKENS_SENDER_INTERFACE_HASH =
        0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895;
    
    constructor() {
        sold = 0;
        sefu = msg.sender;
        banu = new MainToken();
        tokenAddress = address(banu);
        banu.imprima(1000000);
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
    

    // function tokensReceived(
    //     address operator,
    //     //NOT THE RIGHT IMPLEMENTATION. JUST PATCHED ERRORS
    //     address from,
    //     address, /*to*/
    //     uint256 amount,
    //     bytes calldata, /*userData*/
    //     bytes calldata /*operatorData*/
    // ) external override {
    //     require(msg.sender == address(banu), "Invalid token");
    //     ceva = "there you have it";
    //     investors[from] = amount;
    //     operator = from;
    //     //   like approve + transferFrom, but only one tx
    // }
    
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

    function addUser(address user) external {
        users[user] = msg.sender;
    }
    
    function createUser() public payable returns (address) {
        User user = new User(tokenAddress, msg.sender, address(this));
        users[msg.sender] = address(user);
        return address(user);
    }

    function balanceETH() public view returns (uint256) {
        return address(this).balance;
    }

    //https://www.youtube.com/watch?v=CVdZ09iqQj
    function balanceATN() public view returns (uint256) {
        return banu.balanceOf(address(this));
    }

    function createProject(
        string memory _name,
        string memory _description,
        string memory _code,
        string memory _iconurl,
        string memory _category
    ) public payable returns (address) {
        Project project = new Project(
            address(banu),
            address(this),
            _name,
            _code,
            _description,
            _iconurl,
            _category,
            address(msg.sender)
        );
        projects.push(address(project));
        return (address(project));
    }

    function invest(address investor, address project, uint256 ATNamount, uint256 ETHamount) public payable returns (bool){
        
        banu.operatorSend(investor, project, ATNamount, "hallo", "auto");
        
        uint256 ethValue = msg.value + ETHamount;
        bool success = true;
        if (ethValue>0){
            // also send the eth along with it 
            (success,  ) = payable(project).call{value: ethValue}("");
        }
        
        Project fundedProject = Project(project);
        uint256 investedETH = (success ? ethValue : 0);
        fundedProject.addToShares(investor, ATNamount, investedETH);
        
        return true;
    }

    function buy() public payable {
        uint256 cashu = msg.value * 1000;
        require(
            sold + cashu < banu.totalSupply(),
            "Total supply limit was reached. Trade amongst yourselves now."
        );
        require(cashu < 500000000000000000000, "Can't buy more than 500 ATN.");
        banu.transfer(msg.sender, cashu);
    }

    function sell(uint256 amount) public payable {
        banu.operatorSend(msg.sender, address(this), amount, "asda", "asd");
    }
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
