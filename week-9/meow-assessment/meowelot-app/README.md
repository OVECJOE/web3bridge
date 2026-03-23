# Meowelot Frontend

React + TypeScript frontend for the $MEOW token on Lisk Sepolia.

## Setup

```bash
bun install
# Fill in .env with your deployed addresses and WalletConnect project id
bun run dev
```

Required environment variables:

```env
VITE_TOKEN_ADDRESS=0x...
VITE_NFT_ADDRESS=0x...
VITE_WALLETCONNECT_PROJECT_ID=your_walletconnect_cloud_project_id
VITE_APP_URL=https://your-production-domain.com
VITE_APP_ICON=https://your-production-domain.com/icon.png
```

Create a WalletConnect Cloud project id at https://cloud.walletconnect.com.
Without this value, many mobile wallets will not appear in the connect modal.

## Deploy (Vercel)

```bash
bun run build
# Push to GitHub, import repo in Vercel
# Set VITE_TOKEN_ADDRESS, VITE_NFT_ADDRESS, and VITE_WALLETCONNECT_PROJECT_ID env vars
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