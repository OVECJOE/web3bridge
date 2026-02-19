export const encode = (msg: string): bigint => {
  const encoder = new TextEncoder();
  const bytes = encoder.encode(msg)
  return BigInt("0x" + [...bytes].map(b=>b.toString(16).padStart(2,"0")).join(""));
}

export const decode = (num: bigint): string => {
  let hex = num.toString(16);
  if (hex.length % 2 !== 0){
    hex = "0" + hex;
  }
  const bytes = new Uint8Array(hex.match(/.{2}/g)!.map(byte => parseInt(byte, 16)))
  return new TextDecoder("utf-8").decode(bytes);
}