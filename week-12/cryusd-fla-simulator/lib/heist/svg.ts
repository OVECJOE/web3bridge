export function createAgentSpriteDataUri(accent: string) {
  if (typeof window === "undefined") {
    return ""
  }

  const source = `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96">
  <defs>
    <linearGradient id="glassGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="rgba(255,255,255,0.9)"/>
      <stop offset="100%" stop-color="${accent}"/>
    </linearGradient>
  </defs>
  <circle id="ring" cx="48" cy="48" r="40" fill="none" stroke="url(#glassGrad)" stroke-width="6"/>
  <rect id="visor" x="28" y="34" width="40" height="22" rx="5" fill="rgba(8,12,18,0.88)" stroke="rgba(255,255,255,0.85)" stroke-width="2"/>
  <path id="body" d="M30 64 L66 64 L60 84 L36 84 Z" fill="url(#glassGrad)"/>
  <circle cx="40" cy="45" r="3" fill="rgba(255,255,255,0.85)"/>
  <circle cx="56" cy="45" r="3" fill="rgba(255,255,255,0.85)"/>
</svg>
`

  const parser = new DOMParser()
  const xml = parser.parseFromString(source, "image/svg+xml")

  const ring = xml.getElementById("ring")
  if (ring) {
    ring.setAttribute("stroke-width", "6")
  }

  const serializer = new XMLSerializer()
  const normalized = serializer.serializeToString(xml)
  return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(normalized)}`
}
