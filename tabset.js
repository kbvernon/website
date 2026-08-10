function activateTab(id, push) {
    const btn = document.querySelector(`.tabset .label[data-tab="${id}"]`);
    const panel = document.getElementById(id);
    if (!btn || !panel) return;
    document.querySelectorAll('.tabset .label').forEach(b => {
        b.classList.remove('active');
        b.setAttribute('aria-selected', 'false');
    });
    document.querySelectorAll('.tabset .panel').forEach(p => p.classList.remove('active'));
    btn.classList.add('active');
    btn.setAttribute('aria-selected', 'true');
    panel.classList.add('active');
    document.getElementById('tab-select').value = id;
    if (push) history.pushState(null, '', '#' + id);
}

document.querySelectorAll('.tabset .label').forEach(btn => {
    btn.addEventListener('click', () => activateTab(btn.dataset.tab, true));
});

document.getElementById('tab-select').addEventListener('change', function () {
    activateTab(this.value, true);
});

if (location.hash) activateTab(location.hash.slice(1), false);
window.addEventListener('popstate', () => {
    activateTab(location.hash.slice(1) || 'publications', false);
});
