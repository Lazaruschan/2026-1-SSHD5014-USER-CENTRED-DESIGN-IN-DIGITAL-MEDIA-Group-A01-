/**
 * Client-side password gate for the SSHD5014 static site.
 * Not true security (password check runs in the browser) — use for casual course access only.
 *
 * Default password: 20265014
 * To change it, replace PASSWORD_HASH with:
 *   python3 -c "import hashlib; print(hashlib.sha256(b'YOUR_PASSWORD').hexdigest())"
 */
(function () {
  const PASSWORD_HASH =
    "fd973f0bfd31da02b1869e88235cf6e360404f2b9ab614581f6b3c2af9358c65";
  const STORAGE_KEY = "sshd5014_site_unlocked";
  const TITLE = "SSHD5014 User-centred Design in Digital Media";

  function inSlidesFolder() {
    return /\/slides(\/|$)/.test(location.pathname);
  }

  async function sha256Hex(text) {
    const data = new TextEncoder().encode(text);
    const digest = await crypto.subtle.digest("SHA-256", data);
    return Array.from(new Uint8Array(digest))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");
  }

  function isUnlocked() {
    try {
      return sessionStorage.getItem(STORAGE_KEY) === "1";
    } catch (_) {
      return false;
    }
  }

  function setUnlocked() {
    try {
      sessionStorage.setItem(STORAGE_KEY, "1");
    } catch (_) {
      /* private mode may block storage; unlock for this page only */
    }
  }

  function revealSite() {
    document.documentElement.classList.remove("site-locked");
    document.documentElement.classList.add("site-unlocked");
    const gate = document.getElementById("site-password-gate");
    if (gate) gate.remove();
  }

  function injectLockStyles() {
    if (document.getElementById("site-auth-styles")) return;
    const style = document.createElement("style");
    style.id = "site-auth-styles";
    style.textContent = `
      html.site-locked body > *:not(#site-password-gate) { visibility: hidden !important; }
      #site-password-gate {
        position: fixed; inset: 0; z-index: 2147483647;
        display: flex; align-items: center; justify-content: center;
        background: #0a0a0a; color: #e8e8e8;
        font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
        padding: 24px;
      }
      #site-password-gate .gate-card {
        width: 100%; max-width: 400px;
        border: 1px solid #333; background: #111;
        padding: 32px 28px;
      }
      #site-password-gate .gate-eyebrow {
        font-size: 12px; letter-spacing: 0.12em; text-transform: uppercase;
        color: #888; margin: 0 0 10px;
      }
      #site-password-gate h1 {
        font-family: "Times New Roman", Times, serif;
        font-weight: normal; font-size: 28px; margin: 0 0 8px; color: #fff;
        border-top: 1px solid #C5A059; padding-top: 14px;
      }
      #site-password-gate p { margin: 0 0 20px; color: #aaa; font-size: 14px; line-height: 1.5; }
      #site-password-gate label { display: block; font-size: 12px; color: #888; margin-bottom: 8px; }
      #site-password-gate input[type="password"] {
        width: 100%; box-sizing: border-box;
        background: #000; color: #fff; border: 1px solid #444;
        padding: 12px 14px; font-size: 16px; outline: none;
      }
      #site-password-gate input[type="password"]:focus { border-color: #C5A059; }
      #site-password-gate button {
        margin-top: 16px; width: 100%;
        background: #C5A059; color: #000; border: 0;
        padding: 12px 16px; font-size: 14px; font-weight: 600; cursor: pointer;
      }
      #site-password-gate button:hover { background: #d4b56e; }
      #site-password-gate .gate-error {
        min-height: 1.25em; margin-top: 12px; font-size: 13px; color: #e57373;
      }
    `;
    document.head.appendChild(style);
  }

  function showGate() {
    document.documentElement.classList.add("site-locked");
    injectLockStyles();

    const gate = document.createElement("div");
    gate.id = "site-password-gate";
    gate.setAttribute("role", "dialog");
    gate.setAttribute("aria-modal", "true");
    gate.setAttribute("aria-labelledby", "site-password-title");
    gate.innerHTML = `
      <div class="gate-card">
        <p class="gate-eyebrow">PolyU CPCE · Course site</p>
        <h1 id="site-password-title">${TITLE}</h1>
        <p>Enter the course password to continue.</p>
        <form id="site-password-form" autocomplete="current-password">
          <label for="site-password-input">Password</label>
          <input id="site-password-input" type="password" name="password" required autofocus />
          <button type="submit">Enter</button>
          <div class="gate-error" id="site-password-error" aria-live="polite"></div>
        </form>
      </div>
    `;
    document.body.appendChild(gate);

    const form = gate.querySelector("#site-password-form");
    const input = gate.querySelector("#site-password-input");
    const error = gate.querySelector("#site-password-error");

    form.addEventListener("submit", async (event) => {
      event.preventDefault();
      error.textContent = "";
      const value = input.value || "";
      try {
        const hash = await sha256Hex(value);
        if (hash === PASSWORD_HASH) {
          setUnlocked();
          revealSite();
          return;
        }
      } catch (_) {
        /* crypto.subtle needs secure context (https or localhost) */
        error.textContent = "Password check needs HTTPS or localhost.";
        return;
      }
      error.textContent = "Incorrect password. Try again.";
      input.select();
    });

    setTimeout(() => input.focus(), 0);
  }

  function boot() {
    if (isUnlocked()) {
      document.documentElement.classList.add("site-unlocked");
      return;
    }
    if (document.body) {
      showGate();
    } else {
      document.addEventListener("DOMContentLoaded", showGate, { once: true });
    }
  }

  // Mark slides path for debugging / future path-sensitive assets
  if (inSlidesFolder()) {
    document.documentElement.dataset.authScope = "slides";
  }

  boot();
})();
