import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { HomeScreen } from '../screens/HomeScreen';
import { SongsScreen } from '../screens/SongsScreen';
import { SongDetailScreen } from '../screens/SongDetailScreen';
import { CatechismScreen } from '../screens/CatechismScreen';
import { CatechismChapterScreen } from '../screens/CatechismChapterScreen';
import { QuizScreen } from '../screens/QuizScreen';
import { MoonTheme } from '../components/moon/theme';
import { RootStackParamList } from '../types';
import { StatusBar } from 'expo-status-bar';

const Stack = createNativeStackNavigator<RootStackParamList>();

export const AppNavigator = () => {
    const theme = MoonTheme.colors.moonlight;

    return (
        <NavigationContainer>
            <StatusBar style="light" />
            <Stack.Navigator
                screenOptions={{
                    headerStyle: { backgroundColor: theme.background },
                    headerTintColor: theme.textDisplay,
                    headerShadowVisible: false,
                    headerTitleStyle: { fontFamily: 'NotoSansDevanagari_700Bold' },
                    contentStyle: { backgroundColor: theme.background },
                }}
            >
                <Stack.Screen
                    name="Home"
                    component={HomeScreen}
                    options={{ headerShown: false }}
                />
                <Stack.Screen
                    name="Songs"
                    component={SongsScreen}
                    options={{ title: 'Geet' }}
                />
                <Stack.Screen
                    name="SongDetail"
                    component={SongDetailScreen}
                    options={{ title: '', headerTransparent: true }}
                />
                <Stack.Screen
                    name="Catechism"
                    component={CatechismScreen}
                    options={{ title: 'Dharmashiksha' }}
                />
                <Stack.Screen
                    name="CatechismChapter"
                    component={CatechismChapterScreen}
                    options={{ title: 'Study' }}
                />
                <Stack.Screen
                    name="Quiz"
                    component={QuizScreen}
                    options={{ title: 'Bible Quiz' }}
                />
            </Stack.Navigator>
        </NavigationContainer>
    );
};
