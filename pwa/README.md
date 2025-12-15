# Sakshi Vani PWA

This is a modern Progressive Web App (PWA) version of the Sakshi Vani Android app.
It runs on **Android**, **iOS**, and **Desktop** devices.

## Features
- **Cross-Platform**: Works in any modern browser.
- **Offline Capable**: Works without internet once loaded (using Service Worker).
- **Unicode Hindi**: All songs converted from legacy Chanakya font to standard Unicode.
- **Search**: Instant search by Title, ID, or Lyrics.
- **Dark Mode**: Automatically adapts to your device theme.

## How to Run Locally
You can run this using any static file server.

### Using Python (if installed)
1. Open a terminal in this folder.
2. Run: `python -m http.server 3000`
3. Open `http://localhost:3000` in your browser.

### Using VS Code
1. Open this folder in VS Code.
2. Install "Live Server" extension.
3. Right-click `index.html` and choose "Open with Live Server".

## How to Deploy (Online)
To make the app accessible on mobile devices, deploy it to a free host:

1. **GitHub Pages**: Upload these files to a GitHub repository and enable Pages.
2. **Netlify/Vercel**: Drag and drop this folder onto their dashboard.

## How to Install on Mobile
Once hosted (or running locally):
1. Open the URL in Chrome (Android) or Safari (iOS).
2. Tap the **Share** button (iOS) or **Menu** button (Android).
3. Select **"Add to Home Screen"**.
4. The app will appear as a native app icon on your device.
