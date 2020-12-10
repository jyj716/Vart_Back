const selectProperties = async (object, projection) => {
    let isProjection = false

    for (let value of Object.values(projection)) {
        isProjection = isProjection | value
    }


    if (isProjection) {
        for (let objKey of Object.keys(object)) {
            let isKey = false

            for (let [proKey, proValue] of Object.entries(projection)) {
                if (objKey === proKey) {
                    if (proValue) {
                        isKey = true
                    } else {
                        delete object[objKey]
                    }
                }
            }

            if (!isKey) {
                delete object[objKey]
            }
        }
    } else {
        for (let objKey of Object.keys(object)) {
            for (let [proKey, proValue] of Object.entries(projection)) {
                if (objKey === proKey) {
                    if (!proValue) {
                        delete object[objKey]
                    }
                }
            }
        }

    }
}


"use strict";
const { FileSystemWallet, Gateway } = require("fabric-network");
const fs = require("fs");
const path = require("path");
const YAML = require("yaml")

const ccpPath = path.resolve(__dirname, '..', 'hyperledger_fabric', 'network', 'connection.yaml')
const ccpYAML = fs.readFileSync(ccpPath, "utf8");
const ccp = YAML.parse(ccpYAML);

const wallet = async (chaincodeId) => {
    try {
        // Create a new file system based wallet for managing identities.
        const walletPath = path.join(process.cwd(), 'hyperledger_fabric', 'application', 'wallet')
        const wallet = new FileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check to see if we've already enrolled the user.
        const userExists = await wallet.exists("user1");
        if (!userExists) {
            console.log(
                'An identity for the user "user1" does not exist in the wallet'
            );
            console.log("Run the registerUser.js application before retrying");
            return;
        }

        // Create a new gateway for connecting to our peer node.
        const gateway = new Gateway();
        await gateway.connect(ccp, {
            wallet,
            identity: "user1",
            discovery: { enabled: false },
        });

        // Get the network (channel) our contract is deployed to.
        const network = await gateway.getNetwork("mychannel");

        // Get the contract from the network.
        const contract = network.getContract(chaincodeId);

        return contract

    } catch (error) {
        console.error(`Wallet Error: ${error}`);

        result = {
            result: false,
            data: error
        }

        return result
    }
}


module.exports = {
    selectProperties,
    wallet
}
