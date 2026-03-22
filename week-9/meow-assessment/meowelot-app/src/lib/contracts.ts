import { parseAbi, type Abi } from "viem";

export const TOKEN_ADDRESS = (import.meta.env.VITE_TOKEN_ADDRESS ||
  "0x0000000000000000000000000000000000000000") as `0x${string}`;
export const NFT_ADDRESS = (import.meta.env.VITE_NFT_ADDRESS ||
  "0x0000000000000000000000000000000000000000") as `0x${string}`;

export const liskSepolia = {
  id: 4202,
  name: "Lisk Sepolia",
  nativeCurrency: { name: "Ethereum", symbol: "ETH", decimals: 18 },
  rpcUrls: {
    default: { http: ["https://rpc.sepolia-api.lisk.com"] },
    public:  { http: ["https://rpc.sepolia-api.lisk.com"] },
  },
  blockExplorers: {
    default: { name: "Blockscout", url: "https://sepolia-blockscout.lisk.com" },
  },
  testnet: true,
} as const;

export const TOKEN_ABI = parseAbi([
  "function name() view returns (string)",
  "function symbol() view returns (string)",
  "function decimals() view returns (uint8)",
  "function totalSupply() view returns (uint256)",
  "function balanceOf(address) view returns (uint256)",
  "function MAX_SUPPLY() view returns (uint256)",
  "function FAUCET_AMOUNT() view returns (uint256)",
  "function FAUCET_COOLDOWN() view returns (uint256)",
  "function ANTI_WHALE_CAP() view returns (uint256)",
  "function NFT_THRESHOLD() view returns (uint256)",
  "function lastRequestTime(address) view returns (uint256)",
  "function timeUntilNextRequest(address) view returns (uint256)",
  "function treasuryAddress() view returns (address)",
  "function totalBurned() view returns (uint256)",
  "function remainingMintable() view returns (uint256)",
  "function circulatingSupply() view returns (uint256)",
  "function owner() view returns (address)",
  "function paused() view returns (bool)",
  "function allowance(address,address) view returns (uint256)",
  "function burnFeeBps() view returns (uint256)",
  "function treasuryFeeBps() view returns (uint256)",
  "function extraBurnBps() view returns (uint256)",
  "function requestToken()",
  "function mint(address to, uint256 amount)",
  "function transfer(address to, uint256 amount) returns (bool)",
  "function approve(address spender, uint256 amount) returns (bool)",
  "function burn(uint256 amount)",
]);

// NFT ABI — tuple typed properly as a plain Abi array (not parseAbi) to avoid
// viem's inline tuple parsing limitation for complex nested tuples.
export const NFT_ABI = [
  { name: "name",           type: "function", stateMutability: "view", inputs: [],                              outputs: [{ type: "string" }] },
  { name: "totalSupply",    type: "function", stateMutability: "view", inputs: [],                              outputs: [{ type: "uint256" }] },
  { name: "balanceOf",      type: "function", stateMutability: "view", inputs: [{ name: "owner", type: "address" }], outputs: [{ type: "uint256" }] },
  { name: "tokenURI",       type: "function", stateMutability: "view", inputs: [{ name: "tokenId", type: "uint256" }], outputs: [{ type: "string" }] },
  { name: "tokensOfOwner",  type: "function", stateMutability: "view", inputs: [{ name: "owner", type: "address" }],  outputs: [{ type: "uint256[]" }] },
  {
    name: "getTraits",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "tokenId", type: "uint256" }],
    outputs: [{
      type: "tuple",
      components: [
        { name: "furPattern", type: "uint8" },
        { name: "eyeColor",   type: "uint8" },
        { name: "background", type: "uint8" },
        { name: "accessory",  type: "uint8" },
        { name: "amount",     type: "uint256" },
        { name: "recipient",  type: "address" },
      ],
    }],
  },
] as const satisfies Abi;

export const EXPLORER_URL = "https://sepolia-blockscout.lisk.com";

export const FUR_NAMES = ["Golden Spots", "Silver Ghost", "Desert Sand", "Midnight Dark", "Crimson Wild"];
export const EYE_NAMES = ["Amber Glow", "Emerald Blaze", "Ice Blue", "Violet Storm", "Solar Gold"];
export const BG_NAMES  = ["Jungle Mist", "Night Sky", "Sunset Dunes", "Deep Ocean", "Aurora Borealis", "Volcanic Ash"];
export const ACC_NAMES = ["None", "Gold Chain", "Laser Eyes", "Crown", "Sunglasses"];