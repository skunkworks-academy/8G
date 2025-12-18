# ============================================
# Upgrade /docs into Self-Paced "Quiz Wall" site
# Course: 8G103G Guardium Data Protection Fundamentals
# Run from repo root: ...\skunkworks-academy\8G
#
# This script:
# - Creates/overwrites self-paced pages in /docs:
#   index.html, final.html, module01..module10.html
# - Creates shared engine + styles in /docs/assets:
#   app.js, styles.css
# - Uses existing pools in /docs/assets/data/module-XX-pool.json
#
# Notes:
# - No emojis (PowerShell parser-safe)
# - Vanilla HTML/CSS/JS (GitHub Pages friendly)
# ============================================

$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$path) {
  if (!(Test-Path $path)) {
    New-Item -ItemType Directory -Path $path | Out-Null
  }
}

function Write-File([string]$path, [string]$content) {
  $dir = Split-Path $path -Parent
  Ensure-Dir $dir
  Set-Content -Path $path -Value $content -Encoding UTF8
}

# --- Ensure directories ---
Ensure-Dir ".\docs"
Ensure-Dir ".\docs\assets"
Ensure-Dir ".\docs\assets\data"

# --- Self-paced WALL ---
Write-File ".\docs\index.html" @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>8G103G — Quiz Wall</title>
  <link rel="stylesheet" href="assets/styles.css">
</head>
<body class="no-select">
  <header class="topbar">
    <div class="wrap">
      <div class="brand">
        <span class="badge">Skunkworks Academy</span>
        <span class="badge">8G103G</span>
        <span class="badge">Self-Paced Course</span>
      </div>
      <h1>Guardium Data Protection Fundamentals — Quiz Wall</h1>
      <p class="sub">
        Complete Modules 01–10. Each attempt draws a randomized subset from the module pool, shuffles options,
        enforces a timer and attempt limits, and provides detailed remediation.
      </p>
      <div class="actions">
        <button class="btn good" id="exportAllBtn">Export All Progress (JSON)</button>
        <button class="btn" id="importBtn">Import Progress (JSON)</button>
        <input type="file" id="importFile" accept="application/json" hidden>
        <button class="btn bad" id="resetAllBtn">Reset All</button>
        <a class="btn primary" href="final.html">Final Review</a>
      </div>
    </div>
  </header>

  <main class="wrap">
    <section class="panel">
      <div class="kpis" id="kpis"></div>
      <div class="hr"></div>
      <h2>Modules</h2>
      <div class="grid" id="wall"></div>
    </section>

    <footer class="footer">
      Static-only delivery (GitHub Pages). Deterrents reduce casual cheating but cannot prevent a determined user.
    </footer>
  </main>

  <script src="assets/app.js"></script>
  <script>
    window.addEventListener('DOMContentLoaded', () => {
      CourseApp.enableDeterrents({ watermarkText: '8G103G | Skunkworks Academy', fullscreenOptional: true });

      CourseApp.renderWall({ mountId: 'wall', kpiId: 'kpis' });

      document.getElementById('exportAllBtn').addEventListener('click', () => CourseApp.exportAll());

      document.getElementById('resetAllBtn').addEventListener('click', () => {
        if (confirm('Reset all modules on this browser?')) {
          CourseApp.resetAll();
          location.reload();
        }
      });

      const importBtn = document.getElementById('importBtn');
      const importFile = document.getElementById('importFile');

      importBtn.addEventListener('click', () => importFile.click());

      importFile.addEventListener('change', async (e) => {
        const f = e.target.files && e.target.files[0];
        if (!f) return;
        try {
          await CourseApp.importAll(await f.text());
          location.reload();
        } catch (err) {
          alert('Import failed: ' + err.message);
        } finally {
          importFile.value = '';
        }
      });
    });
  </script>
</body>
</html>
"@

# --- FINAL REVIEW ---
Write-File ".\docs\final.html" @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>8G103G — Final Review</title>
  <link rel="stylesheet" href="assets/styles.css">
</head>
<body class="no-select">
  <header class="topbar">
    <div class="wrap">
      <div class="brand">
        <span class="badge">8G103G</span>
        <span class="badge">Final Review</span>
      </div>
      <h1>Final Review & Mastery Recap</h1>
      <p class="sub">Unlocked only when all modules are completed (mastery threshold met).</p>
      <div class="actions">
        <a class="btn" href="index.html">Back to Wall</a>
        <button class="btn good" id="exportFinalBtn">Export Final JSON</button>
        <button class="btn bad" id="resetAllBtn">Reset All</button>
      </div>
    </div>
  </header>

  <main class="wrap">
    <section class="panel" id="finalMount"></section>
    <footer class="footer">
      Evidence note: exports contain attempt history, timestamps, answers, and scoring.
    </footer>
  </main>

  <script src="assets/app.js"></script>
  <script>
    window.addEventListener('DOMContentLoaded', () => {
      CourseApp.enableDeterrents({ watermarkText: '8G103G | Final Review', fullscreenOptional: false });

      CourseApp.renderFinal({ mountId: 'finalMount' });

      document.getElementById('exportFinalBtn').addEventListener('click', () => CourseApp.exportFinal());

      document.getElementById('resetAllBtn').addEventListener('click', () => {
        if (confirm('Reset all modules on this browser?')) {
          CourseApp.resetAll();
          location.href = 'index.html';
        }
      });
    });
  </script>
</body>
</html>
"@

# --- MODULE PAGES 01..10 ---
1..10 | ForEach-Object {
  $m = $_.ToString("00")
  Write-File ".\docs\module$m.html" @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>8G103G — Module $m</title>
  <link rel="stylesheet" href="assets/styles.css">
</head>
<body class="no-select">
  <div class="antiCheatBanner">
    Focus required. Switching tabs/windows may blur content. Copy/paste and context menu are blocked (best-effort).
  </div>

  <header class="topbar">
    <div class="wrap">
      <div class="brand">
        <span class="badge">8G103G</span>
        <span class="badge">Module $m</span>
      </div>
      <h1 id="modTitle">Module $m Quiz</h1>
      <p class="sub" id="modMeta"></p>

      <div class="actions">
        <a class="btn" href="index.html">Wall</a>
        <a class="btn primary" href="final.html">Final</a>
        <button class="btn" id="fullscreenBtn">Fullscreen</button>
        <button class="btn bad" id="resetBtn">Reset Module</button>
      </div>
    </div>
  </header>

  <main class="wrap">
    <section class="panel">
      <div class="kpis" id="attemptKpis"></div>
      <div class="hr"></div>

      <div id="quizMount"></div>

      <div class="hr"></div>
      <div class="actions">
        <button class="btn good" id="exportBtn">Export Module JSON</button>
      </div>
    </section>

    <footer class="footer">
      Timer auto-submits on expiry. Attempt limits are enforced per browser only.
    </footer>
  </main>

  <script src="assets/app.js"></script>
  <script>
    window.addEventListener('DOMContentLoaded', async () => {
      CourseApp.enableDeterrents({
        watermarkText: '8G103G | Module $m',
        fullscreenOptional: true,
        blurOnFocusLoss: true
      });

      await CourseApp.renderModule({
        moduleId: '$m',
        mountId: 'quizMount',
        titleId: 'modTitle',
        metaId: 'modMeta',
        kpiId: 'attemptKpis',
        poolUrl: 'assets/data/module-$m-pool.json',
        config: {
          poolSize: 30,
          pickCount: 10,
          timeLimitSeconds: 10 * 60,
          attemptLimit: 3,
          masteryPct: 80
        }
      });

      document.getElementById('exportBtn').addEventListener('click', () => CourseApp.exportModule('$m'));

      document.getElementById('resetBtn').addEventListener('click', () => {
        if (confirm('Reset Module $m progress on this browser?')) {
          CourseApp.resetModule('$m');
          location.reload();
        }
      });

      document.getElementById('fullscreenBtn').addEventListener('click', () => CourseApp.requestFullscreen());
    });
  </script>
</body>
</html>
"@
}

# --- STYLES ---
Write-File ".\docs\assets\styles.css" @"
:root{
  --bg:#0b1020; --text:#e9ecff; --muted:#b9c0ff;
  --accent:#7aa2ff; --good:#4ade80; --bad:#fb7185; --warn:#fbbf24;
  --border:rgba(255,255,255,.12);
  --shadow: 0 20px 60px rgba(0,0,0,.35);
  --radius: 18px;
  --mono: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono","Courier New", monospace;
  --sans: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial;
}
*{box-sizing:border-box}
html,body{height:100%}
body{
  margin:0;
  font-family:var(--sans);
  background: radial-gradient(1200px 800px at 10% 10%, rgba(122,162,255,.22), transparent 55%),
              radial-gradient(900px 650px at 90% 20%, rgba(74,222,128,.14), transparent 55%),
              radial-gradient(900px 650px at 60% 110%, rgba(251,113,133,.12), transparent 55%),
              var(--bg);
  color:var(--text);
}
a{color:inherit;text-decoration:none}

.wrap{max-width:1200px;margin:0 auto;padding:18px}
.topbar{
  position:sticky;top:0;z-index:20;
  background:rgba(11,16,32,.72);
  backdrop-filter: blur(12px);
  border-bottom:1px solid var(--border);
}
.brand{display:flex;gap:10px;align-items:center;flex-wrap:wrap}
.badge{
  font-family:var(--mono);
  font-size:12px;
  padding:6px 10px;
  border-radius:999px;
  border:1px solid var(--border);
  color:var(--muted);
}
h1{margin:10px 0 6px 0;font-size:clamp(22px,4vw,34px);line-height:1.15}
h2{margin:0 0 10px 0}
.sub{color:var(--muted);max-width:90ch;line-height:1.55;margin:0 0 12px 0}

.panel{
  background: linear-gradient(180deg, rgba(255,255,255,.06), rgba(255,255,255,.03));
  border:1px solid var(--border);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  padding:16px;
}
.actions{display:flex;gap:10px;flex-wrap:wrap;align-items:center;margin:12px 0 0 0}
.btn{
  appearance:none; border:1px solid var(--border);
  background: rgba(255,255,255,.06);
  color: var(--text);
  padding:10px 12px;
  border-radius: 12px;
  cursor:pointer;
  transition: transform .08s ease, background .12s ease;
  font-weight:700;
}
.btn:hover{background: rgba(255,255,255,.10)}
.btn:active{transform: scale(.98)}
.btn.primary{border-color: rgba(122,162,255,.6); background: rgba(122,162,255,.14)}
.btn.good{border-color: rgba(74,222,128,.6); background: rgba(74,222,128,.12)}
.btn.bad{border-color: rgba(251,113,133,.6); background: rgba(251,113,133,.12)}

.hr{height:1px;background:var(--border);margin:14px 0}
.grid{display:grid;grid-template-columns: repeat(12, 1fr);gap:12px}
.tile{
  grid-column: span 12;
  background: rgba(255,255,255,.04);
  border:1px solid var(--border);
  border-radius: 14px;
  padding:14px;
  display:flex;align-items:center;justify-content:space-between;gap:12px;
}
.tile .left{display:flex;flex-direction:column;gap:6px}
.tile .title{font-weight:800}
.tile .meta{color:var(--muted);font-size:12px}
.pill{
  font-family:var(--mono);
  font-size:12px;
  padding:6px 10px;
  border-radius:999px;
  border:1px solid var(--border);
  color:var(--muted);
}
.pill.good{border-color: rgba(74,222,128,.6); color: rgba(210,255,226,.95)}
.pill.warn{border-color: rgba(251,191,36,.65); color: rgba(255,238,200,.95)}
.pill.bad{border-color: rgba(251,113,133,.65); color: rgba(255,220,228,.95)}

.kpis{display:flex;gap:12px;flex-wrap:wrap}
.kpi{
  flex: 1 1 220px;
  background: rgba(255,255,255,.04);
  border:1px solid var(--border);
  border-radius: 14px;
  padding:14px;
}
.kpi .label{color:var(--muted);font-size:12px}
.kpi .value{font-size:22px;margin-top:6px}

.question{
  background: rgba(255,255,255,.04);
  border:1px solid var(--border);
  border-radius: 14px;
  padding:14px;
  margin:12px 0;
}
.choice{
  display:flex;gap:10px;align-items:flex-start;
  padding:10px;border-radius:12px;border:1px solid var(--border);
  margin:8px 0;background: rgba(0,0,0,.10)
}
.choice input{margin-top:4px}
.explain{
  margin-top:10px;
  padding:10px 12px;
  border-radius:12px;
  border:1px solid var(--border);
  background: rgba(0,0,0,.14);
}
.explain.good{border-color: rgba(74,222,128,.55)}
.explain.bad{border-color: rgba(251,113,133,.55)}

.timer{
  font-family:var(--mono);
  padding:6px 10px;
  border-radius:999px;
  border:1px solid var(--border);
  display:inline-block;
}

.footer{padding:26px 0;color:var(--muted);font-size:12px}

@media (min-width: 820px){ .tile{grid-column: span 6} }
@media (min-width: 1060px){ .tile{grid-column: span 4} }

/* Deterrents (best-effort) */
.no-select, .no-select * { user-select:none !important; -webkit-user-select:none !important; }
.antiCheatBanner{
  position:sticky;top:0;z-index:30;
  font-size:12px;
  padding:8px 12px;
  background: rgba(251,191,36,.12);
  border-bottom:1px solid rgba(251,191,36,.35);
  color: rgba(255,238,200,.95);
  backdrop-filter: blur(10px);
}
.blurAll #quizMount, .blurAll #finalMount, .blurAll .panel {
  filter: blur(6px);
  pointer-events:none;
}
.watermark{
  position:fixed;inset:0;z-index:9999;
  pointer-events:none;
  opacity:.10;
  font-family:var(--mono);
  font-size:18px;
  display:flex;
  align-items:center;
  justify-content:center;
  transform: rotate(-18deg);
  white-space:pre-wrap;
  text-align:center;
}
"@

# --- ENGINE ---
Write-File ".\docs\assets\app.js" @"
'use strict';

(function(global){

  const APP = {
    course: '8G103G',
    modules: Array.from({length:10},(_,i)=> String(i+1).padStart(2,'0')),
    storeKey: '8G103G_QUIZ_WALL_V1'
  };

  function nowIso(){ return new Date().toISOString(); }

  function loadState(){
    try{
      const raw = localStorage.getItem(APP.storeKey);
      if(!raw) return { course: APP.course, createdAt: nowIso(), updatedAt: nowIso(), modules:{} };
      const obj = JSON.parse(raw);
      if(!obj.modules) obj.modules = {};
      return obj;
    }catch(e){
      return { course: APP.course, createdAt: nowIso(), updatedAt: nowIso(), modules:{} };
    }
  }

  function saveState(s){
    s.updatedAt = nowIso();
    localStorage.setItem(APP.storeKey, JSON.stringify(s));
  }

  function resetAll(){
    localStorage.removeItem(APP.storeKey);
  }

  function resetModule(moduleId){
    const s = loadState();
    delete s.modules[moduleId];
    saveState(s);
  }

  function downloadJson(filename, obj){
    const blob = new Blob([JSON.stringify(obj, null, 2)], {type:'application/json'});
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = filename;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  }

  function escapeHtml(s){
    return String(s).replace(/[&<>"']/g, m => ({
      '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'
    }[m]));
  }

  function fmtTime(sec){
    sec = Math.max(0, Math.floor(sec||0));
    const m = Math.floor(sec/60), s = sec%60;
    return m>0 ? `${m}m ${s}s` : `${s}s`;
  }

  function seededShuffle(arr, seed){
    let a = arr.slice();
    let s = seed >>> 0;
    function rnd(){ s ^= s<<13; s ^= s>>>17; s ^= s<<5; return (s>>>0)/4294967296; }
    for(let i=a.length-1;i>0;i--){
      const j = Math.floor(rnd()*(i+1));
      [a[i],a[j]]=[a[j],a[i]];
    }
    return a;
  }

  function deriveSeed(){
    const t = Date.now();
    const r = Math.floor(Math.random()*1e9);
    return (t ^ r) >>> 0;
  }

  function shuffleOptions(question, seed){
    const idxs = [0,1,2,3];
    const shuffledIdxs = seededShuffle(idxs, seed);
    const newChoices = shuffledIdxs.map(i => question.choices[i]);

    const oldCorrect = question.answerIndex;
    const newCorrect = shuffledIdxs.indexOf(oldCorrect);

    const oldIncorrect = question.explainIncorrect || {};
    const newIncorrect = {};
    shuffledIdxs.forEach((oldIdx, newIdx) => {
      if (oldIdx !== oldCorrect) {
        const txt = oldIncorrect[String(oldIdx)];
        if (txt != null) newIncorrect[String(newIdx)] = txt;
      }
    });

    return {
      ...question,
      choices: newChoices,
      answerIndex: newCorrect,
      explainIncorrect: newIncorrect
    };
  }

  async function fetchPool(poolUrl){
    const res = await fetch(poolUrl, {cache:'no-store'});
    if(!res.ok) throw new Error('Failed to load pool: ' + poolUrl);
    return await res.json();
  }

  function ensureModuleRecord(state, moduleId){
    if(!state.modules[moduleId]){
      state.modules[moduleId] = {
        attempts: 0,
        completed: false,
        bestScorePct: null,
        totalTimeSec: 0,
        lastAttemptAt: null,
        history: []
      };
    }
    return state.modules[moduleId];
  }

  function computeTotals(state){
    let attempts=0, completed=0, bestSum=0, bestCount=0, time=0;
    APP.modules.forEach(m=>{
      const mod = state.modules[m];
      if(!mod) return;
      attempts += (mod.attempts||0);
      time += (mod.totalTimeSec||0);
      if(mod.completed) completed++;
      if(mod.bestScorePct != null){ bestSum += mod.bestScorePct; bestCount++; }
    });
    return {
      attempts,
      completed,
      avgBest: bestCount ? Math.round(bestSum/bestCount) : 0,
      time
    };
  }

  function moduleStatusPill(mod){
    if(!mod || (mod.attempts||0)===0) return `<span class="pill">NOT DONE</span>`;
    if(mod.completed) return `<span class="pill good">DONE</span>`;
    return `<span class="pill warn">IN PROGRESS</span>`;
  }

  function renderWall({mountId, kpiId}){
    const state = loadState();
    const totals = computeTotals(state);

    const kpiEl = document.getElementById(kpiId);
    if(kpiEl){
      const rate = Math.round((totals.completed/APP.modules.length)*100);
      kpiEl.innerHTML = `
        <div class="kpi"><div class="label">Modules completed</div><div class="value">${totals.completed}/${APP.modules.length} (${rate}%)</div></div>
        <div class="kpi"><div class="label">Attempts</div><div class="value">${totals.attempts}</div></div>
        <div class="kpi"><div class="label">Average best</div><div class="value">${totals.avgBest}%</div></div>
        <div class="kpi"><div class="label">Time-on-task</div><div class="value">${fmtTime(totals.time)}</div></div>
      `;
    }

    const wall = document.getElementById(mountId);
    wall.innerHTML = '';

    APP.modules.forEach(m=>{
      const mod = state.modules[m];
      const best = mod?.bestScorePct ?? 0;
      const at = mod?.attempts ?? 0;
      const meta = (at===0) ? 'No attempts yet' : `Attempts: ${at} | Best: ${best}% | Time: ${fmtTime(mod.totalTimeSec||0)}`;

      const tile = document.createElement('div');
      tile.className = 'tile';
      tile.innerHTML = `
        <div class="left">
          <div class="title">Module ${m}</div>
          <div class="meta">${meta}</div>
        </div>
        <div class="actions">
          ${moduleStatusPill(mod)}
          <a class="btn primary" href="module${m}.html">Open quiz</a>
        </div>
      `;
      wall.appendChild(tile);
    });
  }

  async function renderModule({moduleId, mountId, titleId, metaId, kpiId, poolUrl, config}){
    const state = loadState();
    const mod = ensureModuleRecord(state, moduleId);

    const seed = deriveSeed();
    const startedAt = Date.now();
    const pool = await fetchPool(poolUrl);

    const allQ = pool.questions || [];
    const poolSize = config.poolSize || allQ.length;
    const pickCount = config.pickCount || Math.min(10, poolSize);

    const attemptLimit = config.attemptLimit ?? 3;
    const masteryPct = config.masteryPct ?? 80;

    const titleEl = document.getElementById(titleId);
    if(titleEl) titleEl.textContent = pool.title || `Module ${moduleId} Quiz`;

    const metaEl = document.getElementById(metaId);
    if(metaEl){
      metaEl.innerHTML = `
        Pool: <b>${allQ.length}</b> | Attempt limit: <b>${attemptLimit}</b> | Mastery: <b>${masteryPct}%</b> |
        Questions per attempt: <b>${pickCount}</b> | Time limit: <b>${Math.round((config.timeLimitSeconds||0)/60)} min</b>
      `;
    }

    const kpiEl = document.getElementById(kpiId);
    if(kpiEl){
      const status = mod.completed ? 'DONE' : (mod.attempts>0 ? 'IN PROGRESS' : 'NOT DONE');
      kpiEl.innerHTML = `
        <div class="kpi"><div class="label">Status</div><div class="value">${status}</div></div>
        <div class="kpi"><div class="label">Attempts used</div><div class="value">${mod.attempts}/${attemptLimit}</div></div>
        <div class="kpi"><div class="label">Best score</div><div class="value">${mod.bestScorePct ?? 0}%</div></div>
        <div class="kpi"><div class="label">Time-on-task</div><div class="value">${fmtTime(mod.totalTimeSec||0)}</div></div>
      `;
    }

    const mount = document.getElementById(mountId);
    mount.innerHTML = '';

    if(mod.attempts >= attemptLimit && !mod.completed){
      mount.innerHTML = `
        <div class="question">
          <div><b>Attempt limit reached for this browser.</b></div>
          <div class="meta">You cannot submit a new attempt here. Reset module (if allowed) or use instructor process.</div>
          <div class="hr"></div>
          <a class="btn" href="index.html">Back to Wall</a>
        </div>
      `;
      return;
    }

    const subset = seededShuffle(allQ.slice(0, poolSize), seed)
      .slice(0, pickCount)
      .map((q, i) => shuffleOptions(q, seed + i + 17));

    const answers = {};
    let submitted = false;

    const timeLimit = config.timeLimitSeconds || 0;
    let remaining = timeLimit;
    let timerHandle = null;

    const header = document.createElement('div');
    header.className = 'question';
    header.innerHTML = `
      <div style="display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap;align-items:center">
        <div>
          <div><b>Attempt seed:</b> <span style="font-family:var(--mono)">${seed}</span></div>
          <div class="meta">Answer all questions then submit.</div>
        </div>
        <div>
          <span class="timer" id="timer">${timeLimit ? fmtTime(remaining) : 'No timer'}</span>
          <button class="btn good" id="submitBtn">Submit</button>
        </div>
      </div>
    `;
    mount.appendChild(header);

    function tick(){
      if(submitted) return;
      remaining--;
      const tEl = document.getElementById('timer');
      if(tEl) tEl.textContent = fmtTime(remaining);
      if(remaining <= 0){
        submit(true);
      }
    }
    if(timeLimit){
      timerHandle = setInterval(tick, 1000);
    }

    subset.forEach((q, idx)=>{
      const qEl = document.createElement('div');
      qEl.className = 'question';
      qEl.innerHTML = `
        <div style="display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap">
          <div><b>${idx+1}. ${escapeHtml(q.prompt)}</b></div>
          <span class="pill">ID: ${escapeHtml(q.id)}</span>
        </div>
        <div class="meta">Tags: ${(q.tags||[]).map(escapeHtml).join(', ')}</div>
        <div class="hr"></div>
        <div class="choices"></div>
        <div class="explainWrap"></div>
      `;
      const choices = qEl.querySelector('.choices');

      q.choices.forEach((c, i)=>{
        const row = document.createElement('label');
        row.className = 'choice';
        row.innerHTML = `
          <input type="radio" name="${q.id}" value="${i}">
          <div><b>${String.fromCharCode(65+i)}.</b> ${escapeHtml(c)}</div>
        `;
        row.addEventListener('click', ()=>{
          if(submitted) return;
          answers[q.id] = i;
        });
        choices.appendChild(row);
      });

      mount.appendChild(qEl);
    });

    const resultEl = document.createElement('div');
    resultEl.id = 'results';
    mount.appendChild(resultEl);

    function submit(auto=false){
      if(submitted) return;
      submitted = true;
      if(timerHandle) clearInterval(timerHandle);

      let correct = 0;
      const perQuestion = [];
      subset.forEach(q=>{
        const chosen = (answers[q.id] != null) ? answers[q.id] : null;
        const ok = (chosen === q.answerIndex);
        if(ok) correct++;
        perQuestion.push({ id:q.id, chosenIndex:chosen, correctIndex:q.answerIndex, ok });
      });

      const pct = Math.round((correct/subset.length)*100);
      const elapsedSec = Math.max(1, Math.floor((Date.now()-startedAt)/1000));

      mod.attempts += 1;
      mod.totalTimeSec += elapsedSec;
      mod.lastAttemptAt = nowIso();
      mod.history.push({ at: mod.lastAttemptAt, seed, autoSubmit:auto, scorePct:pct, correct, total:subset.length, elapsedSec, perQuestion });

      if(mod.bestScorePct == null || pct > mod.bestScorePct) mod.bestScorePct = pct;
      if(pct >= masteryPct) mod.completed = true;

      saveState(state);

      const qEls = Array.from(mount.querySelectorAll('.question')).slice(1);
      subset.forEach((q, idx)=>{
        const chosen = (answers[q.id] != null) ? answers[q.id] : null;
        const ok = (chosen === q.answerIndex);

        const wrap = qEls[idx].querySelector('.explainWrap');
        const cls = ok ? 'good' : 'bad';
        const chosenLabel = chosen==null ? 'No answer' : `${String.fromCharCode(65+chosen)}. ${q.choices[chosen]}`;
        const correctLabel = `${String.fromCharCode(65+q.answerIndex)}. ${q.choices[q.answerIndex]}`;

        let why = '';
        if(ok){
          why = escapeHtml(q.explainCorrect || 'Correct (add explanation).');
        }else{
          const map = q.explainIncorrect || {};
          why = escapeHtml(map[String(chosen)] || 'Incorrect (add explanation).');
        }

        wrap.innerHTML = `
          <div class="explain ${cls}">
            <div><b>Your answer:</b> ${escapeHtml(chosenLabel)}</div>
            <div><b>Correct answer:</b> ${escapeHtml(correctLabel)}</div>
            <div class="hr"></div>
            <div><b>Why:</b> ${why}</div>
          </div>
        `;
      });

      resultEl.innerHTML = `
        <div class="question">
          <div style="display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap">
            <div>
              <div><b>Result:</b> ${pct}% (${correct}/${subset.length})</div>
              <div class="meta">Time: ${fmtTime(elapsedSec)} ${auto ? '(auto-submitted)' : ''}</div>
              <div class="meta">Mastery threshold: ${masteryPct}% | Status: ${mod.completed ? '<b>DONE</b>' : '<b>NOT DONE</b>'}</div>
            </div>
            <div class="actions">
              <a class="btn" href="index.html">Back to Wall</a>
              <a class="btn primary" href="final.html">Final</a>
            </div>
          </div>
        </div>
      `;

      const submitBtn = document.getElementById('submitBtn');
      if(submitBtn) submitBtn.disabled = true;
    }

    document.getElementById('submitBtn').addEventListener('click', ()=> submit(false));
  }

  function renderFinal({mountId}){
    const state = loadState();
    const totals = computeTotals(state);
    const mount = document.getElementById(mountId);

    const allDone = APP.modules.every(m => state.modules[m]?.completed);

    if(!allDone){
      mount.innerHTML = `
        <div class="question" id="finalMount">
          <div><b>Final Review is locked.</b></div>
          <div class="meta">Complete all modules (meet mastery threshold) to unlock.</div>
          <div class="hr"></div>
          <a class="btn" href="index.html">Back to Wall</a>
        </div>
      `;
      return;
    }

    const completionRate = Math.round((totals.completed/APP.modules.length)*100);
    const summary = `
      <div class="kpis" id="finalMount">
        <div class="kpi"><div class="label">Completion</div><div class="value">${totals.completed}/${APP.modules.length} (${completionRate}%)</div></div>
        <div class="kpi"><div class="label">Attempts</div><div class="value">${totals.attempts}</div></div>
        <div class="kpi"><div class="label">Avg best</div><div class="value">${totals.avgBest}%</div></div>
        <div class="kpi"><div class="label">Time-on-task</div><div class="value">${fmtTime(totals.time)}</div></div>
      </div>
    `;

    const sections = APP.modules.map(m=>{
      const mod = state.modules[m];
      const rows = (mod.history||[]).map(a=>`
        <div class="choice">
          <div style="flex:1">
            <div><b>${a.scorePct}%</b> | ${a.correct}/${a.total} | ${fmtTime(a.elapsedSec)} | <span class="badge">seed ${a.seed}</span></div>
            <div class="meta">${a.at}${a.autoSubmit ? ' (auto)' : ''}</div>
          </div>
        </div>
      `).join('');

      return `
        <div class="question">
          <div style="display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap;align-items:center">
            <div><b>Module ${m}</b> — Best: ${mod.bestScorePct ?? 0}% | Attempts: ${mod.attempts ?? 0}</div>
            <span class="pill good">DONE</span>
          </div>
          <div class="hr"></div>
          ${rows || '<div class="meta">No attempts recorded.</div>'}
        </div>
      `;
    }).join('');

    mount.innerHTML = `
      ${summary}
      <div class="hr"></div>
      <h2>Attempt history</h2>
      ${sections}
    `;
  }

  function exportAll(){ downloadJson('8G103G-progress-export.json', loadState()); }
  function exportModule(moduleId){
    const s = loadState();
    downloadJson(`8G103G-module-${moduleId}-export.json`, { course:APP.course, moduleId, module:s.modules[moduleId] || null });
  }
  function exportFinal(){ downloadJson('8G103G-final-export.json', loadState()); }

  async function importAll(jsonText){
    const obj = JSON.parse(jsonText);
    if(!obj || typeof obj !== 'object') throw new Error('Invalid JSON');
    if(!obj.modules) obj.modules = {};
    localStorage.setItem(APP.storeKey, JSON.stringify(obj));
  }

  function enableDeterrents(opts){
    const options = Object.assign({
      watermarkText: '8G103G',
      fullscreenOptional: true,
      blurOnFocusLoss: true
    }, opts || {});

    window.addEventListener('contextmenu', (e)=> e.preventDefault());

    window.addEventListener('keydown', (e)=>{
      const k = (e.key || '').toLowerCase();
      const ctrl = e.ctrlKey || e.metaKey;
      if(ctrl && (k==='c' || k==='x' || k==='a' || k==='s' || k==='p')) { e.preventDefault(); }
      if((e.ctrlKey && e.shiftKey && (k==='i' || k==='j' || k==='c')) || k==='f12') { e.preventDefault(); }
    });

    if(options.blurOnFocusLoss){
      window.addEventListener('blur', ()=> document.body.classList.add('blurAll'));
      window.addEventListener('focus', ()=> document.body.classList.remove('blurAll'));
      document.addEventListener('visibilitychange', ()=>{
        if(document.hidden) document.body.classList.add('blurAll');
        else document.body.classList.remove('blurAll');
      });
    }

    const wm = document.createElement('div');
    wm.className = 'watermark';
    wm.textContent = options.watermarkText + '\n' + new Date().toLocaleString();
    document.body.appendChild(wm);
  }

  function requestFullscreen(){
    const el = document.documentElement;
    if(el.requestFullscreen) el.requestFullscreen().catch(()=>{});
  }

  global.CourseApp = {
    APP,
    renderWall,
    renderModule,
    renderFinal,
    exportAll,
    exportModule,
    exportFinal,
    importAll,
    resetAll,
    resetModule,
    enableDeterrents,
    requestFullscreen
  };

})(window);
"@

# --- Verify pools exist ---
$missing = @()
1..10 | ForEach-Object {
  $m = $_.ToString("00")
  $p = ".\docs\assets\data\module-$m-pool.json"
  if (!(Test-Path $p)) { $missing += $p }
}

if ($missing.Count -gt 0) {
  Write-Host "Missing pool files detected (copy pools into docs/assets/data/ as module-XX-pool.json):" -ForegroundColor Yellow
  $missing | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
} else {
  Write-Host "Pool files detected for modules 01–10." -ForegroundColor Green
}

Write-Host ""
Write-Host "Files written. Next steps:" -ForegroundColor Green
Write-Host "  git add -A" -ForegroundColor Cyan
Write-Host "  git commit -m `"Upgrade /docs to self-paced Quiz Wall course`"" -ForegroundColor Cyan
Write-Host "  git push" -ForegroundColor Cyan
