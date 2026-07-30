# Play Store listing — Sakshi Vani

Copy these fields into Google Play Console → **Grow** → **Store presence** → **Main store listing**.  
Add a **Hindi** listing under **Custom store listings** or **Translations** (locale: `hi-IN`).

---

## English (default)

### App name (max 30)
```
Sakshi Vani
```

### Short description (max 80)
```
Lutheran hymns, Hindi Bible, catechism, prayer & faith journey — offline-first.
```

### Full description (max 4000)
```
Sakshi Vani (साक्षी वाणी) is your digital companion for Lutheran worship and daily faith — built offline-first so hymns, study, and prayer work even with limited connectivity.

WHAT YOU GET

• 350+ Hindi worship songs (Sakshi Vani) plus Mundari Durang Puthi hymns
• Full Bible in Hindi & English — download once, read offline, with text-to-speech
• Luther’s Small Catechism in Hindi — Ten Commandments, Creed, Lord’s Prayer, Sacraments
• Daily verse on the home screen
• Prayer logging and spiritual journey / progress tracking
• Reading plans and quiz for catechism study
• Optional sign-in to sync favorites, reflections, and prayer logs across devices
• Church courtesy reminder and gentle daily verse notifications (optional)

DESIGNED FOR DEVOTION

Warm, readable Hindi typography. Large text controls for singers and elders. Share verses and songs with your congregation.

PRIVACY & CHOICE

Core content works offline without an account. Sign-in, cloud sync, weather location, and ads are optional. Remove ads with a one-time in-app purchase. Read our Privacy Policy and Terms in Settings (English & Hindi), covering USA, Europe, and India.

येशु सहाय — made with love for Hindi-speaking Lutheran communities.
```

### App category
- **Primary:** Books & Reference *(or Lifestyle — pick one; Books & Reference fits Bible/hymns well)*

### Tags / keywords (for your own ASO notes; Play may not show a free-form keyword field)
`Hindi Bible, Lutheran, hymns, catechism, भजन, धर्मशिक्षा, prayer, Gossner, Mundari`

---

## हिंदी (hi-IN)

### ऐप का नाम (अधिकतम 30)
```
साक्षी वाणी
```
*(If Console requires Latin package branding, keep English name “Sakshi Vani” and put Hindi in short/full description.)*

### संक्षिप्त विवरण (अधिकतम 80)
```
लूथरन भजन, हिंदी बाइबल, धर्मशिक्षा, प्रार्थना और विश्वास-यात्रा — ऑफ़लाइन।
```

### पूरा विवरण
```
साक्षी वाणी आपके विश्वास-जीवन का डिजिटल साथी है — लूथरन आराधना, भजन, बाइबल और धर्मशिक्षा एक ही ऐप में। ऑफ़लाइन-फ़र्स्ट डिज़ाइन: कम नेटवर्क पर भी पढ़ें और गाएँ।

मुख्य विशेषताएँ

• 350+ हिंदी आराधना गीत (साक्षी वाणी) और मुंडारी दुरंग पुथी भजन
• पूरी बाइबल हिंदी व अंग्रेज़ी में — एक बार डाउनलोड, फिर ऑफ़लाइन पढ़ें; ज़ोर से पढ़ने (TTS) की सुविधा
• लूथर की छोटी धर्मशिक्षा हिंदी में — दस आज्ञा, विश्वास, प्रभु-प्रार्थना, संस्कार
• होम स्क्रीन पर आज का वचन
• प्रार्थना लॉग और आध्यात्मिक यात्रा / प्रगति
• पठन योजना और प्रश्नोत्तरी
• वैकल्पिक साइन-इन से पसंदीदा, चिंतन और प्रार्थना सिंक
• वैकल्पिक दैनिक वचन और कलीसिया शिष्टाचार रिमाइंडर

गोपनीयता

बिना खाते के मुख्य सामग्री उपयोग करें। साइन-इन, सिंक, स्थान और विज्ञापन वैकल्पिक हैं। विज्ञापन हटाने के लिए एक बार की इन-ऐप खरीदारी। सेटिंग्स में गोपनीयता नीति और नियम (EN / हिंदी) — अमेरिका, यूरोप और भारत।

येशु सहाय।
```

---

## Graphics checklist

| Asset | Size | Source tip |
|-------|------|------------|
| **App icon** | 512×512 PNG | Export from `assets/icon/app_icon.png` (or Play Console “Generate”) |
| **Feature graphic** | 1024×500 PNG/JPEG | Brand cream `#FDF7F2` + brown `#93452B`, title “साक्षी वाणी / Sakshi Vani”, optional dove/cross icon — no small unreadable text |
| **Phone screenshots** | min **2**, ideal **4–8** | 16:9 or 9:16; use Pixel emulator | 
| **Tablet** (optional) | 7" / 10" | Same screens if you support large foldables |

### Screenshot set (capture in this order)

1. **Home** — daily verse hero + greeting (`साक्षी वाणी` title)
2. **Songs** — song list / search
3. **Song reader** — large Hindi lyrics
4. **Bible** — book/chapter picker (after download completes)
5. **Catechism list** — clean titles only (no raw markdown)
6. **Catechism reader** — commandment + meaning block
7. **Journey / prayer** — progress or prayer log
8. **Onboarding slide 1** (optional) — welcome / brand

**Tips**
- Use a clean status bar (full battery, Wi‑Fi, hide personal notifications).
- Prefer light theme for brand consistency.
- Skip screens that show debug banners, empty error states, or AdMob test labels if possible.
- After first Bible open, wait for the ~40 MB download so Bible screenshots show real content.

### Emulator capture (Android Studio)

1. Start Pixel emulator → run the release or debug app.  
2. Open **Extended Controls** (… ) → **Camera** / or use emulator toolbar **📷 Camera** / **Screenshot**.  
3. Or: `adb exec-out screencap -p > shot1.png`  
4. Crop to content if needed; upload PNGs to Play Console.

---

## Release notes (first release)

**EN**
```
Initial release of Sakshi Vani: Hindi hymns, Bible (on-demand download), catechism, prayer logging, reading plans, optional cloud sync, and privacy/terms in English & Hindi.
```

**HI**
```
साक्षी वाणी का पहला संस्करण: हिंदी भजन, बाइबल (माँग पर डाउनलोड), धर्मशिक्षा, प्रार्थना, पठन योजना, वैकल्पिक क्लाउड सिंक, तथा अंग्रेज़ी व हिंदी में गोपनीयता/नियम।
```

---

## Contact (Store listing)

| Field | Suggested |
|-------|-----------|
| Email | Your support Gmail (same as Play developer account is fine) |
| Website (optional) | https://github.com/arpanguria68-ui/Sakshivani-Lutherans |
| Privacy policy | https://github.com/arpanguria68-ui/Sakshivani-Lutherans/blob/main/PRIVACY.md |

---

## IAP listing text (Play Console → Monetize → Products)

**Product ID:** `remove_ads_tier1`  
**Name:** Remove Ads / Supporter  
**Description:** One-time purchase to remove AdMob ads and support Sakshi Vani development.
