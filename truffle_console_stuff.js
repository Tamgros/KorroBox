
const Web3 = require('web3') // 1.0.0-beta.34
// choose a web provider
const web3 = new Web3(Web3.givenProvider || 'http://localhost:7545')

// example onwer address owner:
// '0x90C9fDca9CA00b30a1dd73257e4C1351b5edbF71'

// define a new tokenized asset and give it owner addresss
korroBoxSteamGames.new('some','game', 100, false, '0xC42E0e7F42Ac467C818d0ab939F3f1367e431763','0x8096aF3EaaAC311bCB585E67ED224928Af03E9B6','0x9f8aa3f0f5C55eaE4aB348ee6B0C0B34eA21448D', {from: '0x90C9fDca9CA00b30a1dd73257e4C1351b5edbF71'})

// from the deployed address above
korroBoxContract = korroBoxSteamGames.at('<above deplyed address>')
korroBoxContract.totalSupply()
korroBoxContract.maxSupply()


var price = .5
var vat = 10;

var ethUsd = 450;
//here we need to grab the price + the VAT from our DB
var priceInEth = price / ethUsd;
var priceInWei = web3.utils.toWei(String(priceInEth).slice(0,16));

////var vat = 10.5;
var vatInEth = vat / ethUsd;
var vatInWei = web3.utils.toWei(String(vatInEth).slice(0,16));
var BN = web3.utils.BN;
var bnPrice = new BN(priceInWei);
var bnVat = new BN(vatInWei);
var finalPrice = bnPrice.add(bnVat);

var block = web3.eth.getBlockNumber();

// here's how you sign
var signedMsg = web3.eth.accounts.sign(web3.utils.sha3(String(priceInWei) + String(vatInWei) + String(block)), '0x1c5c2ab75cc4d4378fd651c74d7e99de31180fcb546be16e0fbba0df90d33acd');

var msg = String(signedMsg);

var r = signedMsg.r;
var s = signedMsg.s;
var v = web3.utils.toDecimal(signedMsg.v);


// some basic tests
korroBoxContract.verify_working(String(priceInWei), String(vatInWei), String(block), v, r, s);
korroBoxContract.verify__noprefix_working(String(priceInWei), String(vatInWei), String(block), v, r, s);

korroBoxContract.verify__noprefix_working(String(priceInWei), String(vatInWei), String(block), v, r, s);

korroBoxContract.buyGame(String(priceInWei), String(vatInWei), String(block), v, r, s,{from: '0x6801F9C7C648f1c0A927e0B5fbd21fDb161790c7', value:parseInt(finalPrice.toString(10))});

bytes32 finalHash = keccak256(abi.encodePacked(String(priceInWei), String(vatInWei), _latestBlock));
korroBoxContract._verify('0x90C9fDca9CA00b30a1dd73257e4C1351b5edbF71', finalHash, v, r, s)
