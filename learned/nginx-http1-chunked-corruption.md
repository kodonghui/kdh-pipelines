---
name: nginx-http1-chunked-corruption
description: "Nginx HTTP/1.0 default corrupts chunked responses — appends 'Content-Length: 0' as body text"
user-invocable: false
origin: auto-extracted
---

# Nginx HTTP/1.0 Chunked Response Corruption

**Extracted:** 2026-04-01
**Context:** Bun/Hono server behind nginx reverse proxy, Cloudflare CDN

## Problem

Browser shows blank page or "Content-Length: 0" as visible text. curl returns HTML correctly but raw bytes show `Content-Length: 0\r\n\r\n` appended AFTER the `</html>` closing tag. JS files also corrupted — causes `Unexpected token ':'` error killing React.

## Root Cause

Nginx defaults to HTTP/1.0 for upstream connections. HTTP/1.0 doesn't support `Transfer-Encoding: chunked`. When Bun/Hono sends a chunked response, nginx misinterprets the chunked trailer as body content, appending it literally.

## Solution

```nginx
location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;          # ← THIS FIXES IT
    proxy_set_header Connection "";   # ← Required with 1.1
    proxy_set_header Host $host;
    # ... other headers
}
```

After fixing nginx: if Cloudflare cached the broken JS, rebuild frontend (`npx vite build`) to generate new file hashes and bypass CDN cache.

## Diagnosis Steps

```bash
# 1. Check if body contains the corruption
curl -s http://127.0.0.1:80/ -H "Host: example.com" | xxd | tail -5
# Look for "Content-Length: 0" after </html>

# 2. Compare local (no nginx) vs nginx
curl -s http://localhost:3000/ | grep -c "Content-Length"  # should be 0
curl -s http://127.0.0.1:80/ -H "Host: ..." | grep -c "Content-Length"  # if 1, nginx is corrupting

# 3. Check JS files too
curl -s https://example.com/assets/index-*.js | tail -c 50  # should NOT end with "Content-Length: 0"
```

## When to Use

- Blank page in browser but curl returns HTML
- "Content-Length: 0" visible as text on page
- JS `Unexpected token ':'` error with no obvious syntax issue
- Works on localhost but breaks through nginx/Cloudflare
