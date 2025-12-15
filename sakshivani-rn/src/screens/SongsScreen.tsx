import React, { useState, useMemo } from 'react';
import { View, FlatList, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { MoonTheme } from '../components/moon/theme';
import { MoonText } from '../components/moon/MoonText';
import { MoonInput } from '../components/moon/MoonInput';
import { MoonCard } from '../components/moon/MoonCard';
import { RootStackParamList, Song } from '../types';
import songsData from '../data/songs.json';
import Fuse from 'fuse.js';

type Props = {
    navigation: NativeStackNavigationProp<RootStackParamList, 'Songs'>;
};

export const SongsScreen: React.FC<Props> = ({ navigation }) => {
    const mode = 'moonlight';
    const theme = MoonTheme.colors[mode];
    const [search, setSearch] = useState('');

    // Configure Fuse for fuzzy search
    const fuse = useMemo(() => new Fuse(songsData, {
        keys: ['title', 'id', 'lyrics'],
        threshold: 0.3,
    }), []);

    const filteredSongs = useMemo(() => {
        if (!search) return songsData as Song[];
        return fuse.search(search).map(result => result.item) as Song[];
    }, [search, fuse]);

    const renderItem = ({ item }: { item: Song }) => (
        <MoonCard
            variant="ghost"
            style={styles.songItem}
            onPress={() => navigation.navigate('SongDetail', { songId: item.id })}
        >
            <View style={styles.songRow}>
                <View style={[styles.idBadge, { backgroundColor: theme.surface }]}>
                    <MoonText variant="caption" color={theme.textMuted}>{item.id}</MoonText>
                </View>
                <View style={styles.songInfo}>
                    <MoonText variant="body" numberOfLines={1}>{item.title}</MoonText>
                    <MoonText variant="caption" color={theme.textMuted} numberOfLines={1}>
                        {item.category}
                    </MoonText>
                </View>
            </View>
        </MoonCard>
    );

    return (
        <SafeAreaView style={[styles.container, { backgroundColor: theme.background }]}>
            <View style={styles.header}>
                <MoonText variant="heading" style={{ marginBottom: 16 }}>गीत पुस्तक</MoonText>
                <MoonInput
                    placeholder="Search songs..."
                    value={search}
                    onChangeText={setSearch}
                    icon="search"
                />
            </View>

            <FlatList
                data={filteredSongs}
                renderItem={renderItem}
                keyExtractor={item => item.id}
                contentContainerStyle={styles.listContent}
                keyboardShouldPersistTaps="handled"
            />
        </SafeAreaView>
    );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
    },
    header: {
        padding: MoonTheme.spacing.lg,
    },
    listContent: {
        paddingHorizontal: MoonTheme.spacing.md,
        paddingBottom: MoonTheme.spacing.xxl,
    },
    songItem: {
        marginBottom: MoonTheme.spacing.sm,
        padding: MoonTheme.spacing.sm,
    },
    songRow: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    idBadge: {
        width: 40,
        height: 40,
        borderRadius: 20,
        alignItems: 'center',
        justifyContent: 'center',
        marginRight: 16,
    },
    songInfo: {
        flex: 1,
    }
});
