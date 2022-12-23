const { createAlchemyWeb3 } = require('@alch/alchemy-web3')

const whitelist = require('../scripts/whitelist.js')

const web3 = createAlchemyWeb3(process.env.NEXT_PUBLIC_ALCHEMY_RPC_URL)
import { config } from '../dapp.config'

const contract = require('../artifacts/contracts/BoredApe.sol/BoredApe.json')

const nftContract = new web3.eth.Contract(contract.abi, config.contractAddress)


export const getWhiteListMinted = async () => {
  const whitelistMinted = await nftContract.methods.totalWhiteListSupply().call()
  return whitelistMinted
}

export const getMaxSupply = async () => {
  const maxWhiteList = await nftContract.methods.maxWhiteList().call()
  return maxWhiteList
}

export const getTotalMax = async () => {
  const totalMax = await nftContract.methods.maxSupply().call()
  return totalMax
}

export const getTotalMinted = async () => {
  const totalSupply = await nftContract.methods.totalSupply().call()
  return totalSupply
} 
export const isPausedState = async () => {
  const paused = await nftContract.methods.paused().call()
  return paused
}

export const isPublicSaleState = async () => {
  const publicSale = await nftContract.methods.publicM().call()
  return publicSale
}

export const isPreSaleState = async () => {
  const whitelistM = await nftContract.methods.whitelistM().call()
  return whitelistM
}

// export const getPrice = async () => {
//   const price = await nftContract.methods.price().call()
//   return price
// }

export const presaleMint = async (mintAmount) => {
  if (!window.ethereum.selectedAddress) {
    return {
      success: false,
      status: 'To be able to mint, you need to connect your wallet'
    }
  }

  var isValid = 1;
  var merkle_proof;
  const response = await fetch(`/api/getProof`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      address: window.ethereum.selectedAddress
    }),
  });
  if(response.status == 200) {
    const { proof, root } = await response.json();
    merkle_proof = proof;
    console.log("proof:", proof);
    console.log("root:", root);
  } else {
    isValid = 0;
  }
  

  if (!isValid) {
    return {
      success: false,
      status: 'Invalid Merkle Proof - You are not on the whitelist'
    }
  }
  const nonce = await web3.eth.getTransactionCount(
    window.ethereum.selectedAddress,
    'latest'
  )
  // Set up our Ethereum transaction
  const tx = {
    to: config.contractAddress,
    from: window.ethereum.selectedAddress,
    value: parseInt(
      web3.utils.toWei(String(config.whitelist_price * mintAmount), 'ether')
    ).toString(16), // hex
    data: nftContract.methods
      .whitelistMint(mintAmount, merkle_proof)
      .encodeABI(),
    nonce: nonce.toString(16)
  }

  try {
    const txHash = await window.ethereum.request({
      method: 'eth_sendTransaction',
      params: [tx]
    })

    return {
      success: true,
      status: (
        <a href={`https://etherscan.io/tx/${txHash}`} target="_blank">
          <p>✅ Check out your transaction on Etherscan:</p>
          <p>{`https://etherscan.io/tx/${txHash}`}</p>
        </a>
      )
    }
  } catch (error) {
    return {
      success: false,
      status: '😞 Smth went wrong:' + error.message
    }
  }
}

export const publicMint = async (mintAmount) => {
  if (!window.ethereum.selectedAddress) {
    return {
      success: false,
      status: 'To be able to mint, you need to connect your wallet'
    }
  }

  const nonce = await web3.eth.getTransactionCount(
    window.ethereum.selectedAddress,
    'latest'
  )

  // Set up our Ethereum transaction
  const tx = {
    to: config.contractAddress,
    from: window.ethereum.selectedAddress,
    value: parseInt(
      web3.utils.toWei(String(config.price * mintAmount), 'ether')
    ).toString(16), // hex
    data: nftContract.methods.publicSaleMint(mintAmount).encodeABI(),
    nonce: nonce.toString(16)
  }

  try {
    const txHash = await window.ethereum.request({
      method: 'eth_sendTransaction',
      params: [tx]
    })

    return {
      success: true,
      status: (
        <a href={`https:/etherscan.io/tx/${txHash}`} target="_blank">
          <p>✅ Check out your transaction on Etherscan:</p>
          <p>{`https://etherscan.io/tx/${txHash}`}</p>
        </a>
      )
    }
  } catch (error) {
    return {
      success: false,
      status: '😞 Smth went wrong:' + error.message
    }
  }
}
