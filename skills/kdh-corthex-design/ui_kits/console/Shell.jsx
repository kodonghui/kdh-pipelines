// AppShell — sidebar + main region. Mirrors packages/app/src/components/layout/app-shell.tsx

const Avatar = ({ initial, size = 22 }) => (
  <span className="ava" style={{ width: size, height: size, fontSize: Math.max(9, size * 0.42) }}>
    {initial}
  </span>
);

const NavItem = ({ icon, label, active, onClick }) => (
  <div className={`nav-item ${active ? 'active' : ''}`} onClick={onClick} role="button" tabIndex={0}>
    {icon}
    <span>{label}</span>
  </div>
);

const AgentNavItem = ({ initial, label, active, onClick }) => (
  <div className={`nav-item ${active ? 'active' : ''}`} onClick={onClick} role="button" tabIndex={0}>
    <Avatar initial={initial} />
    <span>{label}</span>
  </div>
);

const Sidebar = ({ page, setPage, activeAgent, setActiveAgent, agents }) => (
  <aside className="sidebar" aria-label="Primary">
    <div className="brand">corthex</div>

    <div className="sb-search">
      <IconSearch />
      <input placeholder="검색…" aria-label="Search" />
    </div>

    <div style={{ height: 8 }} />

    <div className="sb-group-label">Workspace</div>
    <NavItem icon={<IconHome size={16} />} label="허브"          active={page === 'hub'}      onClick={() => setPage('hub')} />
    <NavItem icon={<IconActivity size={16} />} label="활동 로그"  active={page === 'activity'} onClick={() => setPage('activity')} />
    <NavItem icon={<IconBuilding size={16} />} label="조직도"      active={page === 'org'}      onClick={() => setPage('org')} />
    <NavItem icon={<IconBell size={16} />} label="알림"           active={page === 'notif'}    onClick={() => setPage('notif')} />

    <div className="sb-group-label" style={{ marginTop: 12 }}>Agents</div>
    {agents.map((a) => (
      <AgentNavItem
        key={a.id}
        initial={a.initial}
        label={a.name}
        active={page === 'hub' && activeAgent === a.id}
        onClick={() => { setPage('hub'); setActiveAgent(a.id); }}
      />
    ))}

    <div className="sb-footer">
      <Avatar initial="KD" size={28} />
      <span className="name">김동희</span>
      <IconSettings size={16} style={{ color: 'hsl(var(--muted-foreground))', cursor: 'pointer' }}
        onClick={() => setPage('profile')} />
    </div>
  </aside>
);

Object.assign(window, { Avatar, NavItem, AgentNavItem, Sidebar });
