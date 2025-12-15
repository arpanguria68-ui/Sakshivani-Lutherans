import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ViewStyle, TextStyle } from 'react-native';
import { MoonTheme, ThemeMode } from './theme';

interface MoonCardProps {
    children: React.ReactNode;
    mode?: ThemeMode;
    variant?: 'solid' | 'glass' | 'ghost' | 'hero';
    style?: ViewStyle;
    onPress?: () => void;
}

export const MoonCard: React.FC<MoonCardProps> = ({
    children,
    mode = 'moonlight',
    variant = 'solid',
    style,
    onPress
}) => {
    const theme = MoonTheme.colors[mode];

    const getBackgroundColor = () => {
        switch (variant) {
            case 'solid': return theme.surface;
            case 'glass': return theme.surfaceGlass;
            case 'hero': return theme.primary; // Or gradient in parent
            case 'ghost': return 'transparent';
            default: return theme.surface;
        }
    };

    const containerStyle = [
        styles.card,
        {
            backgroundColor: getBackgroundColor(),
            borderRadius: variant === 'hero' ? MoonTheme.radius.xl : MoonTheme.radius.md,
            borderColor: theme.border,
            borderWidth: variant === 'ghost' ? 0 : 1,
        },
        variant !== 'ghost' && MoonTheme.shadows.soft,
        style
    ];

    if (onPress) {
        return (
            <TouchableOpacity style={containerStyle} onPress={onPress} activeOpacity={0.8}>
                {children}
            </TouchableOpacity>
        );
    }

    return <View style={containerStyle}>{children}</View>;
};

const styles = StyleSheet.create({
    card: {
        padding: MoonTheme.spacing.md,
        overflow: 'hidden',
    }
});
