import { useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { TOKEN_ADDRESS, TOKEN_ABI } from "../lib/contracts";

export function useTransfer() {
  const { writeContractAsync, data: hash, isPending } = useWriteContract();
  const { data: receipt, isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  async function transfer(to: `0x${string}`, amount: bigint) {
    return writeContractAsync({
      address: TOKEN_ADDRESS,
      abi: TOKEN_ABI,
      functionName: "transfer",
      args: [to, amount],
    });
  }

  return { transfer, hash, receipt, isPending, isConfirming, isSuccess };
}