import { binexpmod } from './exp.ts'

export const mod = (x: bigint,m:bigint): bigint => {
  return x%m 
}

export const gcd = (a: bigint,b: bigint) => {
  if (b == 0n) return a;
  else return gcd(b,mod(a,b))
}

export const modinverse = (a: bigint,m: bigint) => {
  if (gcd(a,m) !== 1n) return 0n  
  else {
    return  binexpmod(a,m-2n,m)
  }
}
export const modinverse_un = (a,m) => {
  return  binexpmod(a,m-2n,m)
}