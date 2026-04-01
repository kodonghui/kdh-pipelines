---
name: spa-auth-401-over-redirect
description: "Global fetch 401 interceptor breaks unauthenticated pages — skip auth-check and public routes"
user-invocable: false
origin: auto-extracted
---

# SPA Auth Interceptor 401 Over-Redirect

**Extracted:** 2026-04-01
**Context:** React SPA with API auth (Hono RPC, fetch wrapper)

## Problem

1. First-time visitor sees "Session expired" message on login page
2. Signup page immediately redirects back to login
3. Invite accept page (public) can't load

## Root Cause

A global `authFetch` wrapper redirects ALL 401 responses to `/login?expired=1`. But `AuthProvider.checkAuth()` calls `/api/auth/me` on EVERY page mount (including signup, invite). Since unauthenticated users naturally get 401 from auth/me, the interceptor fires incorrectly.

## Solution

```typescript
const authFetch = async (input: RequestInfo | URL, init?: RequestInit) => {
  const res = await fetch(input, init)
  if (res.status === 401) {
    const url = typeof input === 'string' ? input : input instanceof URL ? input.href : input.url
    const isAuthCheck = url.includes('/auth/me')           // ← Normal for logged-out users
    const isAuthRoute = url.includes('/auth/login') || url.includes('/auth/signup')
    const isOnPublicPage = ['/login', '/signup', '/invite/'].some(p => 
      window.location.pathname === p || window.location.pathname.startsWith(p))
    
    // Only redirect when a real session expired mid-use
    if (!isAuthCheck && !isAuthRoute && !isOnPublicPage) {
      window.location.href = '/login?expired=1'
    }
  }
  return res
}
```

## Key Insight

`/api/auth/me` returning 401 is NORMAL for unauthenticated users — it's not "session expired", it's "no session exists". Only redirect on 401 from OTHER API calls (meaning user WAS authenticated and session died).

## When to Use

- React/Vue/Svelte SPA with global fetch interceptor for auth
- Pages that should be accessible without login (signup, invite, public)
- AuthProvider/AuthContext that checks auth state on mount
