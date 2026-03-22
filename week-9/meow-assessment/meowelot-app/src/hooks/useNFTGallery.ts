import { useReadContract } from "wagmi";
import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { createPublicClient, http } from "viem";
import { NFT_ADDRESS, NFT_ABI, ACC_NAMES, BG_NAMES, EYE_NAMES, FUR_NAMES, liskSepolia } from "../lib/contracts";

export interface OcelotNFT {
  tokenId: number;
  tokenURI: string;
  traits: {
    furPattern: number; eyeColor: number;
    background: number; accessory: number;
    amount: bigint;     recipient: string;
    furName: string;    eyeName: string;
    bgName: string;     accName: string;
  };
}

interface RawTraits {
  furPattern: number;
  eyeColor: number;
  background: number;
  accessory: number;
  amount: bigint;
  recipient: `0x${string}`;
}

export function useNFTGallery(address?: `0x${string}`) {
  const { data: tokenIds, isLoading: isIdsLoading } = useReadContract({
    address: NFT_ADDRESS,
    abi: NFT_ABI,
    functionName: "tokensOfOwner",
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });

  const ids = useMemo(() => (tokenIds as bigint[] | undefined) ?? [], [tokenIds]);
  const idsKey = useMemo(() => ids.map((id) => id.toString()).join(","), [ids]);
  const enabled = !!address && ids.length > 0;

  const { data: nfts = [], isFetching: isFetchingNFTs } = useQuery<OcelotNFT[]>({
    queryKey: ["nft-gallery", address, idsKey],
    enabled,
    queryFn: async () => {
      const client = createPublicClient({ chain: liskSepolia, transport: http() });
      const results: OcelotNFT[] = [];

      for (const id of ids) {
        try {
          const [uri, raw] = await Promise.all([
            client.readContract({ address: NFT_ADDRESS, abi: NFT_ABI, functionName: "tokenURI", args: [id] }) as Promise<string>,
            client.readContract({ address: NFT_ADDRESS, abi: NFT_ABI, functionName: "getTraits", args: [id] }) as Promise<RawTraits>,
          ]);
          results.push({
            tokenId: Number(id),
            tokenURI: uri,
            traits: {
              furPattern: Number(raw.furPattern),
              eyeColor:   Number(raw.eyeColor),
              background: Number(raw.background),
              accessory:  Number(raw.accessory),
              amount:     raw.amount as bigint,
              recipient:  raw.recipient as string,
              furName: FUR_NAMES[Number(raw.furPattern)] ?? "",
              eyeName: EYE_NAMES[Number(raw.eyeColor)]  ?? "",
              bgName:  BG_NAMES[Number(raw.background)] ?? "",
              accName: ACC_NAMES[Number(raw.accessory)] ?? "",
            },
          });
        } catch {
          continue;
        }
      }

      return results;
    },
  });

  return {
    nfts: enabled ? nfts : [],
    count: ids.length,
    loading: isIdsLoading || (enabled && isFetchingNFTs),
  };
}