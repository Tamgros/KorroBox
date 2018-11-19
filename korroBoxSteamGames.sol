pragma solidity 0.4.24;

import "./DetailedERC721.sol";
import "./SafeMath.sol";
import "./strings.sol";


interface Marketplace {
  function receiveApproval(address _from, uint256 _tokenId, address _tokenAddr, uint8 _listType, uint _price) external;
}


/**
 * @title korroBoxSteamGames
 *
 * Generic implementation for both required and optional functionality in
 * the ERC721 standard for non-fungible tokens.
 *
 * Heavily inspired by Decentraland's generic implementation:
 * https://github.com/decentraland/land/blob/master/contracts/BasicNFT.sol
 *
 * Standard Author: dete
 * Implementation Author: Nadav Hollander <nadav at dharma.io>
 */
 // TODO: change this name as it breaks from the ERC721 standard
contract korroBoxSteamGames is DetailedERC721 {
    using SafeMath for uint;
    using strings for *;

    string public name;
    string public symbol;

    uint public numTokensTotal;
    uint public maxTokenSupply;

    uint public purchaseWindowInBlocks;

    address korroBox;
    address korroBoxPayable;

    address gameDevAddress;
    address gameDevPayable;

    bool public transferable;

    mapping(uint => address) internal tokenIdToOwner;
    mapping(uint => address) internal tokenIdToApprovedAddress;
    mapping(uint => string) internal tokenIdToMetadata;
    mapping(address => uint[]) internal ownerToTokensOwned;
    mapping(uint => uint) internal tokenIdToOwnerArrayIndex;

    /*
    * @dev initiates the korroAsset contract
    * @param _name The name of the asset
    * @param _symbol Smaller (3 or 4 char) signifier for the asset
    * @param _limit Max amount of this type of asset that can exist
    * @param _transferable If players can trade/sell this
    * @param _korroBoxPayable Where payments to KorroBox are sent
    * @param _gameDevAddress Dev ownership address
    * @param _gameDevPayable
    */
    constructor (
        string _name,
        string _symbol,
        uint _limit,
        bool _transferable,
        address _korroBoxPayable,
        address _gameDevAddress,
        address _gameDevPayable
      )
        public
      {
        name = _name;
        symbol = _symbol;
        maxTokenSupply = _limit;
        transferable = _transferable;
        korroBox = msg.sender;
        korroBoxPayable = _korroBoxPayable;
        gameDevAddress = _gameDevAddress;
        gameDevPayable = _gameDevPayable;

        numTokensTotal = 0;
        purchaseWindowInBlocks = 50;

      }

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 _tokenId
    );

    event Mint(
        address indexed _to,
        uint256 indexed _tokenId
    );


    modifier onlyExtantToken(uint _tokenId) {
        require(ownerOf(_tokenId) != address(0));
        _;
    }

    modifier onlyNonexistentToken(uint _tokenId) {
        require(tokenIdToOwner[_tokenId] == address(0));
        _;
    }

    modifier onlyKorro() {
        require(msg.sender == korroBox);
        _;
    }

    modifier onlyGameDev() {
      require(msg.sender == gameDevAddress);
      _;
    }

    modifier eitherKorroOrDev() {
      require(msg.sender == gameDevAddress || msg.sender == korroBox);
      _;
    }

    modifier canTransfer(uint256 _tokenId) {
      require(msg.sender == ownerOf(_tokenId) ||
               msg.sender == _getApproved(_tokenId));

      // KorroBox can transfer no matter even if the tokens aren't transferrable
      // but only if KorroBox is the owner of the token or approved
      require((transferable == true) || (msg.sender == korroBox));
      _;
    }

    /*
    * @dev Return the name of the tokenized asset.
    */
    function name()
        public
        view
        returns (string _name)
    {
        return name;
    }

    /*
    * @dev Returns the symbol of the tokenized asset.
    * @return string The symbol of the tokenized asset.
    */
    function symbol()
        public
        view
        returns (string _symbol)
    {
        return symbol;
    }

    /*
    * @dev Returns the number of tokens minted in this contract.
    * @reutn uint258 number of tokens that have been minted.
    */
    function totalSupply()
        public
        view
        returns (uint256 _totalSupply)
    {
        return numTokensTotal;
    }

    /*
    * @dev Returns the maximum number of tokens able to be minted by this congract.
    * @return uint256 The max number of tokens able to be minted by this contract.
    */
    function maxSupply()
        public
        view
        returns (uint256 _maxSupply)
    {
        return maxTokenSupply;
    }

    /*
    * @dev Returns true if the tokens in this contract are transferable.
    * @return bool True if the tokens in this contract are transferable.
    */
    function thisIsTransferable()
      public
      view
      returns (bool)
    {
      return transferable;
    }

    /*
    * @dev Returns KorroBox's address.
    * @return Address of KorroBox.
    */
    function getKorroBoxAddress()
      public
      view
      returns (address)
    {
      return korroBox;
    }

    /*
    * @dev Returns the address that payments to KorroBox go to.
    * @return Address where payments to KorroBox go to.
    */
    function getKorroBoxAddressPayable()
      public
      view
      returns (address)
    {
      return korroBoxPayable;
    }

    /*
    * @dev Changes the amount of blocks that the signature for purchase is valid
    * @param _old_purchaseWindowInBlocks number of blocks the signature was valid for
    * @param _new_purchaseWindowInBlocks new number of blocks the signature will be valid for
    */
    function changeBlockWaitTime(uint _old_purchaseWindowInBlocks, uint _new_purchaseWindowInBlocks)
      public
      onlyKorro()
    {
      require(_old_purchaseWindowInBlocks == purchaseWindowInBlocks);
      purchaseWindowInBlocks = _new_purchaseWindowInBlocks;
    }

    /*
    * @dev Changes KorroBox's address. Only KorroBox can do this.
    * @param _newAddress The address that KorroBox's address will be changed to
    */
    function changeKorroBoxAddress(address _newAddress)
      public
      onlyKorro()
    {
      korroBox = _newAddress;
    }

    /*
    * @dev Change's the address that payments to KorroBox go to.
    * @notice Only the KorroBox address can exectue this function.
    * @param _newAddress The address that KorroBox's payable address will be changed to
    */
    function changekorroBoxPayable(address _newAddress)
      public
      onlyKorro()
    {
      korroBoxPayable = _newAddress;
    }

    /*
    * @dev Returns the address of the Game Developer who developed the digital asset.
    */
    function getGameDevAddress()
      public
      view
      returns (address)
    {
      return gameDevAddress;
    }

    /*
    * @dev Returns the address that payments to the Game Developer go to.
    */
    function getGameDevAddressPayable()
      public
      view
      returns (address)
    {
      return gameDevPayable;
    }

    /*
    * @dev Change's the Game Developer's address.
    * @notice Only the KorroBox or Game Developer Addresses can exectue this function.
    * @param _newAddress The address that the Game Developer's address will be changed to
    */
    function changeGameDevAddress(address _newAddress)
      public
      eitherKorroOrDev()
    {
      gameDevAddress = _newAddress;
    }

    /*
    * @dev Change's the address that payments to the Game Developer go to.
    * @notice Only the KorroBox or Game Developer Addresses can exectue this funciton.
    * @param _newAddress The address that The Game Developer's payable address will be changed to
    */
    function changeGameDevAddressPayable(address _newAddress)
      public
      eitherKorroOrDev()
    {
      gameDevPayable = _newAddress;

    }

    /*
    * @dev Change's maximumum ammount of tokens that can be minted by this contracts
    * @notice Only KorroBox can execute this function
    * @param _newAddress The address that KorroBox's payable address will be changed to
    */
    function increaseMaxTokens(uint by )
      public
      onlyKorro()
      returns (uint)
    {
      require(msg.sender == korroBox);
      maxTokenSupply = maxTokenSupply + by;
      return maxTokenSupply;
    }

    /*
    * @dev Returns the number of tokens owned by a provided address
    * @param _owner The address that this function will return the balance of
    * @return uint The number of tokens owned by _owner
    */
    function balanceOf(address _owner)
        public
        view
        returns (uint _balance)
    {
        return ownerToTokensOwned[_owner].length;
    }

    /*
    * @dev Returns the owner of a provided token
    * @param _tokenId The token to find the owner of
    * @return address The address that owns the _tokenId
    */
    function ownerOf(uint _tokenId)
        public
        view
        returns (address _owner)
    {
        return _ownerOf(_tokenId);
    }

    /*
    * @dev Returns the metadata associated with a provided token Id.
    * @param _tokenId Token to find the metadata associated with it.
    * @return string Metadata associated with _tokenId
    */
    function tokenMetadata(uint _tokenId)
        public
        view
        returns (string _infoUrl)
    {
        return tokenIdToMetadata[_tokenId];
    }

    /*
    * @dev Approve an address to change the state of a given token.
    * @notice The token must be owned by the caller of this function.
    * @param _to The address that will be approved
    * @param _tokenId The token that have another address have
    *                 approval to perform actions on it
    */
    function approve(address _to, uint _tokenId)
        public
        onlyExtantToken(_tokenId)
    {
        require(msg.sender == ownerOf(_tokenId));
        require(msg.sender != _to);

        if (_getApproved(_tokenId) != address(0) ||
                _to != address(0)) {
            _approve(_to, _tokenId);
            emit Approval(msg.sender, _to, _tokenId);
        }
    }

    /*
    * @dev Changes the ownership of a token.
    * @notice Only the owner or approved address of a token can execute this function.
    * @param _from The original owner of the token
    * @param _to The address that the token's ownership will be transferred to
    * @param _tokenId The token that will have its ownership changed.
    */
    function transferFrom(address _from, address _to, uint _tokenId)
        public
        onlyExtantToken(_tokenId)
        canTransfer(_tokenId)
    {
        //require(getApproved(_tokenId) == msg.sender);
        require(ownerOf(_tokenId) == _from);
        require(_to != address(0));

        _clearApprovalAndTransfer(_from, _to, _tokenId);

        emit Approval(_from, 0, _tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

    /*
    * @dev Changes the onership of a token
    * @notice Only the owner of the token can execute this function.
    * @param _to The address that the ownership of the token will be changed to.
    * @param _tokenId The token that will have its ownership changed.
    */
    function transfer(address _to, uint _tokenId)
        public
        onlyExtantToken(_tokenId)
        canTransfer(_tokenId)
    {
        require(ownerOf(_tokenId) == msg.sender);
        require(_to != address(0));

        _clearApprovalAndTransfer(msg.sender, _to, _tokenId);

        emit Approval(msg.sender, 0, _tokenId);
        emit Transfer(msg.sender, _to, _tokenId);
    }

    /**
    * @dev Approves a marketplace address using the interface standard defined above
            and executes the marketplace's listing contract.
    * @param _spender Address of the lister of the token
    * @param _tokenId The token to list
    * @param _listType The int8 category that this listing uses.
    * @param _price The uint amount that the marketplace uses when listing the token
    * @return bool True if the listing is successful.
    */
    function approveAndList(address _spender, uint _tokenId, uint8 _listType, uint _price)
        public
        canTransfer(_tokenId)
        returns (bool success)
    {

        Marketplace market = Marketplace(_spender);
        approve(_spender, _tokenId);
        if (getApproved(_tokenId) == _spender) {
            market.receiveApproval(msg.sender, _tokenId, this, _listType, _price);
            return true;
        }
        return false;
    }

    // might need to make this internal, only to be called
    // by buyGame and remove "onlyKorro"
    /*
    * @dev Creates a new asset token
    * @notice Only KorroBox can call this function for tokenIds that don't exist yet
    *           and if the number of tokens hasn't reached the max supply.
    * @param _owner The address that will own the new token.
    * @param _tokenId The uint256 id of the new token.
    */
    function mint(address _owner, uint256 _tokenId)
        public
        onlyNonexistentToken(_tokenId)
        onlyKorro()
    {
        require(numTokensTotal < maxTokenSupply);

        // require that the _tokenId corresponds to an
        // index in the database
        require(_tokenId < maxTokenSupply);

        _setTokenOwner(_tokenId, _owner);
        _addTokenToOwnersList(_owner, _tokenId);

        numTokensTotal = numTokensTotal.add(1);

        emit Mint(_owner, _tokenId);
    }

    /*
    * @dev Creates a new asset token
    * @notice can only be called internally
    * @param _newAddress The address that KorroBox's payable address will be changed to
    */
    function _mint(address _owner, uint256 _tokenId)
        internal
        onlyNonexistentToken(_tokenId)
    {
        require(numTokensTotal < maxTokenSupply);

        // require that the _tokenId corresponds to an
        // index in the database
        require(_tokenId < maxTokenSupply);

        _setTokenOwner(_tokenId, _owner);
        _addTokenToOwnersList(_owner, _tokenId);

        numTokensTotal = numTokensTotal.add(1);

        emit Mint(_owner, _tokenId);
    }

    /*
    * @dev Returns the token id of an owner at a given index of its ownership array
    * @param _owner The address of the owner of the array of tokens that this function checks
    * @param _index The index of the array of tokens that the owner owns
    *                 that this function returns
    * @return uint Token Id that the owner owns at the provided token array index
    */
    function tokenOfOwnerByIndex(address _owner, uint _index)
        public
        view
        returns (uint _tokenId)
    {
        return _getOwnerTokenByIndex(_owner, _index);
    }

    /*
    * @dev Returns the array of tokens that an owner owns.
    * @notice can only be called internally
    * @param _newAddress The address that KorroBox's payable address will be changed to
    */
    function getOwnerTokens(address _owner)
        public
        view
        returns (uint[] _tokenIds)
    {
        return _getOwnerTokens(_owner);
    }

    // TODO: probably delete this function
    /*
    * @dev Returns true if this contract follows the ERC721 standard.
            Which it does as long as it's set to be transferable = true.
    */
    function implementsERC721()
        public
        view
        returns (bool _implementsERC721)
    {
        return transferable;
    }

    /*
    * @dev Returns the approved address for a provided token id.
    * @param _tokenId The token Id that this function returns the approved address of.
    * @return address that has approval from the provided token Id.
    */
    function getApproved(uint _tokenId)
        public
        view
        returns (address _approved)
    {
        return _getApproved(_tokenId);
    }

    /*
    * @dev Transferes ownership of a token and then resets its approval to no address.
    * @notice can only be called internally
    * @param _from The address of current owner of the token that will be transferred from.
    * @param _to The address that the token is being transferred from.
    * @param _tokenId The token that is being transferred.
    */
    function _clearApprovalAndTransfer(address _from, address _to, uint _tokenId)
        internal
    {
        _clearTokenApproval(_tokenId);
        _removeTokenFromOwnersList(_from, _tokenId);
        _setTokenOwner(_tokenId, _to);
        _addTokenToOwnersList(_to, _tokenId);
    }

    /*
    * @dev Returns the owner of the provided token Id.
    * @notice can only be called internally
    * @param _tokenId The token Id to return the owner of.
    * @returns address Of the owner of the provided token Id.
    */
    function _ownerOf(uint _tokenId)
        internal
        view
        returns (address _owner)
    {
        return tokenIdToOwner[_tokenId];
    }

    /*
    * @dev Updates the approve address of the provided token id to the provided address.
    * @notice can only be called internally
    * @param _to The address that will recieve aproval for the provided token Id.
    * @param _tokenId The token that will have its approval changed.
    */
    function _approve(address _to, uint _tokenId)
        internal
    {
        tokenIdToApprovedAddress[_tokenId] = _to;
    }

    /*
    * @dev Returns the approve address of the provided token Id.
    * @notice can only be called internally
    * @param _tokenId The token Id to return the apporved address of.
    */
    function _getApproved(uint _tokenId)
        internal
        view
        returns (address _approved)
    {
        return tokenIdToApprovedAddress[_tokenId];
    }

    /*
    * @dev Returns the array of tokens owned by a provided owner address.
    * @notice can only be called internally
    * @param _owner The address this function returns the array of owned tokens of.
    */
    function _getOwnerTokens(address _owner)
        internal
        view
        returns (uint[] _tokens)
    {
        return ownerToTokensOwned[_owner];
    }

    /*
    * @dev Retuns the tokenId of a token owned by the provided address
            at the provided index of the ownership array.
    * @notice can only be called internally
    * @param _owner Address of the owner of the token ownership array.
    * @param _index Index of the ownership array to return the token Id of.
    * @return uint Token Id for the proivded owner's address and index.
    */
    function _getOwnerTokenByIndex(address _owner, uint _index)
        internal
        view
        returns (uint _tokens)
    {
        return ownerToTokensOwned[_owner][_index];
    }

    /*
    * @dev Clear the proved address for the provided token_id
    * @notice can only be called internally
    * @param _tokenId the token Id to have its approved address set to address(0).
    */
    function _clearTokenApproval(uint _tokenId)
        internal
    {
        tokenIdToApprovedAddress[_tokenId] = address(0);
    }

    /*
    * @dev Updates the owner of provided token Id to the provided address.
    * @notice can only be called internally
    * @param _tokenId The token to have its owner address updated.
    * @param _owner the new owner address of the provided token Id
    */
    function _setTokenOwner(uint _tokenId, address _owner)
        internal
    {
        tokenIdToOwner[_tokenId] = _owner;
    }

    /*
    * @dev Update the ownership array of the provided owner address by appending
            the provided token Id.
    * @notice can only be called internally
    * @param _owner The owner address to add the token Id to its ownership array.
    * @param _tokenId The token to append to the ownership array.
    */
    function _addTokenToOwnersList(address _owner, uint _tokenId)
        internal
    {
        ownerToTokensOwned[_owner].push(_tokenId);
        tokenIdToOwnerArrayIndex[_tokenId] =
            ownerToTokensOwned[_owner].length - 1;
    }

    /*
    * @dev Removes the provided token Id from the privided address's array
              of owned tokens
    * @notice can only be called internally. Will fail if provided address doesn't
                own the provided token Id.
    * @param _owner Address of the owner of the array for the token Id to be removed.
    * @param _tokenId The token Id to be removed from the owner's array.
    */
    function _removeTokenFromOwnersList(address _owner, uint _tokenId)
        internal
    {
        //require(_ownerOf(_tokenId) == _owner);
        uint length = ownerToTokensOwned[_owner].length;
        uint index = tokenIdToOwnerArrayIndex[_tokenId];
        uint swapToken = ownerToTokensOwned[_owner][length - 1];

        ownerToTokensOwned[_owner][index] = swapToken;
        tokenIdToOwnerArrayIndex[swapToken] = index;

        delete ownerToTokensOwned[_owner][length - 1];
        ownerToTokensOwned[_owner].length--;
    }

    /*
    * @dev Updates the metadata map of the provided token Id with the provied metadata.
    * @notice can only be called internally
    * @param _tokenId The token to add the provided metadata to
    * @param _metadata Content to update the metadata map with.
    */
    function _insertTokenMetadata(uint _tokenId, string _metadata)
        internal
    {
        tokenIdToMetadata[_tokenId] = _metadata;
    }

    /*
    * @dev A player can buy a token Id through korroBox with this funciton. The
            player must recieve a signed message through korroBox that provides
            the game's price and relevant taxes based on the player's region.
            If the appropriate amount of ETH is sent with this payable function,
            the player gets a token minted to their account. The game dev is
            sent the gamePrice payable portion and korroBox recieves the
            appropriate taxes.
            Go to www.korrobox.com for details and automatically signing and
            setting up this contract for the caller.
    * @notice Go to www.korrobox.com to recieve the correct signed message and
            be informed of the correct ETH payment to send.
    * @param _gamePrice The string representation of the ETH price of a token.
    * @param _vat A string of the absolute value of taxes and vat for this token
            price and player.
    * @param _blockWhenSigned Strong of the latest block number of the Ethereum blockchain.
    * @param v part of the korroBox signature
    * @param r part of the korroBox signature
    */
    function buyGame(string _gamePrice, string _vat, string _blockWhenSigned, uint8 v, bytes32 r, bytes32 s)
        payable
        public
    {
        bytes32 finalHash = keccak256(abi.encodePacked(_gamePrice, _vat, _blockWhenSigned));
        uint price = stringToUint(_gamePrice);
        uint vat = stringToUint(_vat);
        uint latestBlock = stringToUint(_blockWhenSigned);
        require(_verify(korroBox, finalHash, v, r, s) || _verifyNoPrefix(korroBox, finalHash, v, r, s), "The price is not signed by the korrobox address");
        require(msg.value == price + vat);
        require(latestBlock + purchaseWindowInBlocks >= block.number);

        // give to buyer by directly minting to them
        _mint(msg.sender, numTokensTotal);

        // transfer price to game seller
        gameDevPayable.transfer(price);

        // transfer vat to korrobox
        korroBoxPayable.transfer(vat);
    }

    /*
    * @dev A player can buy a token Id through korroBox with this funciton. The
            player must recieve a signed message through korroBox that provides
            the game's price and relevant taxes based on the player's region.
            If the appropriate amount of ETH is sent with this payable function,
            the player gets a token minted to their account. The game dev is
            sent the gamePrice payable portion and korroBox recieves the
            appropriate taxes.
            Go to www.korrobox.com for details and automatically signing and
            setting up this contract for the caller.
    * @notice Go to www.korrobox.com to recieve the correct signed message and
            be informed of the correct ETH payment to send.
    * @param _gamePrice The string representation of the ETH price of a token.
    * @param _vat A string of the absolute value of taxes and vat for this token
            price and player.
    * @param _tokenId The tokenId to be minted to the buyer
    * @param _block_when_signed String of the latest block number of the Ethereum blockchain.
    * @param v Part of the korroBox signature
    * @param r Part of the korroBox signature
    */
    function buySpecificGameId(string _gamePrice, string _vat, string _tokenId, string _blockWhenSigned, uint8 v, bytes32 r, bytes32 s)
        payable
        public
    {
        bytes32 finalHash = keccak256(abi.encodePacked(_gamePrice, _vat, _tokenId, _blockWhenSigned));
        uint price = stringToUint(_gamePrice);
        uint vat = stringToUint(_vat);
        uint token_id_to_purchase = stringToUint(_tokenId);
        uint blockWhenSigned = stringToUint(_blockWhenSigned);
        require(_verify(korroBox, finalHash, v, r, s) || _verifyNoPrefix(korroBox, finalHash, v, r, s), "The price is not signed by the korrobox address");
        require(msg.value == price + vat);
        require(blockWhenSigned + purchaseWindowInBlocks >= block.number);

        // give to buyer by directly minting to them
        _mint(msg.sender, token_id_to_purchase);

        // transfer price to game seller
        gameDevPayable.transfer(price);

        // transfer vat to korrobox
        korroBoxPayable.transfer(vat);
    }

    /*
    * @dev Requires that the provided address was used to sign the hash
    * @notice Attaches a previx in case the hash doesn't contain one.
    * @param _address Address to verify that it signed the hash.
    * @param _hash The byte32 hash to recover the signing address from.
    * @param v part of the signature
    * @param r part of the signature
    * @param s part of the signature
    */
    function _verify(address _address, bytes32 hash, uint8 v, bytes32 r, bytes32 s)
      public
      pure
      returns(bool)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        return ecrecover(prefixedHash, v, r, s) == _address;
    }

    /*
    * @dev Requires that the provided address was used to sign the hash
    * @notice No provided prefix.
    * @param _address Address to verify that it signed the hash.
    * @param _hash The byte32 hash to recover the signing address from.
    * @param v part of the signature
    * @param r part of the signature
    * @param s part of the signature
    */
    function _verifyNoPrefix(address _address, bytes32 hash, uint8 v, bytes32 r, bytes32 s) public pure returns(bool) {
        return ecrecover(hash, v, r, s) == _address;
    }

    /*
    * @dev Concatenates two strings together
    * @param _gamePrice String of the price to
    * @param _blockWhenSigned The block when korrobox signed the message
    */
    function getString(string _gamePrice, string _blockWhenSigned) public pure returns(string) {
        string memory finalHash = _gamePrice.toSlice().concat(_blockWhenSigned.toSlice());
        return finalHash;
    }

    /*
    * @dev Converts a string into an uint.
    * @notice Attaches a previx in case the hash doesn't contain one.
    * @param s The string to be converted to a uint
    * @return result The uint representation of the string s.
    */
    function stringToUint(string s) internal pure returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

}
