# Project : VART(Back-end)

### 1. What is VART(Virtual Asset Retrieval and Transfer System)

**VART is a system that shows disclosure.**

#### Architecture

![image](https://user-images.githubusercontent.com/65117718/100582410-8a7da600-332c-11eb-8d7d-3738c855534d.png)

#### Using Port

| Name                | Port |
| :------------------ | ---- |
| hyperledger Explore | 8080 |
| Node.js Express     | 3001 |
| Blockchain Explorer | 8000 |

### 2. Get Start

#### * Pre-Setting

- Docker
- Linux
- Node.js (ver 12.x)
- Go
- npm

#### a. npm install

```
npm i  || npm install
```

#### b. Hyperledger Fabric

##### - Chaincode Complile

```
cd hyperledger_fabric/chaincode/disclosure
go build

cd ../vart
go build

```

##### - Network Up

```
cd ../../network
./network.sh up
```

##### - Chaincode Install & Instantiate

```
cd scripts
./CC.sh
```

##### - Blockchain Explorer Up

```
cd ..
./network.sh explorerUp
```

##### - Create Wallet

```
cd ../application
node enrollAdmin.js
node registerUser.js
```

### 3. Clean Up

```
cd hyperledger_fabric/network
./network.sh down
```

