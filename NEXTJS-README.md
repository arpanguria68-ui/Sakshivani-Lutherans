# Sakshi Vani - Next.js Version

Modern React-based version of Sakshi Vani with static export for Vercel deployment.

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ installed
- npm or yarn package manager

### Installation

```powershell
# Install dependencies
npm install

# Run development server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to see the app.

## 📦 Build for Production

```powershell
# Create static export
npm run build

# The output will be in the 'out/' folder
# This can be deployed to any static hosting (Vercel, Netlify, etc.)
```

## 🏗️ Project Structure

```
app/
├── page.tsx                    # Landing page
├── layout.tsx                  # Root layout
├── globals.css                 # Global styles
├── dashboard-web/              # Dashboard section
│   ├── page.tsx               # Main dashboard
│   ├── prayer/page.tsx        # Prayer tracker
│   ├── church/page.tsx        # Church attendance
│   ├── reflection/page.tsx    # Daily reflection
│   ├── bible/page.tsx         # Bible reading log
│   └── quiz/page.tsx          # Interactive quiz
└── pwa/                        # PWA section
    ├── page.tsx               # Songs list
    └── catechism/page.tsx     # Catechism chapters

public/
├── shared/                     # Shared CSS/JS from original
├── pwa/                        # PWA assets (songs.json, etc.)
└── dashboard-web/data/         # Bible data
```

## ✨ Features

### Implemented
- ✅ Landing page with app cards
- ✅ Dashboard with tracking features
- ✅ Prayer tracker (time/type logging)
- ✅ Church attendance logger
- ✅ Reflection journal
- ✅ Bible reading tracker
- ✅ Interactive quiz
- ✅ PWA songs list with search
- ✅ Catechism chapter navigation
- ✅ LocalStorage persistence
- ✅ Responsive design
- ✅ Theme toggle (Day/Night)

### To Be Implemented
- ⏳ Individual catechism chapter pages
- ⏳ Bible reader component
- ⏳ TTS integration
- ⏳ Service Worker for offline support

## 🎨 Tech Stack

- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Deployment**: Static Export (Vercel-ready)

## 📝 Development Notes

### Static Export Configuration
The app is configured for static export in `next.config.js`:
- `output: 'export'` - Generates static HTML
- `trailingSlash: true` - Matches Vercel routing
- `images.unoptimized: true` - No image optimization needed

### Data Storage
- Uses `localStorage` for client-side persistence
- Bible data loaded from JSON files in `public/`
- Songs data in `public/pwa/songs.json`

### Routing
- File-based routing via App Router
- Clean URLs with trailing slashes
- Client-side navigation with Next.js Link

## 🚢 Deployment

### Vercel (Recommended)
```bash
# Push to GitHub
git add .
git commit -m "Next.js migration complete"
git push origin nextjs-migration

# Deploy via Vercel Dashboard or CLI
vercel --prod
```

### Manual Static Hosting
```bash
npm run build
# Upload the 'out/' folder to any static host
```

## 🔄 Migration from Static Site

This Next.js version maintains feature parity with the original static site while adding:
- Component reusability
- Better state management
- Type safety with TypeScript
- Modern development experience
- Easier maintenance

## 📚 Learn More

- [Next.js Documentation](https://nextjs.org/docs)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [TypeScript](https://www.typescriptlang.org/docs)

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## 📄 License

Same as original Sakshi Vani project.
