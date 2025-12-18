'use strict';

const APP = {
  version: '1.0.0',
  course: '8G103',
  modules: Array.from({length: 10}, (_,i)=> String(i+1).padStart(2,'0')),
  storeKey: '8G103_PROGRESS_V1',
};

function nowIso(){ return new Date().toISOString(); }

function loadProgress(){
  try{
    const raw = localStorage.getItem(APP.storeKey);
    if(!raw) return { version: APP.version, course: APP.course, createdAt: nowIso(), updatedAt: nowIso(), modules: {} };
    const obj = JSON.parse(raw);
    if(!obj.modules) obj.modules = {};
    return obj;
  }catch(e){
    return { version: APP.version, course: APP.course, createdAt: nowIso(), updatedAt: nowIso(), modules: {} };
  }
}

function saveProgress(p){
  p.updatedAt = nowIso();
  localStorage.setItem(APP.storeKey, JSON.stringify(p));
}

function resetProgress(){
  localStorage.removeItem(APP.storeKey);
}

function computeTotals(progress){
  let attempts=0, bestAvg=0, bestCount=0, completed=0, totalTimeSec=0;
  APP.modules.forEach(m=>{
    const mod = progress.modules[m];
    if(!mod) return;
    attempts += (mod.attempts||0);
    totalTimeSec += (mod.totalTimeSec||0);
    if(mod.bestScorePct != null){
      bestAvg += mod.bestScorePct;
      bestCount++;
    }
    if(mod.completed) completed++;
  });
  const avgBest = bestCount ? Math.round(bestAvg / bestCount) : 0;
  return { attempts, avgBest, completed, totalTimeSec };
}

function fmtTime(sec){
  sec = Math.max(0, Math.floor(sec||0));
  const h = Math.floor(sec/3600);
  const m = Math.floor((sec%3600)/60);
  const s = sec%60;
  if(h>0) return ${h}h 10m;
  if(m>0) return ${m}m s;
  return ${s}s;
}

function downloadJson(filename, dataObj){
  const blob = new Blob([JSON.stringify(dataObj, null, 2)], {type:'application/json'});
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

async function loadPool(moduleId){
  const res = await fetch(ssets/data/module--pool.json, {cache:'no-store'});
  if(!res.ok) throw new Error('Failed to load pool: '+moduleId);
  return await res.json();
}

function seededShuffle(arr, seed){
  let a = arr.slice();
  let s = seed >>> 0;
  function rnd(){
    s ^= s << 13; s ^= s >>> 17; s ^= s << 5;
    return (s >>> 0) / 4294967296;
  }
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
