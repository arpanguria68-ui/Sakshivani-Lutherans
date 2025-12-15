import React from 'react';
import { View, ScrollView, StyleSheet, StatusBar } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { MoonTheme } from '../components/moon/theme';
import { MoonText } from '../components/moon/MoonText';
import { MoonCard } from '../components/moon/MoonCard';
import { MoonButton } from '../components/moon/MoonButton';
import { RootStackParamList } from '../types';
import { Ionicons } from '@expo/vector-icons';

type Props = {
    navigation: NativeStackNavigationProp<RootStackParamList, 'Home'>;
};

export const HomeScreen: React.FC<Props> = ({ navigation }) => {
    const mode = 'moonlight'; // Default to dark/moon theme
    const theme = MoonTheme.colors[mode];

    return (
        <SafeAreaView style={[styles.container, { backgroundColor: theme.background }]}>
            <StatusBar barStyle="light-content" backgroundColor={theme.background} />

            <ScrollView contentContainerStyle={styles.scrollContent}>

                {/* Header */}
                <View style={styles.header}>
                    <MoonText variant="display" mode={mode}>साक्षी वाणी</MoonText>
                    <MoonText variant="body" mode={mode} color={theme.textMuted}>
                        Songs • Catechism • Quiz
                    </MoonText>
                </View>

                {/* Hero Card */}
                <MoonCard variant="hero" mode={mode} style={styles.heroCard}>
                    <View>
                        <MoonText variant="heading" color="white" style={{ marginBottom: 8 }}>
                            आज का वचन
                        </MoonText>
                        <MoonText variant="body" color="rgba(255,255,255,0.9)" serif>
                            "क्योंकि परमेश्वर ने जगत से ऐसा प्रेम रखा कि उसने अपना एकलौता पुत्र दे दिया..."
                        </MoonText>
                        <MoonText variant="caption" color="rgba(255,255,255,0.7)" style={{ marginTop: 8 }}>
                            यूहन्ना 3:16
                        </MoonText>
                    </View>
                </MoonCard>

                {/* Quick Actions Grid */}
                <View style={styles.grid}>
                    {/* Songs */}
                    <MoonCard
                        variant="glass"
                        mode={mode}
                        style={styles.gridItem}
                        onPress={() => navigation.navigate('Songs')}
                    >
                        <Ionicons name="musical-notes" size={32} color={theme.secondary} />
                        <MoonText variant="heading" style={{ marginTop: 12 }}>गीत</MoonText>
                        <MoonText variant="caption" color={theme.textMuted}>350+ Songs</MoonText>
                    </MoonCard>

                    {/* Catechism */}
                    <MoonCard
                        variant="glass"
                        mode={mode}
                        style={styles.gridItem}
                        onPress={() => navigation.navigate('Catechism')}
                    >
                        <Ionicons name="book" size={32} color={theme.accent} />
                        <MoonText variant="heading" style={{ marginTop: 12 }}>धर्मशिक्षा</MoonText>
                        <MoonText variant="caption" color={theme.textMuted}>Study</MoonText>
                    </MoonCard>
                </View>

                {/* Quiz Banner */}
                <MoonCard
                    variant="solid"
                    mode={mode}
                    style={styles.quizBanner}
                    onPress={() => navigation.navigate('Quiz')}
                >
                    <View style={styles.quizContent}>
                        <View style={{ flex: 1 }}>
                            <MoonText variant="heading" color={theme.primary}>Bible Quiz</MoonText>
                            <MoonText variant="body" style={{ fontSize: 14 }}>
                                अपने ज्ञान को परखें और नया सीखें
                            </MoonText>
                        </View>
                        <MoonButton
                            title="Play"
                            onPress={() => navigation.navigate('Quiz')}
                            size="sm"
                        />
                    </View>
                </MoonCard>

            </ScrollView>
        </SafeAreaView>
    );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
    },
    scrollContent: {
        padding: MoonTheme.spacing.lg,
    },
    header: {
        marginBottom: MoonTheme.spacing.xl,
        marginTop: MoonTheme.spacing.md,
    },
    heroCard: {
        marginBottom: MoonTheme.spacing.xl,
        minHeight: 160,
        justifyContent: 'center',
    },
    grid: {
        flexDirection: 'row',
        gap: MoonTheme.spacing.md,
        marginBottom: MoonTheme.spacing.lg,
    },
    gridItem: {
        flex: 1,
        alignItems: 'center',
        paddingVertical: MoonTheme.spacing.lg,
        aspectRatio: 0.85,
        justifyContent: 'center'
    },
    quizBanner: {
        padding: MoonTheme.spacing.md,
    },
    quizContent: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
    }
});
