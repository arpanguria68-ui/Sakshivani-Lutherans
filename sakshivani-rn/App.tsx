import { useCallback } from 'react';
import { Platform } from 'react-native';
import { useFonts } from 'expo-font';
import * as SplashScreen from 'expo-splash-screen';
import { AppNavigator } from './src/navigation/AppNavigator';
import { SafeAreaProvider } from 'react-native-safe-area-context';

// Only prevent auto-hide on native platforms
if (Platform.OS !== 'web') {
    SplashScreen.preventAutoHideAsync();
}

export default function App() {
    // Skip custom font loading on web - use system fonts instead
    const [fontsLoaded] = Platform.OS === 'web'
        ? [true] // Fonts immediately "loaded" on web
        : useFonts({
            'NotoSansDevanagari_400Regular': require('./assets/fonts/NotoSansDevanagari-Regular.ttf'),
            'NotoSansDevanagari_700Bold': require('./assets/fonts/NotoSansDevanagari-Bold.ttf'),
            'NotoSerifDevanagari_400Regular': require('./assets/fonts/NotoSerifDevanagari-Regular.ttf'),
            'NotoSerifDevanagari_600SemiBold': require('./assets/fonts/NotoSerifDevanagari-SemiBold.ttf'),
        });

    const onLayoutRootView = useCallback(async () => {
        if (fontsLoaded && Platform.OS !== 'web') {
            await SplashScreen.hideAsync();
        }
    }, [fontsLoaded]);

    if (!fontsLoaded) {
        return null;
    }

    return (
        <SafeAreaProvider onLayout={onLayoutRootView}>
            <AppNavigator />
        </SafeAreaProvider>
    );
}
