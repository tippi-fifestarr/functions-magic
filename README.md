# Block Magic ++Functions Workshop
In this exercise, we transform the price forecast bot functions workshop into a D&D themed character info generator.  We take in character info from ```RanCharacter.sol``` and pass that to GPT for some unique Ideals, Traits, Flaws and Bonds. But first, we make a simple hardcoded backstory generator to get the ball rolling.
"Persistence is key, don't give up!" - [BunsDev](https://github.com/BunsDev/)

## Getting Started
- [Install Foundry and Rust](/docs/INSTALL.md)
- [Foundry Guide](/docs/FOUNDRY.md)
- [OpenAI API Key](https://platform.openai.com/api-keys)

## Overview of Functions
Chainlink functions enables you to leverage the power of a decentralized oracle network (DON) to execute external function calls (off-chain) to inform on-chain interactions.

Chainlink is able to execute a user-defined function via a DON, which comes to consensus on the results and reports the median result to the requesting contract via a callback function.

---

## Magic Workflow

> -1. Clone this repo `https://github.com/tippi-fifestarr/functions-magic` (a fork from [BunsDev/functions-workshop](https://github.com/BunsDev/functions-workshop))

0. Check your prerequisites (above) and `yarn install`
1. Set up your environment variables with Chainlink's ENV-ENC encryption tool
2. Simulate your function to ensure it behaves as expected
3. Deploy your consumer contract
4. Create a subscription for your consumer contract
5. Make requests to your consumer contract
6. Query the response from your consumer contract
7. Celebrate 🎉

### 1. Setup Environment Variables

#### Create Password
Chainlink Functions enables you to securely share secrets with the DON. Secrets are encrypted with a password.
```
yarn set:pw
```
Once the encryption key is created with your desired password, you can safely share your secrets with the DON, which requires multiple nodes to decrypt with consensus.

#### Store Variables

We may now safely store environment variables without worrying about them being exposed, since they will be encrypted with your desired password. 

These variables will be stored in a file called `.env.enc`.

```
yarn set:env
```
After running the command, you'll be prompted to enter the following for each variable to be encrypted:

- **Name**: used to identify the variable.

- **Value**: your (*unencrypted*) environment variable (*secret*).

For this demonstration, you will need to add the following to your encrypted environment variables:
- `OPENAI_KEY`
- `PRIVATE_KEY`
- `ETHERSCAN_API_KEY`

### 2. Simulate Functions
Before deploying, it's useful to simulate the execution of your function to ensure the output of your function execution is as expected.

You may simulate your function using the command below.

```
yarn simulate
```

For full details on creating HTTP requestion via functions, read our [API Reference Documentation](https://docs.chain.link/chainlink-functions/api-reference/javascript-source).

### 3. Deploy Consumer

```
yarn deploy
```

**Note**: ensure you have updated the deployment script to align with your target blockchain configurations.

### 4. Create Subscription
Fund a new Functions billing subscription via the [Chainlink Functions UI](https://functions.chain.link/) and add your deployed Consumer Contract as a an authorized consumer to your subscription OR do so programmatically, as follows: <br />
```
npx hardhat func-sub-create --network ethereumSepolia --amount <LINK_AMOUNT> --contract <CONSUMER_ADDRESS>
```

### 5. Make Requests
Functions enable you to make requests via the consumer contract. Before requesting, make sure you have successfully compiled your FunctionConsumer Contract, otherwise the request will fail to process.

You may do this programmatically with: <br/>
```
npx hardhat func-request --network <NETWORK_NAME> --contract <CONSUMER_ADDRESS> --subid <SUBSCRIPTION_ID>
``` 

You will see a confirmation request, so hit `Y` and press enter. 

Once the request is fulfilled the console will show the response (decoded into the relevant return type) from the execution of your custom JS script.

### 6. Make Queries
You are also able to query the response that was stored in your Functions Consumer contract either through the [Functions UI](https://functions.chain.link/) or programmatically as follows: <br/>
```
npx hardhat func-read --contract <CONSUMER_ADDRESS> --network <NETWORK_NAME>
```