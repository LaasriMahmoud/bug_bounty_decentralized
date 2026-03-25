# 🛡️ Bug Bounty Decentralized (BBD)

Une plateforme de bug bounty entièrement décentralisée permettant aux organisations de sécuriser leurs protocoles et aux chercheurs de soumettre des vulnérabilités de manière anonyme et vérifiable.

## 🚀 Vue d'Ensemble

La plateforme repose sur une architecture hybride exploitant la puissance des Smart Contracts (EVM) et le stockage décentralisé (IPFS). L'objectif est d'éliminer le besoin de tiers de confiance pour le paiement des récompenses et la gestion des litiges.

### Points Forts :
- **Décentralisation Totale** : Pas de serveur central, tout est on-chain ou sur IPFS.
- **Sécurité Maximale** : Utilisation de modules spécialisés (Escrow, StakeManager).
- **Justice Décentralisée** : Système de vote à l'aveugle pour résoudre les litiges.
- **Transparence & Réputation** : Historique immuable des chercheurs et organisations.

---

## 🏗️ Architecture du Projet

Le projet est divisé en deux parties principales :

### 1. Smart Contracts (Répertoire `contracts/`)
Le cœur du protocole, développé avec **Foundry**. Les contrats sont modulaires pour une meilleure maintenabilité et sécurité.

- **`BugBountyPlatform.sol`** : Point d'entrée principal. Il orchestre les appels entre les différents modules.
- **`Escrow.sol`** : Gère les fonds (USDC). Il permet aux entreprises de verrouiller leurs récompenses de manière sécurisée (Protection Anti-reentrancy).
- **`StakeManager.sol`** : Gère les cautions (stakes) des chercheurs. Cela limite le SPAM en obligeant un dépôt qui peut être confisqué en cas de soumission abusive.
- **`DisputeModule.sol`** : Gère les appels. Utilise un protocole **Commit/Reveal** (vote à l'aveugle) pour garantir l'équité des membres du comité.
- **`Reputation.sol`** : Suit les performances des acteurs pour renforcer la confiance dans l'écosystème.

### 2. Frontend (Répertoire `frontend/`)
Une application Web3 moderne construite avec **Next.js 14**.
- **Stack** : Wagmi, Viem, React Query, Tailwind CSS.
- **IPFS Integration** : Les vulnérabilités sont chiffrées localement et stockées sur IPFS. Seul le CID (Content Identifier) est envoyé on-chain.

---

## 🛠️ Installation et Utilisation

### Prérequis
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js v18+](https://nodejs.org/)

### Smart Contracts (Foundry)
```bash
cd contracts
forge build
forge test
```

### Frontend (Next.js)
```bash
cd frontend
npm install
npm run dev
```

---

## 🔄 Workflow de la Plateforme

1. **Création** : Une organisation déploie un programme de bug bounty et finance l'**Escrow** avec des USDC.
2. **Soumission** : Le chercheur trouve une faille, la chiffre et l'upload sur **IPFS**.
3. **Validation** : Le chercheur soumet le CID + un **Stake** (caution).
4. **Décision** : L'organisation valide la soumission.
    - **Accepté** : Le chercheur reçoit sa récompense (Escrow) et récupère son Stake.
    - **Refusé** : Le chercheur peut faire appel s'il juge le refus unjustified.
5. **Litige (Optionnel)** : Si appel, le **Dispute Module** entre en jeu. Le comité vote. Si le chercheur gagne, il reçoit sa prime. S'il perd, son Stake est brûlé ou envoyé à la Trésorerie.

---

## 🌐 Liens Utiles
- **Repository** : [GitHub](https://github.com/LaasriMahmoud/bug_bounty_decentralized.git)
- **Blockchain** : Arbitrum Sepolia (Testnet)
