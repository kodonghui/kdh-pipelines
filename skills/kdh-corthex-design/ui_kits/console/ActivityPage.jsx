// Activity log — a simple table view showing runs and handoffs.
const ActivityPage = () => {
  const rows = [
    { t: '10:42', agent: '비서',    intent: '매출 분석',       status: 'complete', dur: '4.2s' },
    { t: '10:41', agent: '분석가',  intent: '주간 리포트',     status: 'complete', dur: '3.1s' },
    { t: '10:38', agent: '운영',    intent: '재고 조회',       status: 'complete', dur: '0.9s' },
    { t: '10:22', agent: '법무',    intent: '계약 검토',       status: 'running',  dur: '—' },
    { t: '09:55', agent: '마케팅',  intent: '카피 A/B 생성',    status: 'failed',   dur: '12.4s' },
    { t: '09:12', agent: '비서',    intent: '업무 계획',       status: 'complete', dur: '2.0s' },
  ];
  const pill = (s) => {
    if (s === 'complete') return <span className="badge success">완료</span>;
    if (s === 'running')  return <span className="badge info">실행 중</span>;
    if (s === 'failed')   return <span className="badge" style={{ background: 'hsl(var(--destructive) / 0.1)', color: 'hsl(var(--destructive))' }}>실패</span>;
    return <span className="badge default">{s}</span>;
  };
  return (
    <div className="page" style={{ maxWidth: 960 }}>
      <h1>활동 로그</h1>
      <div className="acard" style={{ padding: 0, overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ background: 'hsl(var(--muted))', borderBottom: '1px solid hsl(var(--border))' }}>
              {['시간','에이전트','의도','상태','지연시간'].map(h => (
                <th key={h} style={{ padding: '10px 16px', textAlign: 'left', font: '600 11px/16px var(--font-sans)', letterSpacing: '0.08em', textTransform: 'uppercase', color: 'hsl(var(--muted-foreground))' }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((r, i) => (
              <tr key={i} style={{ borderBottom: i === rows.length - 1 ? 0 : '1px solid hsl(var(--border))' }}>
                <td style={{ padding: '12px 16px', fontFamily: 'var(--font-mono)', fontSize: 13, color: 'hsl(var(--muted-foreground))', fontVariantNumeric: 'tabular-nums' }}>{r.t}</td>
                <td style={{ padding: '12px 16px', fontSize: 13, fontWeight: 500 }}>{r.agent}</td>
                <td style={{ padding: '12px 16px', fontSize: 13 }}>{r.intent}</td>
                <td style={{ padding: '12px 16px' }}>{pill(r.status)}</td>
                <td style={{ padding: '12px 16px', fontFamily: 'var(--font-mono)', fontSize: 13, color: 'hsl(var(--muted-foreground))', fontVariantNumeric: 'tabular-nums' }}>{r.dur}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

Object.assign(window, { ActivityPage });
