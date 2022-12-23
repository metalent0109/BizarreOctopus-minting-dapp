//SPDX-License_Identifier: MIT

pragma solidity ^0.8.12;

//@author Crypto-Advice 

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract NFTERC721A is Ownable, ERC721A {

    using Strings for uint;

    enum Step {
        Before, 
        SpecialEvent,
        WhitelistSale, 
        PublicSale, 
        SoldOut, 
        Reveal
    }

    string public baseURI; 

    Step public sellingStep; 

    uint private constant MAX_SUPPLY = 555;
    uint private constant MAX_SPECIALEVENT = 3;
    uint private constant MAX_WHITELIST = 200; 
    uint private constant MAX_PUBLIC = 332; 
    uint private constant MAX_GIFT = 20; 

    uint public evSalePrice = 0.08 ether; 
    uint public wlSalePrice = 0.10 ether; 
    uint public publicSalePrice = 0.20 ether;

    bytes32 public merkleRoot; 

    uint public saleStartTime = 1668071400;
    uint public saleStartTime1;
    uint public saleStartTime2;



    mapping(address => uint) public amountNFTsperWalletSpecialEvent; 
    mapping(address => uint) public amountNFTsperWalletWhitelistSale; 

    uint private teamLength; 

    constructor(address [] memory _team, uint[] memory _teamShares, bytes32 _merkleRoot, string memory _baseURI) ERC721A ("Mountains Club", "MTNS") 
    
    PaymentSplitter(_team, _teamShares) {
        merkleRoot = _merkleRoot; 
        baseURI = _baseURI;
        teamLength = _team.Length;
    }

    function withdraw(address _addr) external onlyOwner { 
        //get the balance of the contract 
        uint256 balance = address(this).balance; 
        payable(_addr).transfer(balance); 
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function specialeventMint(address _account, uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        uint price = evSalePrice; 
        require(price != 0, "Price is 0"); 
        require(sellingStep == Step.SpecialEvent, "Whitelist Pre-Sale is not activated");
        require(currentTime() >= saleStartTime1, "Whitelist Pre-Sale has not started yet");
        require(currentTime() < saleStartTime1 + 300 minutes, "Whitelist Pre-Sale is finished");
        require(isWhiteListed(msg.sender, _proof), "Not whitelisted"); 
        require(amountNFTsperWalletSpecialEvent[msg.sender] + _quantity <= 1, "You can only get 1 NFT on this Whitelist Pre-Sale"); 
        require(totalSupply() + _quantity <= MAX_SPECIALEVENT, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enough funds");
        amountNFTsperWalletSpecialEvent[msg.sender] += _quantity; 
        _safeMint(_account, _quantity); 
    }

    function whitelistMint(address _account, uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        uint price = wlSalePrice; 
        require(price != 0, "Price is 0"); 
        require(sellingStep == Step.WhitelistSale, "Whitelist Sale is not activated");
        require(currentTime() >= saleStartTime2, "Whitelist Sale has not started yet");
        require(isWhiteListed(msg.sender, _proof), "Not whitelisted"); 
        require(amountNFTsperWalletWhitelistSale[msg.sender] + _quantity <= 2, "You can only get 2 NFTs on this Whitelist Sale"); 
        require(totalSupply() + _quantity <= MAX_WHITELIST, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enough funds");
        amountNFTsperWalletWhitelistSale[msg.sender] += _quantity; 
        _safeMint(_account, _quantity); 
    }

    function publicSaleMint(address _account, uint _quantity) external payable callerIsUser {
        uint price = publicSalePrice;
        require(price != 0, "Price is 0");
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(totalSupply() + _quantity <= MAX_WHITELIST + MAX_PUBLIC + MAX_SPECIALEVENT, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enough funds"); 
        _safeMint(_account, _quantity);
    }

    function gift(address _to, uint _quantity) external onlyOwner {
        require(sellingStep > Step.SoldOut, "Gift is after the public sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max Supply");
        _safeMint(_to, _quantity); 
    }

    function setSaleStartTime1(uint _saleStartTime1) external onlyOwner {
        saleStartTime1 = _saleStartTime1;
    }

    function setSaleStartTime2(uint _saleStartTime2) external onlyOwner {
        saleStartTime2 = _saleStartTime2; 
    }

    function currentTime() internal view returns(uint) {
        return block.timestamp; 
    }

    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step); 
    }

    //Whitelist
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot; 
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof) internal view returns(bool) {
        return _verify(leaf(_account), _proof); 
    }

    function leaf(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf); 
    }

    }