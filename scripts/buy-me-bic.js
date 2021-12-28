require('dotenv').config()
const Private = require('../abi/Private.json')
const Whitelist = require('../abi/Whitelist.json')
const Web3 = require('web3')
const { BN } = require('bn.js')

const MAINNET_RPC = 'https://bsc-dataseed.binance.org/'
const TESTNET_RPC = 'https://data-seed-prebsc-1-s1.binance.org:8545/'

const PRIVATE_ADDRESS_MAINNET = '0xF56c8B3432c70E01f8639a753aeA829AC34aeDbE'
const PRIVATE_ADDRESS_TESTNET = '0x9954D270f2012cE3477031D3921a1033946873a6'

const WHITELIST_ADDRESS_MAINNET = '0x7910f4fcca2fae71147df3ac62eebf2c7b6cf05f'
const WHITELIST_ADDRESS_TESTNET = '0x8Fa453073782283C781316E8E4d81801B54228C3'

const BUYER_MAINNET = '0x89b681130154FD6575eb52723301a2C4b991Da07'
const BUYER_TESTNET = '0xE44CFe606eE964c99824129619af116e2cd4AA9a'

// TODO: Change to 1 to Buy real BIC
const TYPE = 0
const MY_BUSD = (new BN((1e18).toString())).mul(new BN('790')) //790000000000000000000

const WHITELIST_PRIVATE_SALE = '0x289542b9a02c7937d659afe40404ec4f7813e59fc5caf7269eff9a359916cb5c'
let numTry = 0
async function BuyMeBIC(web3, privateContract, whitelistContract, me, privateKey) { 

    const magic = async () => {
        numTry++
        console.log("Try: ", numTry)

        const userInfo = await whitelistContract.methods.getUserInfo(me, WHITELIST_PRIVATE_SALE).call()
        if (!userInfo['1']) {
            console.log('not whitelisted')
            return false
        }
        console.log('BOSS whitelisted!')
        const data = privateContract.methods.buy(MY_BUSD).encodeABI()
        const rawTx = await initTx(web3, me, getPrivateAddress(), 0, data)
        const signedTx = await web3.eth.accounts.signTransaction(rawTx, privateKey)

        const receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction)
        console.log("txHash: ", receipt.transactionHash)
        return true
    }

    setTimeout(async () => {
        try {
            const result = await magic()
            if (result) {
                console.log("Congratulation BOSS! Buy OK!!!")
                return
            }
            await BuyMeBIC(web3, privateContract, whitelistContract, me, privateKey)
        } catch (err) {
            console.log(err)
            console.log("try again in setTimeout function\n\n")
            await BuyMeBIC(web3, privateContract, whitelistContract, me, privateKey)
        }
    }, 2509)
}

async function main() {
    console.log('Reminder: Change TYPE to 1 to buy real BIC')
    const web3 = new Web3(getRPC())
    const privateContract = new web3.eth.Contract(Private, getPrivateAddress())
    const whitelistContract = new web3.eth.Contract(Whitelist, getWhitelistAddress())
    const me = getBuyer()
    const privateKey = getPrivateKey()
    await BuyMeBIC(web3, privateContract, whitelistContract, me, privateKey)
}

main()

function getRPC() {
    return (TYPE === 1 ? MAINNET_RPC : TESTNET_RPC)
}

function getPrivateAddress() {
    return (TYPE === 1 ? PRIVATE_ADDRESS_MAINNET : PRIVATE_ADDRESS_TESTNET)
}

function getWhitelistAddress() {
    return (TYPE === 1 ? WHITELIST_ADDRESS_MAINNET : WHITELIST_ADDRESS_TESTNET)
}

function getBuyer() {
    return (TYPE === 1 ? BUYER_MAINNET : BUYER_TESTNET)
}

function getPrivateKey() {
    return (TYPE === 1 ? process.env.BSC_BUYER_SECRET_KEY : process.env.BSC_TEST_BUYER_SECRET_KEY)
}

async function initTx(web3, from, to, value, data) {
    const txConfig = {
        from,
        to,
        value,
        data
    }
    const gasLimit = await web3.eth.estimateGas(txConfig)
    // let nonce = await web3.eth.getTransactionCount(from)
    return {
      ...txConfig,
    //   nonce: nonce.toString(),
      gas: gasLimit
    }
}

