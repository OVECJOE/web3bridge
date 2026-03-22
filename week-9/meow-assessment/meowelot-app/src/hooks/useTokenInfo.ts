import { useReadContracts } from "wagmi";
import { TOKEN_ADDRESS, TOKEN_ABI } from "../lib/contracts";

export function useTokenInfo() {
  const { data, isLoading, refetch } = useReadContracts({
    contracts: [
      { address: TOKEN_ADDRESS, abi: TOKEN_ABI, functionName: "totalSupply" },
      { address: TOKEN_ADDRESS, abi: TOKEN_ABI, functionName: "MAX_SUPPLY" },
      { address: TOKEN_ADDRESS, abi: TOKEN_ABI, functionName: "totalBurned" },
      { address: TOKEN_ADDRESS, abi: TOKEN_ABI, functionName: "remainingMintable" },
      { address: TOKEN_ADDRESS, abi: TOKEN_ABI, functionName: "treasuryAddress" },
      { address: TOKEN_ADDRESS, abi: TOKEN_ABI, functionName: "burnFeeBps" },
      { address: TOKEN_ADDRESS, abi: TOKEN_ABI, functionName: "treasuryFeeBps" },
      { address: TOKEN_ADDRESS, abi: TOKEN_ABI, functionName: "paused" },
      { address: TOKEN_ADDRESS, abi: TOKEN_ABI, functionName: "ANTI_WHALE_CAP" },
      { address: TOKEN_ADDRESS, abi: TOKEN_ABI, functionName: "NFT_THRESHOLD" },
    ],
  });

  return {
    totalSupply:     (data?.[0]?.result as bigint) ?? 0n,
    maxSupply:       (data?.[1]?.result as bigint) ?? 0n,
    totalBurned:     (data?.[2]?.result as bigint) ?? 0n,
    remainingMint:   (data?.[3]?.result as bigint) ?? 0n,
    treasury:        (data?.[4]?.result as string) ?? "",
    burnFeeBps:      (data?.[5]?.result as bigint) ?? 0n,
    treasuryFeeBps:  (data?.[6]?.result as bigint) ?? 0n,
    paused:          (data?.[7]?.result as boolean) ?? false,
    antiWhaleCap:    (data?.[8]?.result as bigint) ?? 0n,
    nftThreshold:    (data?.[9]?.result as bigint) ?? 0n,
    isLoading,
    refetch,
  };
}