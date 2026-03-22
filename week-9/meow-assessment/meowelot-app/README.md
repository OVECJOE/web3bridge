# Meowelot Frontend

React + TypeScript frontend for the $MEOW token on Lisk Sepolia.

## Setup

```bash
npm install
cp .env.example .env
# Fill in your deployed contract addresses
npm start
```

## Deploy (Vercel)

```bash
npm run build
# Push to GitHub, import repo in Vercel
# Set REACT_APP_TOKEN_ADDRESS and REACT_APP_NFT_ADDRESS as env vars
```

## Architecture

```
src/
├── lib/
│   ├── contracts.ts   # ABIs, addresses, chain config
│   ├── wagmi.ts       # Wagmi client config
│   └── utils.ts       # formatMeow, formatCountdown, etc.
├── hooks/
│   ├── useTokenInfo.ts      # 8 read calls: supply, burned, fees, caps
│   ├── useUserBalance.ts    # balanceOf token + NFT, isOwner
│   ├── useFaucetTimer.ts    # per-user live countdown from on-chain time
│   ├── useRequestToken.ts   # requestToken() write
│   ├── useMint.ts           # mint() write — owner only
│   ├── useTransfer.ts       # transfer() write
│   └── useNFTGallery.ts     # tokensOfOwner + tokenURI + getTraits
├── components/
│   ├── Layout.tsx      # sidebar nav + header + wallet panel
│   ├── StatCard.tsx    # reusable stat display card
│   ├── TxButton.tsx    # loading/disabled tx button
│   └── InputField.tsx  # labelled input with error state
└── pages/
    ├── Dashboard.tsx   # stats, supply bar, tokenomics grid, wallet panel
    ├── Faucet.tsx      # animated SVG arc countdown, per-user timer
    ├── Transfer.tsx    # transfer form + fee preview + NFT badge
    ├── Mint.tsx        # owner-only mint form + supply impact preview
    └── Gallery.tsx     # NFT grid with on-chain SVG images + traits
```

## Read Functions Integrated (7)
1. `totalSupply()` — Dashboard
2. `balanceOf(address)` — Dashboard, Faucet, Transfer
3. `MAX_SUPPLY()` — Dashboard, Mint
4. `timeUntilNextRequest(address)` — Faucet (live countdown)
5. `treasuryAddress()` — Dashboard
6. `totalBurned()` — Dashboard
7. `remainingMintable()` — Mint

## Write Functions (3 required + extras)
- `requestToken()` — Faucet page
- `mint()` — Mint page (owner only)  
- `transfer()` — Transfer page