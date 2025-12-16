# Sakshi Vani - Deployment Guide

## 📦 What's Deployable to Vercel

Your repository now has **TWO separate web applications** ready for Vercel deployment:

### 1. **PWA (Progressive Web App)** - `/pwa/`
- **Main landing**: Songs list and search
- **Catechism**: Full catechism with 10 chapters
- **Access URL**: `https://your-domain.vercel.app/`

### 2. **Dashboard (Web Version)** - `/dashboard-web/`
- **Home**: Daily verse, greeting, navigation cards
- **My Journey**: Progress tracking dashboard
- **Prayer Tracker**: Log prayers by time and type
- **Access URL**: `https://your-domain.vercel.app/dashboard`

### 3. **React Native Mobile App** - `/sakshivani-rn/`
- ❌ **NOT deployed to Vercel**
- ✅ This is for native mobile apps (Android APK / iOS IPA)
- Requires separate build process

---

## 🚀 Deployment Instructions

### Step 1: Go to Vercel
Visit [vercel.com](https://vercel.com) and sign in with your GitHub account.

### Step 2: Import Repository
1. Click **"New Project"**
2. Import: `arpanguria68-ui/Sakshivani-Lutherans`
3. Vercel will auto-detect the configuration

### Step 3: Deploy
Click **"Deploy"** - No configuration needed! The `vercel.json` handles everything.

### Step 4: Access Your Sites

After deployment (1-2 minutes), you'll have:

- **Main PWA**: `https://sakshivani-lutherans.vercel.app/`
  - Songs: `/`
  - Catechism: `/catechism.html`
  - Individual catechism chapters: `/catechism/1-commandments.html`, etc.

- **Dashboard**: `https://sakshivani-lutherans.vercel.app/dashboard`
  - Home: `/dashboard`
  - My Journey: `/dashboard/dashboard.html`
  - Prayer Tracker: `/dashboard/prayer.html`

---

## 🎨 Dashboard Features

### ✅ Currently Implemented:
- ✅ Home dashboard with verse of the day
- ✅ Dark/Light theme toggle
- ✅ My Journey progress tracking
- ✅ Prayer tracker (fully functional)
- ✅ Links to Songs and Catechism
- ✅ localStorage for data persistence
- ✅ Responsive design

### 📝 Planned (Templates Ready):
- Bible Reading Logger
- Church Attendance Tracker
- Daily Reflection Journal
- Bible Quiz

---

## 📁 Repository Structure

```
.
├── pwa/                     # Main PWA (Songs & Catechism)
│   ├── index.html          # Songs list
│   ├── catechism.html      # Catechism index
│   ├── catechism/          # 10 catechism chapters
│   ├── songs.json          # Songs database
│   ├── app.js              # PWA logic
│   └── sw.js               # Service Worker
│
├── dashboard-web/           # Dashboard (Spiritual Tracking)
│   ├── index.html          # Home dashboard
│   ├── dashboard.html      # My Journey page
│   ├── prayer.html         # Prayer tracker
│   ├── style.css           # All dashboard styles
│   ├── app.js              # Dashboard logic
│   └── manifest.json       # PWA manifest
│
├── sakshivani-rn/          # React Native Mobile App (NOT on Vercel)
│
├── vercel.json             # Vercel deployment config
├── package.json            # NPM package info
└── README.md               # Main documentation
```

---

## 🔗 URL Routing

### PWA Routes:
- `/` → Songs homepage
- `/catechism.html` → Catechism index
- `/catechism/1-commandments.html` → Ten Commandments
- `/catechism/2-creed.html` → The Creed
- (etc. for all 10 chapters)

### Dashboard Routes:
- `/dashboard` → Dashboard home
- `/dashboard/dashboard.html` → My Journey
- `/dashboard/prayer.html` → Prayer tracker

---

## 🛠️ Local Testing

### Test PWA:
```bash
cd pwa
python -m http.server 8000
# Visit: http://localhost:8000
```

### Test Dashboard:
```bash
cd dashboard-web
python -m http.server 8001
# Visit: http://localhost:8001
```

---

## 📱 Mobile App (React Native)

To build the mobile app separately:

```bash
cd sakshivani-rn
npm install
npx expo start
```

For APK build:
```bash
eas build --platform android
```

---

## ✨ Key Features

### PWA:
- 📖 350+ Hindi Lutheran songs with search
- ✝️ Complete catechism in 10 chapters
- 🔍 Fast search functionality
- 📴 Offline support via Service Worker

### Dashboard:
- 📊 Track prayers, Bible reading, church visits
- 📝 Daily reflections journal
- 🌓 Dark/Light theme toggle
- 💾 Local data storage (private, browser-based)
- 🎨 Beautiful Moon Design System aesthetic

---

## 🎯 Next Steps

1. **Deploy to Vercel** following the steps above
2. **Test both sites** on mobile and desktop
3. **Share with your community**
4. **Add custom domain** (optional) in Vercel settings

---

## 📞 Support

For issues or questions about deployment:
- Check Vercel docs: https://vercel.com/docs
- Review `vercel.json` configuration
- Check browser console for errors

---

Made with ❤️ for the Sakshi Vani Lutheran community
