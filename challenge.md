In this take-home, you will build an API platform (with a basic UI) to generate custodial wallets on the backend with support for basic actions. We leave it kinda open-ended to not limit your creativity and to let you focus on things that you are interested in, within this problem.

### Requirements:

- An authenticated user can create at least one account/wallet.
- All the interactions with the custodial wallet would be done on the backend via an API.
- A user can perform at least these actions on the wallet:
  - getBalance() → balance: number (get the current balance on the wallet.)
  - signMessage(msg: string) → signedMessage: string (The signed message with the private key)
  - sendTransaction(to: string, amount: number) → transactionHash: string (sends a transaction on the blockchain)
- Basic UI to interact with the API.
- We encourage you to use the language/framework that you’re most comfortable with as long as it is a language we are familiar with (Javascript/Typescript, Ruby, Python, Java, and Scala). Internally, we use TypeScript, Node and React, but our core product needs to work seamlessly with many different build tools and frameworks.

### What to focus on:

- Code + API + Schema design and implementation.
- Security considerations (could be in a writeup).
- Testing.

### UI:

The main focus of this takehome is the API/Backend experience. The UI should allow you to showcase the functionality that you built on the backend.

### Tips (you don’t have to follow any of them):

- You can use Dynamic for the authentication layer.
- You can use any open source library for managing the wallet interactions on the backend, such as [Ethers](https://www.dynamic.xyz/blog/how-does-ethers-js-work) or [Viem](https://viem.sh/)
  - Ethers has a [Wallet](https://docs.ethers.org/v6/api/wallet/#about-wallets) class that handles the private key and common methods
- You can use these faucets to get some free [sepolia](https://sepoliafaucet.com/) (assuming that you are building it on Ethereum)
- Here are two RPC [infura](https://app.infura.io/) end-points for ETH testnets that you can use:
  - Seopolia - https://sepolia.infura.io/v3/91de7ed3c17344cc95f8ea31bf6b3adf
