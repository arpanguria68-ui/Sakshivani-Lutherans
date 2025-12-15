import React from 'react';
import { View, FlatList, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { MoonTheme } from '../components/moon/theme';
import { MoonText } from '../components/moon/MoonText';
import { MoonCard } from '../components/moon/MoonCard';
import { RootStackParamList, CatechismChapter } from '../types';
import catechismData from '../data/catechism.json';

type Props = {
    navigation: NativeStackNavigationProp<RootStackParamList, 'Catechism'>;
};

export const CatechismScreen: React.FC<Props> = ({ navigation }) => {
    const mode = 'moonlight';
    const theme = MoonTheme.colors[mode];

    const renderItem = ({ item }: { item: CatechismChapter }) => (
        <MoonCard
            variant="ghost"
            style={styles.chapterItem}
            onPress={() => navigation.navigate('CatechismChapter', { chapterId: item.id })}
        >
            <View style={styles.row}>
                <View style={[styles.numberBox, { backgroundColor: theme.primary }]}>
                    <MoonText variant="caption" color="white">{item.id.split('-')[0]}</MoonText>
                </View>
                <View style={{ flex: 1 }}>
                    <MoonText variant="body" style={{ fontWeight: 'bold' }}>{item.title}</MoonText>
                </View>
            </View>
        </MoonCard>
    );

    return (
        <SafeAreaView style={[styles.container, { backgroundColor: theme.background }]}>
            <View style={styles.header}>
                <MoonText variant="heading">धर्मशिक्षा (Catechism)</MoonText>
                <MoonText variant="caption" color={theme.textMuted} style={{ marginTop: 4 }}>
                    Luther's Small Catechism
                </MoonText>
            </View>

            <FlatList
                data={catechismData}
                renderItem={renderItem}
                keyExtractor={item => item.id}
                contentContainerStyle={styles.listContent}
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
    chapterItem: {
        marginBottom: MoonTheme.spacing.sm,
        paddingVertical: MoonTheme.spacing.md,
        borderBottomWidth: 1,
        borderBottomColor: 'rgba(255,255,255,0.05)',
    },
    row: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    numberBox: {
        width: 32,
        height: 32,
        borderRadius: 8,
        alignItems: 'center',
        justifyContent: 'center',
        marginRight: 16,
    }
});
