# kdh-claude-browser-use

Claude 네이티브 브라우저 러너 — Claude CLI + Playwright MCP로 직접 브라우저 제어.

## 왜 만들었나

browser-use 라이브러리의 BaseChatModel adapter 방식은 Claude와 비호환:
- CLI one-shot = 12초/step (timeout)
- ClaudeSDKClient = structured output 파싱 실패
- 결과: Claude sweep이 로그인도 못 하고 종료

이 도구는 Claude Agent SDK의 본연 방식(에이전트 + MCP 도구)으로 브라우저를 제어.

## 사용법

```bash
# 필수 조건: Claude CLI 로그인 + npx 설치
python3.11 kdh_claude_browser_use.py --url http://localhost:5173/admin
```

## 환경 변수

| 변수 | 필수 | 설명 |
|------|------|------|
| SWEEP_EMAIL | 선택 | 로그인 이메일 (기본: sweep-{timestamp}@test.com) |
| SWEEP_PASSWORD | 선택 | 로그인 비밀번호 (기본: SweepTest123!) |

- API 키 불필요 — Claude CLI의 OAuth 로그인 사용
- ANTHROPIC_API_KEY 환경변수 제거 필수 (있으면 OAuth 대신 Messages API로 잘못 라우팅)

## 의존성

- Claude CLI (`claude` binary, OAuth 로그인 완료 상태)
- `npx @playwright/mcp@latest` (Playwright MCP 서버)
- `contracts.py` (SweepResult Pydantic 모델)

## 결과

`SweepResult` JSON 파일 출력 → `sweep-merge.py`로 3사 병합 가능.

## 벤치마크 (2026-04-16)

| 항목 | browser-use adapter | kdh-claude-browser-use |
|------|-------------------|----------------------|
| 시간 | 49분 (로그인 실패) | **6.5분** |
| 페이지 | 0개 | 8개 |
| 버그 | 0개 | 8개 |
| 방식 | CLI one-shot 12초/step | CLI+MCP 5.3초/turn |
