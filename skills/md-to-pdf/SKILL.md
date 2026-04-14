# /md-to-pdf — Markdown → PDF 변환 스킬

## 트리거
- `/md-to-pdf [파일]`
- "md를 pdf로", "마크다운 pdf로", "pdf로 변환", "pdf 뽑아줘"

## 핵심: WSL 환경에서는 반드시 PowerShell로 실행

WSL에서 Linux Chrome이 의존성 라이브러리 없이 실행 불가. Windows Chrome을 사용해야 하므로 **powershell.exe로 실행**한다.
또한 cmd/powershell에서 `--css` 인라인 전달 시 공백이 토큰 분리되어 깨짐. **CSS는 반드시 파일로 전달** (`--stylesheet`).

## 실행 절차

### Step 1. 입력 파싱

- 인자 없으면 현재 디렉토리 .md 파일 목록 보여주고 물어본다
- 인자 있으면 해당 파일 변환

### Step 2. CSS 파일 생성

변환 전에 임시 CSS 파일을 대상 .md 파일과 같은 디렉토리에 생성한다:

```bash
cat > /path/to/같은디렉토리/_pdf-style.css << 'EOF'
body { font-family: "Malgun Gothic", "맑은 고딕", "나눔고딕", sans-serif; font-size: 12px; line-height: 1.9; }
h1,h2,h3 { color: #1a1a2e; }
table { border-collapse: collapse; width: 100%; }
td,th { border: 1px solid #ddd; padding: 8px; }
th { background: #f4f4f4; }
code, pre { font-family: "D2Coding", "Consolas", monospace; font-size: 11px; }
EOF
```

### Step 3. PowerShell로 변환 실행

WSL 경로를 Windows 경로로 변환해서 실행:

```bash
# WSL 경로 -> Windows 경로 변환
WIN_DIR=$(wslpath -w "/path/to/같은디렉토리")

# PowerShell로 실행 (--stylesheet로 CSS 파일 전달)
powershell.exe -Command "cd '${WIN_DIR}'; md-to-pdf 파일.md --stylesheet _pdf-style.css"
```

**절대 `--css` 인라인으로 전달하지 말 것.** PowerShell/cmd에서 공백+따옴표가 깨진다.
**절대 WSL bash에서 직접 md-to-pdf 실행하지 말 것.** Linux Chrome 의존성 없어서 실패한다.

### Step 4. 정리 + 결과 보고

```bash
# 임시 CSS 삭제
rm /path/to/같은디렉토리/_pdf-style.css

# 필요하면 PDF를 다른 디렉토리로 복사
cp /path/to/같은디렉토리/파일.pdf /target/path/
```

```
PDF 변환 완료
  입력: 파일.md
  출력: 파일.pdf
  크기: NNkB
```

## 전체 예시 (복붙용)

```bash
# 1. CSS 파일 생성
cat > "/mnt/c/Users/USER/Desktop/셀렉트스타 업무/독파모/docs/reports/_pdf-style.css" << 'EOF'
body { font-family: "Malgun Gothic", "맑은 고딕", "나눔고딕", sans-serif; font-size: 12px; line-height: 1.9; }
h1,h2,h3 { color: #1a1a2e; }
table { border-collapse: collapse; width: 100%; }
td,th { border: 1px solid #ddd; padding: 8px; }
th { background: #f4f4f4; }
code, pre { font-family: "D2Coding", "Consolas", monospace; font-size: 11px; }
EOF

# 2. PowerShell로 변환
powershell.exe -Command "cd 'C:\Users\USER\Desktop\셀렉트스타 업무\독파모\docs\reports'; md-to-pdf report.md --stylesheet _pdf-style.css"

# 3. 정리
rm "/mnt/c/Users/USER/Desktop/셀렉트스타 업무/독파모/docs/reports/_pdf-style.css"
```

## 옵션 레퍼런스

| 옵션 | 설명 | 주의 |
|------|------|------|
| `--stylesheet` | 외부 CSS 파일 | WSL에서는 이것만 사용 |
| `--css` | 인라인 CSS | WSL에서 사용 금지 (파싱 깨짐) |
| `--highlight-style` | 코드 하이라이팅 | `github`, `monokai`, `dracula` |
| `--pdf-options` | 페이지 설정 JSON | PowerShell에서 이스케이핑 어려움. 필요하면 CSS에 @page로 대체 |
| `--watch` | 파일 변경 감시 | |

## 설치 정보

- 이미 설치됨: `C:\Users\USER\AppData\Roaming\npm\md-to-pdf`
- Puppeteer Chrome: `~/.cache/puppeteer/chrome/` (WSL용, 실제로는 안 씀)
- Windows Chrome: `C:\Program Files\Google\Chrome\Application\chrome.exe` (PowerShell 실행 시 자동 사용)

## 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| `libnspr4.so: cannot open` | WSL Linux Chrome 의존성 없음 | PowerShell로 실행 |
| CSS가 파일명으로 인식됨 | cmd/powershell 공백 파싱 | `--stylesheet` 파일 방식 사용 |
| `ECONNREFUSED` | WSL에서 Windows Chrome 직접 연결 불가 | PowerShell로 실행 |
| `--dest` 옵션 에러 | md-to-pdf 5.x에서 제거됨 | 변환 후 cp로 복사 |
| JSON parse error | `--pdf-options` 이스케이핑 | CSS에 `@page { size: A4; margin: 25mm; }` 사용 |
