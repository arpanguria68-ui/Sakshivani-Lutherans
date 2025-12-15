import React, { useState } from 'react';
import { View, ScrollView, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { RouteProp } from '@react-navigation/native';
import { MoonTheme } from '../components/moon/theme';
import { MoonText } from '../components/moon/MoonText';
import { MoonButton } from '../components/moon/MoonButton';
import { RootStackParamList, Song } from '../types';
import songsData from '../data/songs.json';
import { Ionicons } from '@expo/vector-icons';

type Props = {
    navigation: NativeStackNavigationProp<RootStackParamList, 'SongDetail'>;
    route: RouteProp<RootStackParamList, 'SongDetail'>;
};

export const SongDetailScreen: React.FC<Props> = ({ navigation, route }) => {
    const { songId } = route.params;
    const song = songsData.find(s => s.id === songId) as Song | undefined;

    const mode = 'moonlight';
    const theme = MoonTheme.colors[mode];
    const [fontSize, setFontSize] = useState(20);

    if (!song) {
        return (
            <View style={[styles.container, { backgroundColor: theme.background, justifyContent: 'center' }]}>
                <MoonText align="center">Song not found</MoonText>
            </View>
        );
    }

    return (
        <SafeAreaView style={[styles.container, { backgroundColor: theme.background }]}>
            {/* Custom Header */}
            <View style={styles.header}>
                <MoonButton
                    title=""
                    icon={<Ionicons name="arrow-back" size={24} color={theme.textDisplay} />}
                    variant="ghost"
                    onPress={() => navigation.goBack()}
                    style={{ paddingHorizontal: 0 }}
                />
                <View style={{ flex: 1, alignItems: 'center' }}>
                    <MoonText variant="caption" color={theme.textMuted}>{song.category}</MoonText>
                    <MoonText variant="heading" style={{ fontSize: 18 }}>Geet {song.id}</MoonText>
                </View>
                <MoonButton
                    title=""
                    icon={<Ionicons name="heart-outline" size={24} color={theme.textDisplay} />}
                    variant="ghost"
                    onPress={() => { }}
                    style={{ paddingHorizontal: 0 }}
                />
            </View>

            <ScrollView contentContainerStyle={styles.content}>
                <MoonText variant="heading" align="center" style={{ marginBottom: 24, fontSize: 24 }}>
                    {song.title}
                </MoonText>

                <MoonText
                    variant="body"
                    serif
                    style={{ fontSize, lineHeight: fontSize * 1.6, textAlign: 'center' }}
                >
                    {song.lyrics}
                </MoonText>

                {song.reference && (
                    <View style={styles.reference}>
                        <MoonText variant="caption" color={theme.textMuted} align="center">Reference: {song.reference}</MoonText>
                    </View>
                )}
            </ScrollView>

            {/* Floating Controls */}
            <View style={styles.controls}>
                <MoonButton
                    title="A-"
                    variant="secondary"
                    size="sm"
                    onPress={() => setFontSize(s => Math.max(16, s - 2))}
                />
                <MoonButton
                    title="A+"
                    variant="secondary"
                    size="sm"
                    onPress={() => setFontSize(s => Math.min(32, s + 2))}
                />
            </View>
        </SafeAreaView>
    );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
    },
    header: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: MoonTheme.spacing.md,
        paddingVertical: MoonTheme.spacing.sm,
        justifyContent: 'space-between',
    },
    content: {
        padding: MoonTheme.spacing.lg,
        paddingBottom: 100,
    },
    reference: {
        marginTop: MoonTheme.spacing.xl,
        paddingTop: MoonTheme.spacing.lg,
        borderTopWidth: 1,
        borderTopColor: 'rgba(255,255,255,0.1)',
    },
    controls: {
        position: 'absolute',
        bottom: 30,
        right: 30,
        flexDirection: 'row',
        gap: 10,
    }
});
