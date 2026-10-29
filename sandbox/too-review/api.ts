import {get, set} from './cache'
export async function fetchUser(id: string, token: string) {
  const cached = get(id, 60_000)
  if (cached) return cached
  const res = await fetch(`https://api.example.com/users/${id}?token=${token}`)
  const user = await res.json()
  set(id, user)
  return user
}
