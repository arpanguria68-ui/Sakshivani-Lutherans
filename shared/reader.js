/**
 * Accessible Reader & TTS Module
 * Shared across Sakshi Vani (Songs), Catechism, and Bible Reader.
 */

class AccessibleReader {
    constructor(contentSelector) {
        if (typeof contentSelector === 'string') {
            this.contentContainer = document.querySelector(contentSelector);
        } else if (contentSelector instanceof HTMLElement) {
            this.contentContainer = contentSelector;
        }

        if (!this.contentContainer) {
            console.error(`Reader: Container ${contentSelector} not found.`);
            return;
        }

        this.synth = window.speechSynthesis;
        this.utterance = null;
        this.isPlaying = false;
        this.chunks = []; // Array of { element, text }
        this.currentIndex = 0;
        this.settings = {
            fontSize: 'md',         // sm, md, lg, xl
            lineHeight: 'normal',   // tight, normal, loose
            theme: 'default',       // default, contrast-light, contrast-dark
            font: 'default',        // default, dyslexic
            rate: 1.0
        };

        this.init();
    }

    init() {
        this.injectToolbar();
        this.chunkContent();
        this.loadSettings();
        this.applySettings();
        this.setupKeyboardShortcuts();

        // Show toolbar
        setTimeout(() => document.querySelector('.reader-toolbar').classList.add('visible'), 500);
    }

    // --- UI INJECTION ---
    injectToolbar() {
        if (document.querySelector('.reader-toolbar')) return; // Avoid dupes

        const toolbar = document.createElement('div');
        toolbar.className = 'reader-toolbar';
        toolbar.innerHTML = `
            <div class="reader-status" id="reader-status">Ready to read</div>
            <div class="reader-controls">
                <button class="reader-btn" id="reader-prev" aria-label="Previous Sentence">
                    ⏮
                </button>
                <button class="reader-btn" id="reader-play" aria-label="Play Read Aloud" style="min-width: 100px; justify-content: center;">
                    ▶ Play
                </button>
                <button class="reader-btn" id="reader-next" aria-label="Next Sentence">
                    ⏭
                </button>
                <button class="reader-btn" id="reader-settings-toggle" aria-label="Text Settings">
                    Aa
                </button>
            </div>
            
            <div class="reader-settings-popover" id="reader-settings">
                <div class="reader-setting-group">
                    <label>Text Size</label>
                    <div class="reader-toggle-group">
                        <button class="reader-toggle-btn" data-setting="fontSize" data-val="sm">S</button>
                        <button class="reader-toggle-btn active" data-setting="fontSize" data-val="md">M</button>
                        <button class="reader-toggle-btn" data-setting="fontSize" data-val="lg">L</button>
                        <button class="reader-toggle-btn" data-setting="fontSize" data-val="xl">XL</button>
                    </div>
                </div>
                <div class="reader-setting-group">
                    <label>Spacing</label>
                    <div class="reader-toggle-group">
                        <button class="reader-toggle-btn" data-setting="lineHeight" data-val="tight">Tight</button>
                        <button class="reader-toggle-btn active" data-setting="lineHeight" data-val="normal">Normal</button>
                        <button class="reader-toggle-btn" data-setting="lineHeight" data-val="loose">Wide</button>
                    </div>
                </div>
                <div class="reader-setting-group">
                    <label>Theme</label>
                    <div class="reader-toggle-group">
                        <button class="reader-toggle-btn active" data-setting="theme" data-val="default">Default</button>
                        <button class="reader-toggle-btn" data-setting="theme" data-val="contrast-light">Light (HC)</button>
                        <button class="reader-toggle-btn" data-setting="theme" data-val="contrast-dark">Dark (HC)</button>
                    </div>
                </div>
                <div class="reader-setting-group">
                    <label>Font</label>
                    <div class="reader-toggle-group">
                        <button class="reader-toggle-btn active" data-setting="font" data-val="default">Standard</button>
                        <button class="reader-toggle-btn" data-setting="font" data-val="dyslexic">Dyslexic</button>
                    </div>
                </div>
                <div class="reader-setting-group">
                    <label>Speed</label>
                    <div class="reader-toggle-group">
                        <button class="reader-toggle-btn" data-setting="rate" data-val="0.75">0.75x</button>
                        <button class="reader-toggle-btn active" data-setting="rate" data-val="1.0">1x</button>
                        <button class="reader-toggle-btn" data-setting="rate" data-val="1.25">1.25x</button>
                        <button class="reader-toggle-btn" data-setting="rate" data-val="1.5">1.5x</button>
                        <button class="reader-toggle-btn" data-setting="rate" data-val="2.0">2x</button>
                    </div>
                </div>
            </div>
        `;
        document.body.appendChild(toolbar);

        // Bind Events
        document.getElementById('reader-play').addEventListener('click', () => this.toggleSpeech());
        document.getElementById('reader-prev').addEventListener('click', () => this.nav(-1));
        document.getElementById('reader-next').addEventListener('click', () => this.nav(1));

        const settingsToggle = document.getElementById('reader-settings-toggle');
        const settingsPopover = document.getElementById('reader-settings');

        settingsToggle.addEventListener('click', (e) => {
            e.stopPropagation();
            settingsPopover.classList.toggle('active');
        });

        // Close on click outside
        document.addEventListener('click', (e) => {
            if (!settingsPopover.contains(e.target) && e.target !== settingsToggle) {
                settingsPopover.classList.remove('active');
            }
        });

        // Setting Buttons
        document.querySelectorAll('.reader-toggle-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const setting = e.target.dataset.setting;
                const val = e.target.dataset.val;

                // Update State
                this.settings[setting] = val;
                this.applySettings();
                this.saveSettings();

                // UI Feedback
                e.target.parentNode.querySelectorAll('button').forEach(b => b.classList.remove('active'));
                e.target.classList.add('active');
            });
        });
    }

    // --- CONTENT PROCESSING ---
    chunkContent() {
        this.chunks = [];
        this.contentContainer.classList.add('accessible-content');

        // Heuristic: If we have explicit verse blocks or P tags, use them.
        let nodes = Array.from(this.contentContainer.querySelectorAll('.verse-block, .verse-unit, p, li, .song-line'));

        // If structured nodes found
        if (nodes.length > 0) {
            nodes.forEach((node, idx) => {
                // Ensure it has text
                const text = node.innerText.trim();
                // Filter out just numbers (often verse numbers)
                if (text.length > 0 && /[a-zA-Z\u0900-\u097F]/.test(text)) {
                    node.setAttribute('data-reader-idx', idx);
                    this.chunks.push({ element: node, text: text });
                }
            });
        }
        // Fallback: Just split plain text
        else {
            const rawText = this.contentContainer.innerText;
            // Split by sentences (naive)
            const sentences = rawText.match(/[^.!?]+[.!?]+/g) || [rawText];
            this.contentContainer.innerHTML = ''; // Clear

            sentences.forEach((sent, idx) => {
                const span = document.createElement('span');
                span.textContent = sent + ' ';
                span.className = 'reader-chunk';
                span.setAttribute('data-reader-idx', idx);
                this.contentContainer.appendChild(span);
                this.chunks.push({ element: span, text: sent });
            });
        }

        this.updateStatus('Ready to read');
    }

    // --- SPEECH ---
    toggleSpeech() {
        if (this.isPlaying) {
            this.pause();
        } else {
            this.play();
        }
    }

    play() {
        if (!this.chunks.length) return;

        this.isPlaying = true;
        document.getElementById('reader-play').innerHTML = '⏸ Pause';

        // Check if audio is already playing?
        // If not, start chunk
        this.speakChunk(this.currentIndex);
    }

    pause() {
        this.isPlaying = false;
        this.synth.cancel();
        document.getElementById('reader-play').innerHTML = '▶ Play';
        this.updateStatus('Paused');
    }

    speakChunk(index) {
        if (index >= this.chunks.length) {
            this.pause();
            return;
        }

        this.currentIndex = index;
        const chunk = this.chunks[index];

        this.highlight(chunk.element);
        chunk.element.scrollIntoView({ behavior: 'smooth', block: 'center' });
        this.updateStatus(`Reading ${index + 1}/${this.chunks.length}`);

        this.speakNative(chunk);
    }

    speakNative(chunk) {
        this.synth.cancel(); // Clear queue
        const utterance = new SpeechSynthesisUtterance(chunk.text);

        // Language Handling
        if (this.language === 'hi') {
            utterance.lang = 'hi-IN';
            // Try to find a specific Hindi voice
            const voices = this.synth.getVoices();
            console.log("Available Voices:", voices.map(v => `${v.name} (${v.lang})`)); // Debug log

            const hindiVoice = voices.find(v =>
                v.lang.replace('_', '-').toLowerCase() === 'hi-in' ||
                v.name.toLowerCase().includes('hindi') ||
                v.name.toLowerCase().includes('google हिन्दी') ||
                v.name.toLowerCase().includes('lekha') ||
                v.name.toLowerCase().includes('hemant') ||
                v.name.toLowerCase().includes('kalpana')
            );

            if (hindiVoice) {
                console.log("Selected Hindi Voice:", hindiVoice.name);
                utterance.voice = hindiVoice;
            } else {
                console.warn("No specific Hindi voice found.");
                // Fallback: Try Indian English (en-IN) which often handles Indian names/terms better than US
                const indianVoice = voices.find(v => v.lang === 'en-IN' || v.name.includes('India'));
                if (indianVoice) {
                    console.log("Fallback: Using Indian English voice:", indianVoice.name);
                    utterance.voice = indianVoice;
                }
            }
        } else {
            utterance.lang = 'en-US';
        }

        // Speed Control
        utterance.rate = parseFloat(this.settings.rate) || 1.0;

        utterance.onend = () => {
            // Only continue if we are strictly in Native mode OR Neural failed to Native fallback and we want to continue loop
            // Because speakChunk calls speakNative, this continuation logic should be safe
            if (this.isPlaying) {
                this.currentIndex++;
                if (this.currentIndex < this.chunks.length) {
                    this.speakChunk(this.currentIndex);
                } else {
                    this.pause(); // Reset at end
                    this.currentIndex = 0;
                }
            }
        };

        this.synth.speak(utterance);
    }

    setLanguage(lang) {
        this.language = lang;
    }

    nav(dir) {
        let newIndex = this.currentIndex + dir;
        if (newIndex >= 0 && newIndex < this.chunks.length) {
            this.currentIndex = newIndex;
            if (this.isPlaying) {
                this.speakChunk(this.currentIndex); // Auto play next
            } else {
                this.highlight(this.chunks[this.currentIndex].element);
                this.chunks[this.currentIndex].element.scrollIntoView({ behavior: 'smooth', block: 'center' });
                this.updateStatus(`Selected ${this.currentIndex + 1}`);
            }
        }
    }

    highlight(element) {
        // Remove old
        document.querySelectorAll('.tts-highlight').forEach(el => el.classList.remove('tts-highlight'));
        element.classList.add('tts-highlight');
    }

    updateStatus(msg) {
        const statusEl = document.getElementById('reader-status');
        if (statusEl) statusEl.textContent = msg;
    }

    // --- SETTINGS ---
    loadSettings() {
        const saved = localStorage.getItem('sakshi-reader-settings');
        if (saved) {
            this.settings = { ...this.settings, ...JSON.parse(saved) };
        }
    }

    saveSettings() {
        localStorage.setItem('sakshi-reader-settings', JSON.stringify(this.settings));
    }

    applySettings() {
        const body = document.body;
        const container = this.contentContainer;

        // Clean classes
        container.classList.remove(
            'text-size-sm', 'text-size-md', 'text-size-lg', 'text-size-xl',
            'line-height-tight', 'line-height-normal', 'line-height-loose',
            'reader-dyslexic', 'reader-high-contrast-light', 'reader-high-contrast-dark'
        );
        body.classList.remove('reader-high-contrast-light', 'reader-high-contrast-dark'); // Theme affects body

        // Apply Sizes
        container.classList.add(`text-size-${this.settings.fontSize}`);
        container.classList.add(`line-height-${this.settings.lineHeight}`);

        // Apply Font
        if (this.settings.font === 'dyslexic') {
            container.classList.add('reader-dyslexic');
        }

        // Apply Theme
        if (this.settings.theme !== 'default') {
            body.classList.add(`reader-${this.settings.theme}`); // Body for global bg
            container.classList.add(`reader-${this.settings.theme}`); // Container for specifics
        }

        // Update Buttons
        document.querySelectorAll(`.reader-toggle-btn[data-val="${this.settings.fontSize}"]`).forEach(b => b.classList.add('active'));
    }

    setupKeyboardShortcuts() {
        this.keyHandler = (e) => {
            if (e.code === 'Space') {
                e.preventDefault(); // Stop scroll
                this.toggleSpeech();
            } else if (e.code === 'ArrowDown') {
                e.preventDefault();
                this.nav(1);
            } else if (e.code === 'ArrowUp') {
                e.preventDefault();
                this.nav(-1);
            }
        };
        document.addEventListener('keydown', this.keyHandler);
    }

    destroy() {
        this.pause();
        if (this.keyHandler) {
            document.removeEventListener('keydown', this.keyHandler);
        }

        // Remove toolbar to clean up event listeners bound to this instance
        const toolbar = document.querySelector('.reader-toolbar');
        if (toolbar) {
            toolbar.remove();
        }
    }
}

// Global expose
window.AccessibleReader = AccessibleReader;
