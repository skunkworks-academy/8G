# ============================================
# BUILD HOLISTIC COURSE CONTENT
# Expands /docs into a rich interactive course
# For 8G103G Quiz Wall + Lesson Pages
# ============================================

$ErrorActionPreference = "Stop"

function Ensure-Dir($dir) {
  if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
}

function Write-File($path, $content) {
  Ensure-Dir (Split-Path $path -Parent)
  Set-Content -Path $path -Value $content -Encoding UTF8
}

# ---------- Directories ----------
Ensure-Dir ".\docs\content"
Ensure-Dir ".\docs\content\modules"
Ensure-Dir ".\docs\content\shared"

# ---------- Shared UI Components (lesson header/footer) ----------
$sharedHeader = @"
<div class='lesson-header'>
  <h1 id='lessonTitle'>__TITLE__</h1>
  <p class='lesson-sub'>__SUBTITLE__</p>
  <hr>
</div>
"@

$sharedFooter = @"
<hr>
<div class='lesson-nav'>
  <a class='btn primary' href='../index.html'>Back to Quiz Wall</a>
  <a class='btn' href='syllabus.html'>Syllabus</a>
  <a class='btn' href='glossary.html'>Glossary</a>
  <a class='btn good' href='../final.html'>Final Review</a>
</div>
"@

# ---------- JS for Interactivity (polls, reveal blocks) ----------
Write-File ".\docs\content\shared\interactive.js" @"
window.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.poll button').forEach(btn => {
    btn.addEventListener('click', () => {
      const parent = btn.closest('.poll');
      parent.querySelectorAll('button').forEach(b => b.disabled = true);
      parent.querySelector('.poll-result').classList.remove('hidden');
    });
  });
  document.querySelectorAll('.toggle-answer').forEach(el => {
    el.addEventListener('click', () => {
      const target = document.getElementById(el.dataset.target);
      if (target) target.classList.toggle('hidden');
    });
  });
});
"@

# ---------- CSS Enhancements ----------
Write-File ".\docs\assets/css/lessons.css" @"
.lesson-header { text-align:center; margin-bottom:12px }
.lesson-sub { color: var(--muted) }
.reveal { margin:12px 0; padding:10px; border:1px solid var(--border); border-radius:10px; background:rgba(255,255,255,.03) }
.poll button { margin:4px; cursor:pointer; }
.poll-result.hidden { display:none; }
.tooltip {
  position:relative;
  border-bottom:1px dotted var(--muted);
  cursor:help;
}
.tooltip .tooltiptext {
  visibility:hidden;
  background-color:var(--muted);
  color:var(--bg);
  text-align:center;
  border-radius:6px;
  padding:6px;
  position:absolute;
  z-index:20;
  bottom:125%;
  left:50%;
  transform:translateX(-50%);
}
.tooltip:hover .tooltiptext { visibility:visible; }
"@

# ---------- Generate Syllabus Rich Page ----------
Write-File ".\docs\content\syllabus.html" @"
<!doctype html>
<html lang='en'>
<head>
  <meta charset='utf-8'>
  <meta name='viewport' content='width=device-width,initial-scale=1'>
  <title>8G103G — Syllabus</title>
  <link rel='stylesheet' href='../assets/styles.css'>
  <link rel='stylesheet' href='../assets/css/lessons.css'>
</head>
<body>
  $sharedHeader.Replace('__TITLE__','Course Syllabus').Replace('__SUBTITLE__','Guardium Protection Fundamentals Overview')

  <main class='wrap'>
    <p>Welcome! This syllabus outlines the modules, learning goals, and interactive checkpoints.</p>

    <ul>
      1..10 | ForEach-Object { "<li><a href='modules/module$($_.ToString('00')).html'>Module $($_.ToString('00')) Lesson</a></li>" }
    </ul>

    <div class='reveal'>
      <h3>How to use this site</h3>
      <p>Learn the material first, complete the polls and examples, then take the associated quiz from the Quiz Wall.</p>
    </div>
  </main>

  $sharedFooter
</body>
</html>
"@

# ---------- Glossary Rich Page ----------
Write-File ".\docs\content\glossary.html" @"
<!doctype html>
<html lang='en'>
<head>
  <meta charset='utf-8'>
  <meta name='viewport' content='width=device-width,initial-scale=1'>
  <title>8G103G — Glossary</title>
  <link rel='stylesheet' href='../assets/styles.css'>
  <link rel='stylesheet' href='../assets/css/lessons.css'>
</head>
<body>
  $sharedHeader.Replace('__TITLE__','Glossary').Replace('__SUBTITLE__','Key Terms & Definitions')

  <main class='wrap'>
    <p>Hover over terms to see definitions.</p>
    <ul>
      <li><span class='tooltip'>Guardium<span class='tooltiptext'>IBM Guardium data security platform</span></span></li>
      <li><span class='tooltip'>Policy<span class='tooltiptext'>Set of rules to monitor/alert database activity</span></span></li>
      <li><span class='tooltip'>S-TAP<span class='tooltiptext'>Software Tap for traffic inspection</span></span></li>
    </ul>
  </main>

  $sharedFooter

  <script src='shared/interactive.js'></script>
</body>
</html>
"@

# ---------- References Page ----------
Write-File ".\docs\content\references.html" @"
<!doctype html>
<html lang='en'>
<head>
  <meta charset='utf-8'>
  <meta name='viewport' content='width=device-width,initial-scale=1'>
  <title>8G103G — References</title>
  <link rel='stylesheet' href='../assets/styles.css'>
  <link rel='stylesheet' href='../assets/css/lessons.css'>
</head>
<body>
  $sharedHeader.Replace('__TITLE__','References & Resources').Replace('__SUBTITLE__','Curated Knowledge Resources')

  <main class='wrap'>
    <ul>
      <li><a href='https://www.ibm.com/docs/guardium'>IBM Guardium Documentation</a></li>
      <li><a href='https://www.ibm.com/security/data-security/guardium'>IBM Security Guardium Overview</a></li>
      <li><a href='https://www.ibm.com/security'>IBM Security Portal</a></li>
    </ul>
  </main>

  $sharedFooter
</body>
</html>
"@

# ---------- Module Lesson Pages (Interactive) ----------
For ($i = 1; $i -le 10; $i++) {
  $m = $i.ToString("00")
  Write-File ".\docs\content\modules\module$m.html" @"
<!doctype html>
<html lang='en'>
<head>
  <meta charset='utf-8'>
  <meta name='viewport' content='width=device-width,initial-scale=1'>
  <title>8G103G — Module $m Lesson</title>
  <link rel='stylesheet' href='../../assets/styles.css'>
  <link rel='stylesheet' href='../../assets/css/lessons.css'>
</head>
<body>
  $sharedHeader.Replace('__TITLE__','Module $m Lesson').Replace('__SUBTITLE__','Concepts & Guided Examples')

  <main class='wrap'>
    <h2>Module $m — Core Concepts</h2>
    <p>Instructional narrative goes here. Add diagrams, explanations, examples.</p>

    <div class='reveal'>
      <h3>Example Scenario</h3>
      <p>Description of a scenario relevant to module $m.</p>
    </div>

    <div class='poll'>
      <p><b>Interactive Checkpoint:</b> What is the primary purpose of the concept discussed above?</p>
      <button>Option A</button><button>Option B</button><button>Option C</button><button>Option D</button>
      <div class='poll-result hidden'>
        <p>Good try! Ensure you revisit the key concepts in this module.</p>
      </div>
    </div>

    <hr>
    <p>When you feel confident, proceed to the <a href='../module$m.html' class='btn primary'>Module $m Quiz</a>.</p>
  </main>

  $sharedFooter

  <script src='../shared/interactive.js'></script>
</body>
</html>
"@
}

Write-Host "Holistic interactive content pages generated:"
Write-Host "  docs/content/syllabus.html"
Write-Host "  docs/content/glossary.html"
Write-Host "  docs/content/references.html"
Write-Host "  docs/content/modules/module01..module10.html"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  git add -A"
Write-Host "  git commit -m 'Add holistic lesson content with interactivity'"
Write-Host "  git push"
