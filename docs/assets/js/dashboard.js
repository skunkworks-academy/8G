'use strict';

(function () {
  // Requires core.js to be loaded first (APP, loadProgress, computeTotals, fmtTime, downloadJson, resetProgress)
  const progress = loadProgress();
  const totals = computeTotals(progress);

  const el = {
    modules: document.getElementById('modules'),
    kpiAttempts: document.getElementById('kpiAttempts'),
    kpiAvgBest: document.getElementById('kpiAvgBest'),
    kpiCompleted: document.getElementById('kpiCompleted'),
    kpiTime: document.getElementById('kpiTime'),
    btnExport: document.getElementById('btnExport'),
    btnImport: document.getElementById('btnImport'),
    fileImport: document.getElementById('fileImport'),
    btnReset: document.getElementById('btnReset'),
    btnReview: document.getElementById('btnReview'),
    impact: document.getElementById('impact')
  };

  // --- Defensive checks (fail loudly but clearly) ---
  const requiredIds = [
    'modules', 'kpiAttempts', 'kpiAvgBest', 'kpiCompleted', 'kpiTime',
    'btnExport', 'btnImport', 'fileImport', 'btnReset', 'btnReview', 'impact'
  ];
  const missing = requiredIds.filter(id => !document.getElementById(id));
  if (missing.length) {
    console.error('[8G103] Missing required DOM elements:', missing);
  }

  // --- Render KPI snapshot ---
  if (el.kpiAttempts) el.kpiAttempts.textContent = String(totals.attempts);
  if (el.kpiAvgBest) el.kpiAvgBest.textContent = `${totals.avgBest}%`;
  if (el.kpiCompleted) el.kpiCompleted.textContent = `${totals.completed} / ${APP.modules.length}`;
  if (el.kpiTime) el.kpiTime.textContent = fmtTime(totals.totalTimeSec);

  function moduleStatusPill(m) {
    const mod = progress.modules[m];
    if (!mod || (mod.attempts || 0) === 0) return `<span class="pill">Not started</span>`;
    if (mod.completed) return `<span class="pill good">Completed</span>`;
    return `<span class="pill warn">In progress</span>`;
  }

  function moduleMeta(m) {
    const mod = progress.modules[m];
    if (!mod || (mod.attempts || 0) === 0) return `No attempts yet`;
    const best = mod.bestScorePct ?? 0;
    const attempts = mod.attempts ?? 0;
    const time = fmtTime(mod.totalTimeSec || 0);
    const last = mod.lastAttemptAt ? new Date(mod.lastAttemptAt).toLocaleString() : null;
    return `Attempts: ${attempts} • Best: ${best}% • Time: ${time}${last ? ` • Last: ${last}` : ''}`;
  }

  function renderModules() {
    if (!el.modules) return;
    el.modules.innerHTML = '';

    APP.modules.forEach(m => {
      const div = document.createElement('div');
      div.className = 'module';
      div.innerHTML = `
        <div class="left">
          <div class="title">Module ${m}</div>
          <div class="meta">${moduleMeta(m)}</div>
        </div>
        <div class="row">
          ${moduleStatusPill(m)}
          <a class="btn primary" href="quiz.html?m=${m}" aria-label="Start or continue Module ${m} quiz">Start / Continue</a>
        </div>
      `;
      el.modules.appendChild(div);
    });
  }

  function computeImpact() {
    if (!el.impact) return;

    // Learning impact indicators (client-side / privacy-friendly):
    // 1) Completion rate
    // 2) Average improvement (best - first attempt) per module
    // 3) Time-on-task
    // 4) Item difficulty: percent correct per question across attempts (min exposures)
    const completionRate = Math.round((totals.completed / APP.modules.length) * 100);

    let improvementSum = 0;
    let improvementCount = 0;

    // Aggregate question stats across modules
    const itemAgg = {}; // qid -> {seen, correct}

    APP.modules.forEach(m => {
      const mod = progress.modules[m];
      if (!mod || !Array.isArray(mod.history) || mod.history.length === 0) return;

      const first = mod.history[0]?.scorePct;
      const best = (mod.bestScorePct ?? first);
      if (typeof first === 'number' && typeof best === 'number') {
        improvementSum += Math.max(0, best - first);
        improvementCount++;
      }

      const stats = mod.itemStats || {};
      Object.keys(stats).forEach(qid => {
        if (!itemAgg[qid]) itemAgg[qid] = { seen: 0, correct: 0 };
        itemAgg[qid].seen += (stats[qid].seen || 0);
        itemAgg[qid].correct += (stats[qid].correct || 0);
      });
    });

    const avgImprovement = improvementCount ? Math.round(improvementSum / improvementCount) : 0;

    // Identify hardest questions: lowest % correct, require at least N exposures
    const MIN_SEEN = 2;
    const hardest = Object.entries(itemAgg)
      .map(([qid, v]) => {
        const pct = v.seen ? Math.round((v.correct / v.seen) * 100) : 0;
        return { qid, pct, seen: v.seen };
      })
      .filter(x => x.seen >= MIN_SEEN)
      .sort((a, b) => a.pct - b.pct)
      .slice(0, 8);

    const hardList = hardest.length
      ? `<ul>
          ${hardest.map(x => `
            <li>
              <span class="badge">${x.pct}%</span>
              <span style="font-family:var(--mono)">${escapeHtml(x.qid)}</span>
              <span class="small">(seen ${x.seen})</span>
            </li>
          `).join('')}
        </ul>`
      : `<div class="small">Not enough attempts yet to compute item difficulty (need at least ${MIN_SEEN} exposures per question).</div>`;

    el.impact.innerHTML = `
      <div class="row">
        <div class="kpi">
          <div class="label">Completion rate</div>
          <div class="value">${completionRate}%</div>
        </div>
        <div class="kpi">
          <div class="label">Avg improvement (best − first)</div>
          <div class="value">${avgImprovement}%</div>
        </div>
        <div class="kpi">
          <div class="label">Time-on-task</div>
          <div class="value">${fmtTime(totals.totalTimeSec)}</div>
        </div>
      </div>
      <div class="hr"></div>
      <div><b>Hardest questions (item difficulty)</b></div>
      ${hardList}
      <div class="hr"></div>
      <div class="small">
        Metrics are stored locally in your browser. Use <b>Export progress</b> to capture evidence or ingest into a reporting pipeline.
      </div>
    `;
  }

  function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, m => ({
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;'
    }[m]));
  }

  // --- Buttons wiring ---
  if (el.btnExport) {
    el.btnExport.addEventListener('click', () => {
      const p = loadProgress();
      downloadJson('8G103-progress-export.json', p);
    });
  }

  if (el.btnImport && el.fileImport) {
    el.btnImport.addEventListener('click', () => el.fileImport.click());

    el.fileImport.addEventListener('change', async (e) => {
      const f = e.target.files && e.target.files[0];
      if (!f) return;

      try {
        const txt = await f.text();
        const obj = JSON.parse(txt);

        if (!obj || typeof obj !== 'object') throw new Error('Invalid JSON structure');
        if (!obj.modules) obj.modules = {};

        // Basic guardrails for wrong-course imports
        if (obj.course && obj.course !== APP.course) {
          const ok = confirm(`This export appears to be for "${obj.course}". Import anyway?`);
          if (!ok) return;
        }

        localStorage.setItem(APP.storeKey, JSON.stringify(obj));
        location.reload();
      } catch (err) {
        alert('Import failed: ' + err.message);
      } finally {
        // allow importing the same file again
        el.fileImport.value = '';
      }
    });
  }

  if (el.btnReset) {
    el.btnReset.addEventListener('click', () => {
      const ok = confirm('Reset ALL local progress for 8G103 on this browser?');
      if (!ok) return;
      resetProgress();
      location.reload();
    });
  }

  if (el.btnReview) {
    el.btnReview.addEventListener('click', () => {
      location.href = 'review.html';
    });
  }

  // --- Initial render ---
  renderModules();
  computeImpact();
})();
