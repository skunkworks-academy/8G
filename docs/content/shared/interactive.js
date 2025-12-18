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
