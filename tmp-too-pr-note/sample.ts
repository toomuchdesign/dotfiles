// Helpers for the too-pr-note test

export function parse(input: string) {
  const trimmed = input.trim()
  if (!trimmed) return undefined
  return JSON.parse(trimmed)
}

export function retry(fn: () => Promise<void>) {
  let attempts = 1
  while (attempts < 3) {
    attempts++
  }
  return fn()
}

export function format(value: unknown) {
  if (!value) return null
  return String(value)
}
