function activateTab(id) {
    document.querySelectorAll('.tabset .label').forEach(b => {
        b.classList.remove('active');
        b.setAttribute('aria-selected', 'false');
    });
    document.querySelectorAll('.tabset .panel').forEach(p => p.classList.remove('active'));
    const btn = document.querySelector(`.tabset .label[data-tab="${id}"]`);
    const panel = document.getElementById(id);
    if (btn) { btn.classList.add('active'); btn.setAttribute('aria-selected', 'true'); }
    if (panel) panel.classList.add('active');
    const sel = document.getElementById('tab-select');
    if (sel) sel.value = id;
}

document.querySelectorAll('.tabset .label').forEach(btn => {
    btn.addEventListener('click', () => activateTab(btn.dataset.tab));
});

document.getElementById('tab-select').addEventListener('change', function () {
    activateTab(this.value);
});

if (location.hash) activateTab(location.hash.slice(1));
window.addEventListener('hashchange', () => activateTab(location.hash.slice(1)));
