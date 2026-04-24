// Profile / Settings page — demos form primitives + theme picker

const ThemeRadio = ({ id, name, desc, swatches, selected, onSelect }) => (
  <div className={`theme-radio ${selected ? 'selected' : ''}`} onClick={() => onSelect(id)} role="radio" aria-checked={selected} tabIndex={0}>
    <div className="swatches">{swatches.map((s, i) => <span key={i} style={{ background: s }} />)}</div>
    <div>
      <div className="name">{name}</div>
      <div className="desc">{desc}</div>
    </div>
  </div>
);

const Field = ({ label, children }) => (
  <div className="kv-row">
    <div className="label">{label}</div>
    <div className="value">{children}</div>
  </div>
);

const ProfilePage = ({ theme, setTheme }) => (
  <div className="page">
    <h1>프로필 · 환경설정</h1>

    <div className="acard">
      <h3>계정</h3>
      <div className="kv-grid">
        <Field label="이름">김동희</Field>
        <Field label="역할">대표이사 (CEO)</Field>
        <Field label="이메일">dh.kim@corthex.io</Field>
        <Field label="회사">코르텍스 주식회사</Field>
      </div>
    </div>

    <div className="acard">
      <h3>테마</h3>
      <div className="theme-radios">
        <ThemeRadio id="paper"  name="Paper"  desc="기본 · 따뜻한 종이톤"        swatches={['#FAF9F6','#1B2A4A','#ECEEF2']} selected={theme==='paper'}  onSelect={setTheme} />
        <ThemeRadio id="carbon" name="Carbon" desc="다크 · 깊은 그라파이트"       swatches={['#15171B','#5FAEFF','#23262C']} selected={theme==='carbon'} onSelect={setTheme} />
        <ThemeRadio id="signal" name="Signal" desc="액센트 · 영업/마케팅 팀용"    swatches={['#FAF9F6','#C34C12','#ECEEF2']} selected={theme==='signal'} onSelect={setTheme} />
      </div>
    </div>

    <div className="acard">
      <h3>세션</h3>
      <div className="alert info">
        <div>
          <b>자동 잠금</b> — 30분 동안 입력이 없으면 세션이 만료됩니다.
          민감한 데이터를 다루는 콘솔이므로 이 값은 변경할 수 없습니다.
        </div>
      </div>
      <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
        <button className="btn btn-outline">비밀번호 변경</button>
        <button className="btn btn-ghost" style={{ color: 'hsl(var(--destructive))' }}>모든 기기에서 로그아웃</button>
      </div>
    </div>
  </div>
);

Object.assign(window, { ProfilePage });
