import { useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { TOKEN_ADDRESS, TOKEN_ABI } from "../lib/contracts";

export function useRequestToken() {
  const { writeContractAsync, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  async function requestToken() {
    return writeContractAsync({
      address: TOKEN_ADDRESS,
      abi: TOKEN_ABI,
      functionName: "requestToken",
    });
  }

  return { requestToken, hash, isPending, isConfirming, isSuccess };
}