// Chat screen — hub. Mirrors packages/app/src/pages/hub.tsx
const { useState, useRef, useEffect } = React;

const AGENTS = [
  { id: 'secretary', initial: '비', name: '비서 (Chief of Staff)', role: '의도 분류 · 작업 분배 · 통합',    greeting: '안녕하세요, 김 대표님. 무엇을 도와드릴까요?' },
  { id: 'analysis',  initial: '분', name: '분석가',                  role: '데이터 · 매출 · 리포팅',            greeting: '분석가입니다. 어떤 수치를 보고 싶으신가요?' },
  { id: 'legal',     initial: '법', name: '법무',                    role: '계약 · 검토 · 컴플라이언스',        greeting: '법무 담당입니다. 검토가 필요한 문서를 공유해 주세요.' },
  { id: 'ops',       initial: '운', name: '운영',                    role: '공급망 · 재고 · 프로세스',          greeting: '운영팀입니다. 현재 재고 기준으로 답변드립니다.' },
  { id: 'marketing', initial: '마', name: '마케팅',                  role: '캠페인 · 카피 · 채널',              greeting: '마케팅입니다. 캠페인 목표를 알려주세요.' },
];

// Pre-scripted replies so the demo feels real without an LLM
const REPLIES = {
  secretary: [
    '확인했습니다. 분석가와 운영팀에 병렬로 배정하겠습니다.',
    '작업을 3개 서브태스크로 분할했습니다. 완료되는 대로 종합 보고드리겠습니다.',
    '네, 5분 내로 초안을 준비하겠습니다.',
  ],
  analysis: [
    '이번 주 매출은 전주 대비 +8.3% 증가했습니다. 주 요인은 온라인 채널의 12.7% 성장입니다.',
    '카테고리별 상위 3개를 정리하면: 식품(42%), 생활(28%), 뷰티(14%)입니다.',
  ],
  legal: ['계약서 3조 2항에 유의사항이 있습니다. 재검토가 필요합니다.'],
  ops: ['현재 재고 회전일수는 17일입니다. 안전 재고 수준 이내입니다.'],
  marketing: ['제안하신 카피 3종을 준비했습니다. A/B 테스트로 운영 권장드립니다.'],
};

const SUGGESTIONS = [
  '이번 주 매출 분석해줘',
  '신제품 기획서 초안 만들어줘',
  '거래처 계약서 검토해줘',
  '이번 달 재고 회전율 알려줘',
];

// Agent-to-agent handoff badge between messages
const HandoffMarker = ({ from, to }) => (
  <div className="handoff" role="separator">
    <div className="line" />
    <div className="label">{from} → {to} · handoff</div>
    <div className="line" />
  </div>
);

const Message = ({ m, agent }) => {
  if (m.type === 'handoff') return <HandoffMarker from={m.from} to={m.to} />;
  if (m.role === 'user') {
    return (
      <div className="msg user">
        <div className="bub">{m.text}</div>
        <div className="ts">{m.ts}</div>
      </div>
    );
  }
  return (
    <div className="msg agent">
      <div className="header">
        <Avatar initial={agent.initial} size={24} />
        <span className="name">{agent.name.split(' ')[0]}</span>
        <span className="ts">{m.ts}</span>
      </div>
      <div className={`bub ${m.streaming ? 'cursor' : ''}`}>{m.text}</div>
    </div>
  );
};

const now = () => {
  const d = new Date();
  return `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`;
};

const ChatScreen = ({ activeAgent }) => {
  const agent = AGENTS.find(a => a.id === activeAgent) || AGENTS[0];
  const [msgs, setMsgs] = useState(() => [
    { role: 'agent', text: agent.greeting, ts: '09:12' },
  ]);
  const [input, setInput] = useState('');
  const [busy, setBusy] = useState(false);
  const scrollRef = useRef(null);

  useEffect(() => {
    setMsgs([{ role: 'agent', text: agent.greeting, ts: '09:12' }]);
  }, [activeAgent]);

  useEffect(() => {
    if (scrollRef.current) scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [msgs]);

  const send = (text) => {
    const q = (text ?? input).trim();
    if (!q || busy) return;
    setInput('');
    setBusy(true);
    setMsgs((prev) => [...prev, { role: 'user', text: q, ts: now() }]);

    // Simulate secretary classifying + handing off to analysis
    const pool = REPLIES[agent.id] || REPLIES.secretary;
    const reply = pool[Math.floor(Math.random() * pool.length)];

    setTimeout(() => {
      setMsgs((prev) => [...prev, { role: 'agent', text: '', ts: now(), streaming: true }]);
      // stream it char by char
      let i = 0;
      const tick = () => {
        i += 2;
        setMsgs((prev) => {
          const next = [...prev];
          const last = next[next.length - 1];
          if (last && last.streaming) {
            next[next.length - 1] = { ...last, text: reply.slice(0, i) };
          }
          return next;
        });
        if (i < reply.length) setTimeout(tick, 22);
        else {
          setMsgs((prev) => prev.map((m, idx) => idx === prev.length - 1 ? { ...m, streaming: false } : m));
          setBusy(false);
        }
      };
      tick();
    }, 300);
  };

  const onKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); }
  };

  return (
    <>
      <div className="chat-header">
        <Avatar initial={agent.initial} size={32} />
        <div>
          <div className="agent-name">{agent.name}</div>
          <div className="agent-role">{agent.role}</div>
        </div>
        <div style={{ flex: 1 }} />
        <span className="badge success"><span style={{ width: 6, height: 6, borderRadius: 999, background: 'currentColor' }} /> 가동 중</span>
        <button className="btn btn-ghost btn-icon" aria-label="Settings"><IconSettings size={16} /></button>
      </div>

      <div className="messages" ref={scrollRef}>
        {msgs.map((m, i) => <Message key={i} m={m} agent={agent} />)}
        {msgs.length <= 1 && (
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 8 }}>
            {SUGGESTIONS.map(s => (
              <button key={s} className="btn btn-outline btn-sm" onClick={() => send(s)}>{s}</button>
            ))}
          </div>
        )}
      </div>

      <div className="composer">
        <div className="composer-inner">
          <button className="btn btn-ghost btn-icon" aria-label="Attach"><IconPaperclip size={18} /></button>
          <textarea
            rows={1}
            placeholder={`${agent.name.split(' ')[0]}에게 메시지 보내기…`}
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={onKeyDown}
            disabled={busy}
          />
          <button className="btn btn-primary btn-icon" onClick={() => send()} disabled={!input.trim() || busy} aria-label="Send">
            <IconSend size={16} />
          </button>
        </div>
        <div style={{ fontSize: 11, color: 'hsl(var(--muted-foreground))', marginTop: 8, letterSpacing: '0.01em' }}>
          Enter 전송 · Shift+Enter 줄바꿈 · 비서가 적절한 전문 에이전트에게 자동 분배합니다
        </div>
      </div>
    </>
  );
};

Object.assign(window, { AGENTS, ChatScreen });
