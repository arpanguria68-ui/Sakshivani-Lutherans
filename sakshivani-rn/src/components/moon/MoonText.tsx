import React from 'react';
import { Text, TextStyle, StyleSheet } from 'react-native';
import { MoonTheme, ThemeMode } from './theme';

interface MoonTextProps {
    children: React.ReactNode;
    mode?: ThemeMode;
    variant?: 'display' | 'heading' | 'body' | 'caption';
    color?: string;
    style?: TextStyle;
    align?: 'left' | 'center' | 'right';
    serif?: boolean;
}

export const MoonText: React.FC<MoonTextProps> = ({
    children,
    mode = 'moonlight',
    variant = 'body',
    color,
    style,
    align = 'left',
    serif = false
}) => {
    const theme = MoonTheme.colors[mode];
    const typo = MoonTheme.typography[variant];

    // Force Serif for body if requested (reading mode)
    const fontFamily = (serif && variant === 'body') ? 'NotoSerifDevanagari_400Regular' : typo.fontFamily;

    const textStyle = {
        fontFamily: fontFamily,
        fontSize: typo.fontSize,
        lineHeight: typo.lineHeight,
        color: color || (variant === 'display' || variant === 'heading' ? theme.textDisplay : theme.textBody),
        textAlign: align,
    };

    return <Text style={[textStyle, style]}>{children}</Text>;
};
