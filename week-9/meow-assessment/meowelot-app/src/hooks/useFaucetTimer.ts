import { useState, useEffect } from "react";
import { useReadContract } from "wagmi";
import { TOKEN_ADDRESS, TOKEN_ABI } from "../lib/contracts";

export function useFaucetTimer(address?: `0x${string}`) {
  const [secondsLeft, setSecondsLeft] = useState(0);

  const { data: timeLeft, refetch } = useReadContract({
    address: TOKEN_ADDRESS,
    abi: TOKEN_ABI,
    functionName: "timeUntilNextRequest",
    args: address ? [address] : undefined,
    query: { enabled: !!address, refetchInterval: 30_000 },
  });

  // Sync on-chain value into local state
  useEffect(() => {
    setSecondsLeft(Number(timeLeft ?? 0n));
  }, [timeLeft]);

  // Live countdown tick
  useEffect(() => {
    if (secondsLeft <= 0) return;
    const id = setInterval(() => setSecondsLeft((s) => Math.max(0, s - 1)), 1000);
    return () => clearInterval(id);
  }, [secondsLeft]);

  return { secondsLeft, canClaim: secondsLeft === 0, refetch };
}