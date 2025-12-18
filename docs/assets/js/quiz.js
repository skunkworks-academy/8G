'use strict';

(function(){
  const qs = new URLSearchParams(location.search);
  const moduleId = qs.get('m') || '01';

  const progress = loadProgress();
  const state = {
    moduleId,
    pool: null,
    startedAt: null,
    seed: deriveSeed(),
    questions: [],
    answers: {},   // id -> selected index
    evaluated: false
  };

  const el = {
    title: document.getElementById('title'),
    meta: document.getElementById('meta'),
    qWrap: document.getElementById('questions'),
    btnSubmit: document.getElementById('btnSubmit'),
    btnReset: document.getElementById('btnReset'),
    btnBack: document.getElementById('btnBack'),
    result: document.getElementById('result'),
  };

  function ensureModuleRecord(){
    if(!progress.modules[state.moduleId]){
      progress.modules[state.moduleId] = {
        attempts: 0,
        bestScorePct: null,
        completed: false,
        totalTimeSec: 0,
        lastAttemptAt: null,
        history: [],
        itemStats: {} // questionId -> {seen, correct}
      };
    }
    return progress.modules[state.moduleId];
  }

  function render(){
    el.title.textContent = Module  Quiz;
    el.meta.textContent = Seed:  • Your progress is stored locally in this browser;

    el.qWrap.innerHTML = '';
    state.questions.forEach((q, idx)=>{
      const qEl = document.createElement('div');
      qEl.className = 'question';
      qEl.innerHTML = 
        <div class="qhead">
          <div class="qprompt">. </div>
          <span class="pill">ID: </span>
        </div>
        <div class="small">Tags: </div>
        <div class="hr"></div>
        <div class="choices"></div>
        <div class="explainWrap"></div>
      ;

      const choices = qEl.querySelector('.choices');
      q.choices.forEach((c, i)=>{
        const row = document.createElement('label');
        row.className = 'choice';
        row.innerHTML = 
          <input type="radio" name="" value="">
          <div><div><b>.</b> </div></div>
        ;
        row.addEventListener('click', ()=>{
          if(state.evaluated) return;
          state.answers[q.id] = i;
        });
        choices.appendChild(row);
      });

      el.qWrap.appendChild(qEl);
    });
  }

  function escapeHtml(s){
    return String(s).replace(/[&<>"']/g, m => ({
      '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'
    }[m]));
  }

  function evaluate(){
    const mod = ensureModuleRecord();
    const total = state.questions.length;
    let correct = 0;

    const perQuestion = [];

    state.questions.forEach((q)=>{
      const chosen = state.answers[q.id];
      const isCorrect = (chosen === q.answerIndex);
      if(isCorrect) correct++;

      // item analysis tracking
      if(!mod.itemStats[q.id]) mod.itemStats[q.id] = { seen: 0, correct: 0 };
      mod.itemStats[q.id].seen += 1;
      if(isCorrect) mod.itemStats[q.id].correct += 1;

      perQuestion.push({
        id: q.id,
        chosenIndex: chosen ?? null,
        correctIndex: q.answerIndex,
        isCorrect
      });
    });

    const pct = Math.round((correct/total)*100);
    const elapsedSec = Math.max(1, Math.floor((Date.now() - state.startedAt)/1000));

    mod.attempts += 1;
    mod.totalTimeSec += elapsedSec;
    mod.lastAttemptAt = new Date().toISOString();
    mod.history.push({
      at: mod.lastAttemptAt,
      seed: state.seed,
      scorePct: pct,
      correct,
      total,
      elapsedSec,
      perQuestion
    });

    if(mod.bestScorePct == null || pct > mod.bestScorePct) mod.bestScorePct = pct;
    mod.completed = pct >= 70; // default threshold; adjust as needed

    saveProgress(progress);

    state.evaluated = true;
    showFeedback(pct, correct, total, elapsedSec);
  }

  function showFeedback(pct, correct, total, elapsedSec){
    el.result.innerHTML = 
      <div class="row">
        <div class="kpi">
          <div class="label">Score</div>
          <div class="value">%</div>
        </div>
        <div class="kpi">
          <div class="label">Correct</div>
          <div class="value"> / </div>
        </div>
        <div class="kpi">
          <div class="label">Time</div>
          <div class="value"></div>
        </div>
      </div>
      <div class="hr"></div>
      <div class="small">Review each question below: what you chose, what was correct, and why.</div>
    ;

    // decorate questions with explanations
    const qEls = Array.from(document.querySelectorAll('.question'));
    state.questions.forEach((q, idx)=>{
      const qEl = qEls[idx];
      const chosen = state.answers[q.id];
      const wrap = qEl.querySelector('.explainWrap');

      const isCorrect = chosen === q.answerIndex;
      const cls = isCorrect ? 'good' : 'bad';
      const chosenLabel = chosen == null ? 'No answer' : ${String.fromCharCode(65+chosen)}. ;
      const correctLabel = ${String.fromCharCode(65+q.answerIndex)}. ;

      let why = '';
      if(isCorrect){
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

    el.btnSubmit.disabled = true;
  }

  function resetAttempt(){
    // resets only the current attempt UI (not stored progress)
    state.answers = {};
    state.evaluated = false;
    state.startedAt = Date.now();
    el.result.innerHTML = '';
    el.btnSubmit.disabled = false;
    render();
  }

  async function init(){
    state.startedAt = Date.now();
    state.pool = await loadPool(state.moduleId);

    // choose question subset (use all for now; you can slice later)
    const questions = state.pool.questions || [];
    const shuffled = seededShuffle(questions, state.seed);
    state.questions = shuffled;

    render();

    el.btnSubmit.addEventListener('click', ()=>{
      if(state.evaluated) return;
      evaluate();
    });

    el.btnReset.addEventListener('click', resetAttempt);
    el.btnBack.addEventListener('click', ()=> location.href = 'index.html');
  }

  init().catch(err=>{
    document.body.innerHTML = <div class="container"><h1 class="h1">Quiz failed to load</h1><pre style="white-space:pre-wrap"></pre></div>;
  });

})();
