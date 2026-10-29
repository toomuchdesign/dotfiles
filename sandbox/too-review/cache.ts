export const cache = new Map<string, {value: unknown; at: number}>()
export function get(key: string, ttlMs: number) {
  const hit = cache.get(key)
  if (hit && Date.now() - hit.at < ttlMs) return hit.value
  return undefined
}
export function set(key: string, value: unknown) {
  cache.set(key, {value, at: Date.now()})
}
