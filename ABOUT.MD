Kubecoin Booth Primer
---------------------

#### Motivation

Kubecoin is an experiment to poke at capturing personal (health) information in a private, respectful, secure and trustworthy way.

It was also created as a fun, and interesting way to put IBM Cloud technology in the hands and pockets of developers, among other things it uses the following IBM Technology:

- IBM Cloud Container Service
- IBM Cloud Functions
- IBM Blockchain
- IBM Mongo Database by Compose
- IBM Cloud Foundry
- IBM MQTT Service

The backend is written in Node.JS, the iOS app in Swift 4 and the Android app in Java.

It was developed by Anthony Amanse, Ishan Gulhane, Hovig Ohannessian, Raheel Zubairy ( with leadership from Laura Bennett )

Here's a high level overview of the technology:

![kubecoin screens](https://raw.githubusercontent.com/antonmc/kubecoin/master/design/architecture.png)

Here's a deeper architecture dive of the **Android/Kubernetes** integration:
https://github.com/IBM/android-kubernetes-blockchain/blob/master/README.md


##### iPhone App on iTunes
developed by Anton McConville & Anthony Amanse

https://itunes.apple.com/us/app/kubecoin/id1369165644?mt=8

##### Android App on Google Play
developed by Anthony Amanse

https://play.google.com/store/apps/details?id=com.amanse.anthony.fitcoinandroid&hl=en

##### Kubecoin Dashboard:
http://kubecoin.mybluemix.net/

> (bug) http is needed to enable socket connection to listen to blockchain events (will create a new block in dashboard when there is a transaction)

We want to show this on a display as much as possible. The dashboard shows the blocks created by the blockchain. The blocks contains the transactions that were performed.

Blockchain transactions (a commit/change to the ledger) include:

* user registration
* updating steps and generating fitcoins
* user creating a contract (claiming swags from shop view in phone)
* user canceling a contract
* confirming contracts (us confirming the contracts and giving them the swag)

##### Kubecoin Shop dashboard
to complete transactions (enter contract id and complete):
https://kubecoin-shop.mybluemix.net/

> github repo: https://github.com/AnthonyAmanse/kubecoin-shop

We want to keep this to ourselves to show a participant when they cash in. After pressing "Confirm" contract, you'll get a message saying that confirming the contract is successful with a transaction ID from the blockchain.

##### Kubecoin Raffle
to pick a random participant out of all of them (click on header to start):
https://kubecoin-raffle.mybluemix.net/

> github repo: https://github.com/AnthonyAmanse/raffle

_temporary raffle dashboard_
