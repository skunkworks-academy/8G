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
    return m>0 ? ${m}m s : ${s}s;
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
    if(!mod || (mod.attempts||0)===0) return <span class="pill">NOT DONE</span>;
    if(mod.completed) return <span class="pill good">DONE</span>;
    return <span class="pill warn">IN PROGRESS</span>;
  }

  function renderWall({mountId, kpiId}){
    const state = loadState();
    const totals = computeTotals(state);

    const kpiEl = document.getElementById(kpiId);
    if(kpiEl){
      const rate = Math.round((totals.completed/APP.modules.length)*100);
      kpiEl.innerHTML = 
        <div class="kpi"><div class="label">Modules completed</div><div class="value">/ (%)</div></div>
        <div class="kpi"><div class="label">Attempts</div><div class="value"></div></div>
        <div class="kpi"><div class="label">Average best</div><div class="value">%</div></div>
        <div class="kpi"><div class="label">Time-on-task</div><div class="value"></div></div>
      ;
    }

    const wall = document.getElementById(mountId);
    wall.innerHTML = '';

    APP.modules.forEach(m=>{
      const mod = state.modules[m];
      const best = mod?.bestScorePct ?? 0;
      const at = mod?.attempts ?? 0;
      const meta = (at===0) ? 'No attempts yet' : Attempts:  | Best: % | Time: ;

      const tile = document.createElement('div');
      tile.className = 'tile';
      tile.innerHTML = 
        <div class="left">
          <div class="title">Module 10</div>
          <div class="meta"></div>
        </div>
        <div class="actions">
          
          <a class="btn primary" href="module10.html">Open quiz</a>
        </div>
      ;
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
    if(titleEl) titleEl.textContent = pool.title || Module  Quiz;

    const metaEl = document.getElementById(metaId);
    if(metaEl){
      metaEl.innerHTML = 
        Pool: <b></b> | Attempt limit: <b></b> | Mastery: <b>%</b> |
        Questions per attempt: <b></b> | Time limit: <b> min</b>
      ;
    }

    const kpiEl = document.getElementById(kpiId);
    if(kpiEl){
      const status = mod.completed ? 'DONE' : (mod.attempts>0 ? 'IN PROGRESS' : 'NOT DONE');
      kpiEl.innerHTML = 
        <div class="kpi"><div class="label">Status</div><div class="value"></div></div>
        <div class="kpi"><div class="label">Attempts used</div><div class="value">/</div></div>
        <div class="kpi"><div class="label">Best score</div><div class="value">%</div></div>
        <div class="kpi"><div class="label">Time-on-task</div><div class="value"></div></div>
      ;
    }

    const mount = document.getElementById(mountId);
    mount.innerHTML = '';

    if(mod.attempts >= attemptLimit && !mod.completed){
      mount.innerHTML = 
        <div class="question">
          <div><b>Attempt limit reached for this browser.</b></div>
          <div class="meta">You cannot submit a new attempt here. Reset module (if allowed) or use instructor process.</div>
          <div class="hr"></div>
          <a class="btn" href="index.html">Back to Wall</a>
        </div>
      ;
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
    header.innerHTML = 
      <div style="display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap;align-items:center">
        <div>
          <div><b>Attempt seed:</b> <span style="font-family:var(--mono)"></span></div>
          <div class="meta">Answer all questions then submit.</div>
        </div>
        <div>
          <span class="timer" id="timer"></span>
          <button class="btn good" id="submitBtn">Submit</button>
        </div>
      </div>
    ;
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
      qEl.innerHTML = 
        <div style="display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap">
          <div><b>. </b></div>
          <span class="pill">ID: </span>
        </div>
        <div class="meta">Tags: </div>
        <div class="hr"></div>
        <div class="choices"></div>
        <div class="explainWrap"></div>
      ;
      const choices = qEl.querySelector('.choices');

      q.choices.forEach((c, i)=>{
        const row = document.createElement('label');
        row.className = 'choice';
        row.innerHTML = 
          <input type="radio" name="" value="31">
          <div><b>.</b> </div>
        ;
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
        const chosenLabel = chosen==null ? 'No answer' : ${String.fromCharCode(65+chosen)}. ;
        const correctLabel = ${String.fromCharCode(65+q.answerIndex)}. ;

        let why = '';
        if(ok){
          why = escapeHtml(q.explainCorrect || 'Correct (add explanation).');
        }else{
          const map = q.explainIncorrect || {};
          why = escapeHtml(map[String(chosen)] || 'Incorrect (add explanation).');
        }

        wrap.innerHTML = 
          <div class="explain ">
            <div><b>Your answer:</b> </div>
            <div><b>Correct answer:</b> </div>
            <div class="hr"></div>
            <div><b>Why:</b> </div>
          </div>
        ;
      });

      resultEl.innerHTML = 
        <div class="question">
          <div style="display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap">
            <div>
              <div><b>Result:</b> % (/)</div>
              <div class="meta">Time:  </div>
              <div class="meta">Mastery threshold: % | Status: </div>
            </div>
            <div class="actions">
              <a class="btn" href="index.html">Back to Wall</a>
              <a class="btn primary" href="final.html">Final</a>
            </div>
          </div>
        </div>
      ;

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
      mount.innerHTML = 
        <div class="question" id="finalMount">
          <div><b>Final Review is locked.</b></div>
          <div class="meta">Complete all modules (meet mastery threshold) to unlock.</div>
          <div class="hr"></div>
          <a class="btn" href="index.html">Back to Wall</a>
        </div>
      ;
      return;
    }

    const completionRate = Math.round((totals.completed/APP.modules.length)*100);
    const summary = 
      <div class="kpis" id="finalMount">
        <div class="kpi"><div class="label">Completion</div><div class="value">/ (%)</div></div>
        <div class="kpi"><div class="label">Attempts</div><div class="value"></div></div>
        <div class="kpi"><div class="label">Avg best</div><div class="value">%</div></div>
        <div class="kpi"><div class="label">Time-on-task</div><div class="value"></div></div>
      </div>
    ;

    const sections = APP.modules.map(m=>{
      const mod = state.modules[m];
      const rows = (mod.history||[]).map(a=>
        <div class="choice">
          <div style="flex:1">
            <div><b>%</b> | / |  | <span class="badge">seed </span></div>
            <div class="meta"></div>
          </div>
        </div>
      ).join('');

      return 
        <div class="question">
          <div style="display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap;align-items:center">
            <div><b>Module 10</b> — Best: % | Attempts: </div>
            <span class="pill good">DONE</span>
          </div>
          <div class="hr"></div>
          
        </div>
      ;
    }).join('');

    mount.innerHTML = 
      
      <div class="hr"></div>
      <h2>Attempt history</h2>
      
    ;
  }

  function exportAll(){ downloadJson('8G103G-progress-export.json', loadState()); }
  function exportModule(moduleId){
    const s = loadState();
    downloadJson(8G103G-module--export.json, { course:APP.course, moduleId, module:s.modules[moduleId] || null });
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
