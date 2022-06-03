// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
//security against transaction for multiple requests
import "hardhat/console.sol";

contract KBMarket is ReentrancyGuard{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _tokensSold;
    address payable owner;
    //we are deploying to matic the API is the same so u can use ether the same way
    uint256 listingPrice=0.045 ether;
    constructor(){
        owner=payable(msg.sender);
    }
    struct MarketToken{
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }
    mapping(uint256 => MarketToken) private idToMarketToken;
    event MarketTokenMinted(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    function getListingPrice() public view returns (uint256){
        return listingPrice;
    }

    function makeMarketItem(
        address nftContract,
        uint tokenId,
        uint price
    )
    public payable nonReentrant{
        require(price>0, 'Price must be at least one wei');
        require(msg.value==listingPrice,'Price must be equal to listing price');

        _tokenIds.increment();
        uint itemId = _tokenIds.current();

        idToMarketToken[itemId]=MarketToken(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );
        //NFT transaction
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketTokenMinted(
        itemId,
        nftContract,
        tokenId,
        msg.sender,
        address(0),
        price,
        false
        );
    }

        //fxn to conduct transaction and market sales
        function createMarketSale(
            address nftContract,
            uint itemId)
            public payable nonReentrant{
                uint price=idToMarketToken[itemId].price;
                uint tokenId =idToMarketToken[itemId].tokenId;
                require(msg.value==price,'Please submit the asking price in order to continue');
                //transfer the amt to the seller
                idToMarketToken[itemId].seller.transfer(msg.value);
                //transfer the token from contract address to the buyer
                IERC721(nftContract).transferFrom(address(this),msg.sender, tokenId);
                idToMarketToken[itemId].owner=payable(msg.sender);
                idToMarketToken[itemId].sold=true;
                _tokensSold.increment();

                payable(owner).transfer(listingPrice);  
            }
        
        // fxn to fetchMarketItems-minting, buying

        function fetchMarketTokens() public view returns(MarketToken[] memory){
            uint itemCount=_tokenIds.current();
            uint unsoldItemCount= _tokenIds.current() - _tokensSold.current();
            uint currentIndex =0;

            //looping over the num of items created if num has not been sold
            MarketToken[] memory items= new MarketToken[](unsoldItemCount);
            for(uint i=0;i<itemCount;i++){
                if(idToMarketToken[i+1].owner ==address(0)){
                    uint currentId=i+1;
                    MarketToken storage currentItem=idToMarketToken[currentId];
                    items[currentIndex]=currentItem;
                    currentIndex +=1;
                }
            }
            return items;
        }
        //user has purchased
        function fetchMyNFTs() public view returns (MarketToken[] memory){
              uint totalItemCount= _tokenIds.current();
              uint itemCount=0;
              uint currentIndex=0;
              for(uint i=0;i<totalItemCount;i++){
                  if(idToMarketToken[i+1].owner==msg.sender){
                      itemCount +=1;
                  }
              }
              MarketToken[] memory items=new MarketToken[](itemCount);
              for(uint i=0;i<totalItemCount;i++){
                  if(idToMarketToken[i+1].owner==msg.sender){
                      uint currentId=idToMarketToken[i+1].itemId;

                      MarketToken storage currentItem= idToMarketToken[currentId];
                      items[currentIndex]=currentItem;
                      currentIndex+=1;
                  }
              } 
              return items;     
        }

        //fxn for returning an arra of minted nfts
        function fetchItemsCreated() public view returns(MarketToken[] memory){
            uint totalItemCount= _tokenIds.current();
            uint itemCount=0;
            uint currentIndex=0;

            for(uint i=0;i<totalItemCount;i++){
                  if(idToMarketToken[i+1].seller==msg.sender){
                      itemCount +=1;
                  }
              }
              MarketToken[] memory items=new MarketToken[](itemCount);
              for(uint i=0;i<totalItemCount;i++){
                  if(idToMarketToken[i+1].seller==msg.sender){
                      uint currentId=idToMarketToken[i+1].itemId;

                      MarketToken storage currentItem= idToMarketToken[currentId];
                      items[currentIndex]=currentItem;
                      currentIndex+=1;
                  }
              }
              return items;
        }
}