(() => {
  const params = new URLSearchParams(window.location.search);
  const saved = localStorage.getItem("sv-lang");
  let lang = params.get("lang") || saved || "en";
  if (lang !== "hi" && lang !== "en") lang = "en";

  function setLang(next) {
    lang = next;
    localStorage.setItem("sv-lang", lang);
    document.documentElement.lang = lang === "hi" ? "hi" : "en";
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const value = el.getAttribute(`data-${lang}`);
      if (value != null) el.textContent = value;
    });
    document.querySelectorAll(".lang-toggle button").forEach((btn) => {
      btn.setAttribute("aria-pressed", btn.dataset.lang === lang ? "true" : "false");
    });
    const event = new CustomEvent("sv:lang", { detail: { lang } });
    window.dispatchEvent(event);
  }

  document.querySelectorAll(".lang-toggle button").forEach((btn) => {
    btn.addEventListener("click", () => setLang(btn.dataset.lang));
  });

  setLang(lang);

  window.SakshiPages = {
    get lang() {
      return lang;
    },
    setLang,
    async loadLegal({ en, hi, mount }) {
      const path = lang === "hi" ? hi : en;
      const root = document.querySelector(mount);
      if (!root) return;
      root.innerHTML = `<p class="loading">${lang === "hi" ? "लोड हो रहा है…" : "Loading…"}</p>`;
      try {
        const res = await fetch(path, { cache: "no-cache" });
        if (!res.ok) throw new Error(String(res.status));
        const md = await res.text();
        root.innerHTML = window.marked.parse(md);
      } catch (err) {
        root.innerHTML = `<p>Could not load document. <a href="${path}">Open source file</a>.</p>`;
      }
    },
  };
})();
