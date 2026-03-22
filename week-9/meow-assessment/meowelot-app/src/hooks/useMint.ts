import { useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { TOKEN_ADDRESS, TOKEN_ABI } from "../lib/contracts";

export function useMint() {
  const { writeContractAsync, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  async function mint(to: `0x${string}`, amount: bigint) {
    return writeContractAsync({
      address: TOKEN_ADDRESS,
      abi: TOKEN_ABI,
      functionName: "mint",
      args: [to, amount],
    });
  }

  return { mint, hash, isPending, isConfirming, isSuccess };
}