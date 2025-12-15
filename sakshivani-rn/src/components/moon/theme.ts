/**
 * Moon Design System Tokens
 * Version: 1.0 based on Moon DS v1
 */

export const MoonTheme = {
    colors: {
        moonlight: {
            background: '#0F0F14',      // Deep dark background
            surface: '#1E1E24',         // Card background
            surfaceGlass: 'rgba(30, 30, 36, 0.7)', // Glassmorphism
            primary: '#764BA2',         // Deep Purple
            secondary: '#667EEA',       // Soft Indigo
            accent: '#FFD700',          // Soft Gold/Amber
            textDisplay: '#FFFFFF',
            textBody: '#E0E0E0',
            textMuted: '#9aa5b1',
            success: '#48c774',
            error: '#f14668',
            border: '#2A2A35'
        },
        daylight: {
            background: '#FDFBF7',
            surface: '#FFFFFF',
            surfaceGlass: 'rgba(255, 255, 255, 0.8)',
            primary: '#667EEA',
            secondary: '#764BA2',
            accent: '#F59E0B',
            textDisplay: '#1a202c',
            textBody: '#2d3748',
            textMuted: '#718096',
            success: '#48c774',
            error: '#f14668',
            border: '#E2E8F0'
        }
    },
    radius: {
        sm: 8,
        md: 16,
        lg: 24,
        xl: 32,
        round: 9999
    },
    spacing: {
        xs: 4,
        sm: 8,
        md: 16,
        lg: 24,
        xl: 32,
        xxl: 48
    },
    typography: {
        display: {
            fontFamily: 'NotoSansDevanagari_700Bold',
            fontSize: 28,
            lineHeight: 36
        },
        heading: {
            fontFamily: 'NotoSansDevanagari_700Bold',
            fontSize: 22,
            lineHeight: 30
        },
        body: {
            fontFamily: 'NotoSerifDevanagari_400Regular',
            fontSize: 18,  // Larger base size for Hindi
            lineHeight: 28
        },
        caption: {
            fontFamily: 'NotoSansDevanagari_400Regular',
            fontSize: 14,
            lineHeight: 20
        }
    },
    shadows: {
        soft: {
            shadowColor: "#000",
            shadowOffset: {
                width: 0,
                height: 4,
            },
            shadowOpacity: 0.1,
            shadowRadius: 12,
            elevation: 5,
        },
        glow: {
            shadowColor: "#667EEA",
            shadowOffset: {
                width: 0,
                height: 0,
            },
            shadowOpacity: 0.3,
            shadowRadius: 20,
            elevation: 8,
        }
    }
};

export type ThemeMode = 'moonlight' | 'daylight';
