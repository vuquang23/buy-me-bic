require('dotenv').config()
const Whitelist = require('../abi/Whitelist.json')
const Web3 = require('web3')


async function main() {
    const web3 = new Web3('https://data-seed-prebsc-1-s1.binance.org:8545/')
    const WHITELIST_ADDRESS_TESTNET = '0x8Fa453073782283C781316E8E4d81801B54228C3'
    const privateKey = 'b011a5e7b87fe05d0a39a123a670bffbdda2d595604ce755e0298f09fb100da1'
    const admin = '0xA450ffc9564E6F9f97D3903ecCdD40265a4F2AE2'

    const whitelistContract = new web3.eth.Contract(Whitelist, WHITELIST_ADDRESS_TESTNET)
    const data = whitelistContract.methods.updateMultiUserInfo(
        ['0xE44CFe606eE964c99824129619af116e2cd4AA9a'],
        ['0x289542b9a02c7937d659afe40404ec4f7813e59fc5caf7269eff9a359916cb5c'],
        [true],
        ['0xA450ffc9564E6F9f97D3903ecCdD40265a4F2AE2'],
        [[]]
    ).encodeABI()

    const rawTx = await initTx(web3, admin, WHITELIST_ADDRESS_TESTNET, 0, data)
    const signedTx = await web3.eth.accounts.signTransaction(rawTx, privateKey)
    console.log(await web3.eth.sendSignedTransaction(signedTx.rawTransaction))
}

main()

async function initTx(web3, from, to, value, data) {
    const txConfig = {
        from,
        to,
        value,
        data
    }
    const gasLimit = await web3.eth.estimateGas(txConfig)
    let nonce = await web3.eth.getTransactionCount(from)
    return {
      ...txConfig,
      nonce,
      gas: gasLimit
    }
}
