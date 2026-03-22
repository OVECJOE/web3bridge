import { useReadContracts } from "wagmi";
import { TOKEN_ADDRESS, TOKEN_ABI, NFT_ADDRESS, NFT_ABI } from "../lib/contracts";

export function useUserBalance(address?: `0x${string}`) {
  const { data, isLoading, refetch } = useReadContracts({
    contracts: address ? [
      { address: TOKEN_ADDRESS, abi: TOKEN_ABI, functionName: "balanceOf", args: [address] },
      { address: NFT_ADDRESS,   abi: NFT_ABI,   functionName: "balanceOf", args: [address] },
      { address: TOKEN_ADDRESS, abi: TOKEN_ABI, functionName: "owner" },
    ] : [],
  });

  return {
    tokenBalance: (data?.[0]?.result as bigint) ?? 0n,
    nftBalance:   (data?.[1]?.result as bigint) ?? 0n,
    isOwner:      address && data?.[2]?.result
                    ? (data[2].result as string).toLowerCase() === address.toLowerCase()
                    : false,
    isLoading,
    refetch,
  };
}