pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

contract Agent is ERC721{
    uint public nextTokenId;
    address public admin;
    constructor()ERC721('Autonet Project','ATP'){
        admin=msg.sender;
    }
    function mint(address to)external{
        require(msg.sender==admin,'only admin');
        _safeMint(to,nextTokenId);
        nextTokenId++;
    }
    function _baseURI() internal view override returns (string memory)
    {return "https://us-central1-afterme-850af.cloudfunctions.net/NFT/";}
}

contract Project{
    Agent model;
    string code;
    string public picurl;
    string public category;
    string public name;
    string public description;
    string public catpicgit;
    MainToken banu;
    bool mature=false;
    mapping(address=>uint256) public shareholders;
    uint256 public spentOnTraining;
    uint256 public avilableShares=930000;
    uint256 initialTrainingCost=1547000000000000000;
    uint256 pricePerShare;
    uint256 lastPayout;
    constructor(
        address adresaLaBanu, 
        string memory _name,
        string memory _code,
        string memory _description,
        string memory _picurl,
        string memory _category,
        address founder)
        payable{
        banu=MainToken(adresaLaBanu);
        pricePerShare=initialTrainingCost/930000;
        name=_name;
        code=_code;
        category=_category;
        description=_description;
        picurl=_picurl;
        shareholders[founder]=70000;
        catpicgit=append(category,picurl,code);
    }
    
    function balanceATN() public view returns (uint256){
        return banu.balanceOf(address(this));
    }
    function balanceETH()public view returns(uint256){
        return address(this).balance;
    }
    
    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {
    return string(abi.encodePacked(a, b, c));
    }
    
    function details() public view returns (string memory,string memory,string memory){
        return (name,description,catpicgit);
    }
    
    function invest(uint256 amount)public payable hasAvailableShares{
        require(amount/pricePerShare<=avilableShares,"Can't buy more than he available shares");
        banu.transferFrom(msg.sender, address(this),amount);
        if (shareholders[msg.sender]>0){
            shareholders[msg.sender]=shareholders[msg.sender]+amount/pricePerShare;
        }
    }
    
    // function payDividends()public{
    //     uint256 total=banu.balanceOf(address(this));
    //     for (uint256 i=0;i<shareholders.length;i++){
    //         // banu.transfer(shareholders[i]);
    //     }
    // }
    
    modifier noSoonerThanDaily() {
        require(block.timestamp >= lastPayout + 86400,"Last payout was less than 24 hours ago.");
        _;
    }
    
    modifier hasAvailableShares(){
    require (avilableShares>0,"No available shares for this project");
    _;
    }
}

contract User{
    address public owner;
    MainToken banu;
    Source source;
    asset[] assets;
    
    constructor(address adresaLaBanu,address adresaLaOwner){
        owner=adresaLaOwner;
        source=Source(msg.sender);
        banu=MainToken(adresaLaBanu);
    }

    struct asset{
        address cine;
        uint ce;
    }
    
    function balanceETH()public view returns(uint256){
        return address(this).balance;
    }
    
    function balanceATN() public view returns(uint256){
        return banu.balanceOf(address(this));
    }
    
    
    function getAssets()view public returns (asset[] memory){
     return assets;
    }
    
    function sellShares(address assetAddress, uint64 amount)public onlyOwner{
    
        for (uint8 i=0;i<assets.length;i++){
            if (assets[i].cine==assetAddress){
                if(amount<=assets[i].ce){
                    assets[i].ce=assets[i].ce-amount;
                }
            }
            
        }
    }
    
    function withdraw(uint256 amount) public onlyOwner{
        require(banu.transfer(owner,amount));
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner,"Only the owner of the contract can call this function.");
        _;
    }
    
    function createProject(
        string memory _name,
        string memory _description,
        string memory _code,
        string memory _iconurl,
        string memory _category
        )
    public onlyOwner {
        address project=source.createProject(_name,_description,_code,_iconurl,_category);
        asset memory bun=asset(address(project),70000);
        assets.push(bun);
    }
}

contract Source is IERC777Recipient{
    string public ceva="nu stiu";
    mapping(address=>address) public users;
    address public sefu;
    MainToken banu;
    address[] public projects;
    uint256 initialPrice=1000000000000000;
    address public tokenAddress;
    uint256 sold;
    constructor(){
        sold=0;
        sefu=msg.sender;
        banu=new MainToken();
        tokenAddress=address(banu);
        banu.imprima(1000000);
    }
    
    function clear()public{
        users[msg.sender]=0x0000000000000000000000000000000000000000;
    }
    
    function tokensReceived(address operator,
        address from,
        address /*to*/,
        uint256 amount,
        bytes calldata /*userData*/,
        bytes calldata /*operatorData*/
    ) external override {
        require(msg.sender == address(banu), "Invalid token");
        ceva="na ca am trimis";
        //   like approve + transferFrom, but only one tx
    }

    
    function allProjects() public view returns(address[] memory)  {
        return projects;
    }
    
    function createUser()public payable returns(address){
        User user=new User(tokenAddress,msg.sender);
        users[msg.sender]=address(user);
        return address(user);
    }

    
    function balanceETH()public view returns(uint256){
        return address(this).balance;
    }
    //https://www.youtube.com/watch?v=CVdZ09iqQj
    function balanceATN() public view returns(uint256){
        return banu.balanceOf(address(this));
    }
    
    function createProject(
        string memory _name,
        string memory _description,
        string memory _code,
        string memory _iconurl,
        string memory _category
        )public payable returns(address){
            Project project=new Project(address(banu),_name,_code,_description,_iconurl,_category,address(msg.sender));
            projects.push(address(project));
            return(address(project));
        }

    function buy()public payable {
        uint256 cashu=msg.value*1000;
        require(sold+cashu<banu.totalSupply(),
        "Total supply limit was reached. Trade amongst yourselves now.");
        require(cashu<500000000000000000000, "Can't buy more than 500 ATN.");
        banu.transfer(msg.sender,cashu);
    }
    
    function sell(uint256 amount)public payable{
        banu.operatorSend(msg.sender,address(this),amount,"asda","asd");
    }
}

    contract MainToken is ERC777 {
        address owner;
        address[] ops=[msg.sender];
        
    constructor ()  ERC777("AUTONET", "ATN",ops) {
        owner=msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"Only the owner of the contract can call this function.");
        _;
    }
    
    function imprima(uint256 amount)public onlyOwner{
         _mint(msg.sender, amount * (10 ** uint256(decimals())),"","");
    }
}


