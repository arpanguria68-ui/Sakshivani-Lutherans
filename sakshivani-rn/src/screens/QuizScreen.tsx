import React, { useState } from 'react';
import { View, StyleSheet, ScrollView, Animated } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { MoonTheme } from '../components/moon/theme';
import { MoonText } from '../components/moon/MoonText';
import { MoonButton } from '../components/moon/MoonButton';
import { MoonCard } from '../components/moon/MoonCard';
import { RootStackParamList, Question } from '../types';
import quizData from '../data/quiz_data.json';

type Props = {
    navigation: NativeStackNavigationProp<RootStackParamList, 'Quiz'>;
};

export const QuizScreen: React.FC<Props> = ({ navigation }) => {
    const mode = 'moonlight';
    const theme = MoonTheme.colors[mode];

    const [currentQuestionIdx, setCurrentQuestionIdx] = useState(0);
    const [score, setScore] = useState(0);
    const [isFinished, setIsFinished] = useState(false);
    const [selectedOption, setSelectedOption] = useState<number | null>(null);
    const [isAnswerRevealed, setIsAnswerRevealed] = useState(false);

    const currentQuestion: Question = quizData[currentQuestionIdx];

    const handleOptionSelect = (index: number) => {
        if (isAnswerRevealed) return;

        setSelectedOption(index);
        setIsAnswerRevealed(true);

        if (index === currentQuestion.correctOptionIndex) {
            setScore(s => s + 1);
        }
    };

    const nextQuestion = () => {
        if (currentQuestionIdx < quizData.length - 1) {
            setCurrentQuestionIdx(prev => prev + 1);
            setSelectedOption(null);
            setIsAnswerRevealed(false);
        } else {
            setIsFinished(true);
        }
    };

    if (isFinished) {
        return (
            <SafeAreaView style={[styles.container, { backgroundColor: theme.background, justifyContent: 'center', alignItems: 'center' }]}>
                <MoonCard variant="glass" style={styles.resultCard}>
                    <MoonText variant="display" align="center"> 🎉 Quiz Complete!</MoonText>
                    <MoonText variant="heading" align="center" style={{ marginTop: 20 }}>
                        Your Score: {score} / {quizData.length}
                    </MoonText>
                    <MoonButton
                        title="Back Home"
                        onPress={() => navigation.navigate('Home')}
                        style={{ marginTop: 40 }}
                        fullWidth
                    />
                </MoonCard>
            </SafeAreaView>
        );
    }

    return (
        <SafeAreaView style={[styles.container, { backgroundColor: theme.background }]}>
            <View style={styles.header}>
                <MoonText variant="heading">Question {currentQuestionIdx + 1}/{quizData.length}</MoonText>
                <View style={styles.scoreBadge}>
                    <MoonText variant="caption" color={theme.primary}>Score: {score}</MoonText>
                </View>
            </View>

            <ScrollView contentContainerStyle={styles.content}>
                <MoonCard variant="solid" style={styles.questionCard}>
                    <MoonText variant="heading" style={{ lineHeight: 34 }}>
                        {currentQuestion.text}
                    </MoonText>
                </MoonCard>

                <View style={styles.optionsContainer}>
                    {currentQuestion.options.map((option, index) => {
                        let variant: 'primary' | 'outline' | 'ghost' = 'outline';
                        let icon = null;

                        if (isAnswerRevealed) {
                            if (index === currentQuestion.correctOptionIndex) {
                                variant = 'primary'; // Show Correct
                                // icon = check
                            } else if (index === selectedOption) {
                                variant = 'ghost'; // Wrong selected
                            }
                        } else if (index === selectedOption) {
                            variant = 'primary';
                        }

                        return (
                            <MoonButton
                                key={index}
                                title={option}
                                variant={variant}
                                onPress={() => handleOptionSelect(index)}
                                style={styles.optionButton}
                                fullWidth
                            />
                        );
                    })}
                </View>

                {isAnswerRevealed && (
                    <View style={styles.explanation}>
                        <MoonCard variant="glass" style={{ borderColor: theme.success }}>
                            <MoonText variant="caption" color={theme.success}>EXPLANATION</MoonText>
                            <MoonText variant="body" style={{ marginTop: 8 }}>
                                {currentQuestion.explanation}
                            </MoonText>
                            <MoonButton
                                title={currentQuestionIdx === quizData.length - 1 ? "Finish" : "Next Question"}
                                onPress={nextQuestion}
                                style={{ marginTop: 16 }}
                            />
                        </MoonCard>
                    </View>
                )}
            </ScrollView>
        </SafeAreaView>
    );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
    },
    header: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        padding: MoonTheme.spacing.lg,
        alignItems: 'center',
    },
    scoreBadge: {
        padding: 8,
        backgroundColor: 'rgba(118, 75, 162, 0.2)',
        borderRadius: MoonTheme.radius.md,
    },
    content: {
        padding: MoonTheme.spacing.lg,
    },
    questionCard: {
        minHeight: 150,
        justifyContent: 'center',
        marginBottom: MoonTheme.spacing.xl,
        padding: MoonTheme.spacing.xl,
    },
    optionsContainer: {
        gap: MoonTheme.spacing.md,
    },
    optionButton: {
        marginBottom: 8,
    },
    explanation: {
        marginTop: MoonTheme.spacing.xl,
    },
    resultCard: {
        padding: MoonTheme.spacing.xxl,
        width: '90%',
        alignItems: 'center',
    }
});
