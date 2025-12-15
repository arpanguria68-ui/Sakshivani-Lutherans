import React from 'react';
import { View, ScrollView, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { RouteProp } from '@react-navigation/native';
import { MoonTheme } from '../components/moon/theme';
import { MoonText } from '../components/moon/MoonText';
import { MoonButton } from '../components/moon/MoonButton';
import { RootStackParamList, CatechismChapter } from '../types';
import catechismData from '../data/catechism.json';

type Props = {
    navigation: NativeStackNavigationProp<RootStackParamList, 'CatechismChapter'>;
    route: RouteProp<RootStackParamList, 'CatechismChapter'>;
};

export const CatechismChapterScreen: React.FC<Props> = ({ navigation, route }) => {
    const { chapterId } = route.params;
    const chapterIndex = catechismData.findIndex(c => c.id === chapterId);
    const chapter = catechismData[chapterIndex] as CatechismChapter;

    const mode = 'moonlight';
    const theme = MoonTheme.colors[mode];

    const handleNext = () => {
        if (chapterIndex < catechismData.length - 1) {
            const nextId = catechismData[chapterIndex + 1].id;
            navigation.replace('CatechismChapter', { chapterId: nextId });
        }
    };

    const handlePrev = () => {
        if (chapterIndex > 0) {
            const prevId = catechismData[chapterIndex - 1].id;
            navigation.replace('CatechismChapter', { chapterId: prevId });
        }
    };

    return (
        <SafeAreaView style={[styles.container, { backgroundColor: theme.background }]}>
            <ScrollView contentContainerStyle={styles.content}>
                <MoonText variant="heading" style={{ marginBottom: 20, color: theme.secondary }}>
                    {chapter.title}
                </MoonText>

                {/* Simple markdown rendering (text for now since raw data is MD) */}
                {/* Ideally use a markdown renderer here */}
                <MoonText variant="body" serif style={{ lineHeight: 36 }}>
                    {chapter.content
                        .replace(/\[cite_start\]/g, '')  // Remove [cite_start] tags
                        .replace(/\[cite:\s*[^\]]*\]/g, '')  // Remove [cite: ...] tags
                        .replace(/#{1,6}\s*/g, '')  // Remove markdown headers
                        .replace(/\*\*/g, '')  // Remove bold markers
                        .replace(/\*/g, '')  // Remove italic markers
                        .replace(/>\s*/g, '')  // Remove blockquote markers
                        .trim()
                    }
                </MoonText>
            </ScrollView>

            {/* Navigation Footer */}
            <View style={[styles.footer, { backgroundColor: theme.surface }]}>
                <MoonButton
                    title="Previous"
                    variant="ghost"
                    onPress={handlePrev}
                    style={{ opacity: chapterIndex === 0 ? 0 : 1 }}
                    size="sm"
                />
                <MoonText variant="caption">{chapterIndex + 1} / {catechismData.length}</MoonText>
                <MoonButton
                    title="Next"
                    variant="ghost"
                    onPress={handleNext}
                    style={{ opacity: chapterIndex === catechismData.length - 1 ? 0 : 1 }}
                    size="sm"
                />
            </View>
        </SafeAreaView>
    );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
    },
    content: {
        padding: MoonTheme.spacing.lg,
        paddingBottom: 80,
    },
    footer: {
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: MoonTheme.spacing.md,
        borderTopWidth: 1,
        borderTopColor: 'rgba(255,255,255,0.1)',
    }
});
