# Sakshi Vani Dashboard (Web Version)

A beautiful, interactive web dashboard for tracking your spiritual journey. Built as a companion to the Sakshi Vani PWA and mobile app.

## 🌟 Features

- **Home Dashboard**: Daily verse, greeting, and quick access to all features
- **My Journey**: Track prayers, Bible reading, church attendance, and reflections
- **Prayer Tracker**: Log different types of prayers throughout the day
- **Dark/Light Theme**: Toggle between moonlight and daylight themes
- **Responsive Design**: Works beautifully on desktop, tablet, and mobile
- **LocalStorage Tracking**: All your data stays private on your device

## 🎨 Design

Built with the Moon Design System aesthetic:
- Smooth gradients and glassmorphism
- Fluid animations and micro-interactions
- Devanagari-optimized typography (Noto Sans/Serif Devanagari)
- Premium color palette with primary (#5B8DEE) and secondary (#A78BFA)

## 🚀 Deployment

### Deploy to Vercel

This dashboard can be deployed separately or alongside the main PWA.

#### Separate Deployment:
```bash
cd dashboard-web
vercel
```

#### As Part of Main Site:
The dashboard is in the `dashboard-web` folder and can be accessed via `/dashboard-web/` when deployed with the main site.

## 📁 File Structure

```
dashboard-web/
├── index.html           # Home dashboard
├── dashboard.html       # My Journey (activity tracking)
├── prayer.html          # Prayer tracker
├── bible.html           # Bible reading log (planned)
├── church.html          # Church attendance log (planned)
├── reflection.html      # Daily reflection journal (planned)
├── quiz.html            # Bible quiz (planned)
├── style.css            # All styles
├── app.js               # Interactivity & localStorage
└── manifest.json        # PWA manifest
```

## 🔗 Integration

Links to the main PWA:
- **Songs**: `../pwa/index.html`
- **Catechism**: `../pwa/catechism.html`

## 📱 Local Development

```bash
cd dashboard-web
python -m http.server 8000
```

Then visit: `http://localhost:8000`

## 💾 Data Storage

All tracking data is stored locally in your browser's localStorage:
- `prayerLogs` - Prayer tracking history
- `bibleLogs` - Bible reading history  
- `churchLogs` - Church attendance history
- `reflectionLogs` - Daily reflections
- `theme` - Theme preference (dark/light)
- `verseDate` & `verseIndex` - Daily verse rotation

## 🌐 Browser Support

Works on all modern browsers:
- Chrome/Edge 88+
- Firefox 78+
- Safari 14+
- Mobile browsers

## 📄 License

ISC
