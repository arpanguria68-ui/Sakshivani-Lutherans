import React from 'react';
import { TouchableOpacity, Text, StyleSheet, ViewStyle } from 'react-native';
import { MoonTheme, ThemeMode } from './theme';

interface MoonButtonProps {
    title: string;
    onPress: () => void;
    mode?: ThemeMode;
    variant?: 'primary' | 'secondary' | 'ghost' | 'outline';
    size?: 'sm' | 'md' | 'lg';
    style?: ViewStyle;
    icon?: React.ReactNode;
    fullWidth?: boolean;
}

export const MoonButton: React.FC<MoonButtonProps> = ({
    title,
    onPress,
    mode = 'moonlight',
    variant = 'primary',
    size = 'md',
    style,
    icon,
    fullWidth
}) => {
    const theme = MoonTheme.colors[mode];

    const getBgColor = () => {
        switch (variant) {
            case 'primary': return theme.primary;
            case 'secondary': return theme.surface;
            case 'ghost': return 'transparent';
            case 'outline': return 'transparent';
            default: return theme.primary;
        }
    };

    const getTextColor = () => {
        switch (variant) {
            case 'primary': return '#FFFFFF';
            case 'secondary': return theme.textDisplay;
            case 'ghost': return theme.textBody;
            case 'outline': return theme.primary;
            default: return '#FFFFFF';
        }
    };

    const containerStyle = [
        styles.container,
        {
            backgroundColor: getBgColor(),
            borderRadius: MoonTheme.radius.round, // Pill shape
            paddingVertical: size === 'sm' ? 8 : (size === 'lg' ? 16 : 12),
            paddingHorizontal: size === 'sm' ? 16 : (size === 'lg' ? 32 : 24),
            borderWidth: variant === 'outline' ? 2 : 0,
            borderColor: theme.primary,
            width: fullWidth ? '100%' : undefined,
            alignSelf: fullWidth ? 'stretch' : 'flex-start'
        },
        variant === 'primary' && MoonTheme.shadows.glow,
        style
    ];

    return (
        <TouchableOpacity style={containerStyle} onPress={onPress} activeOpacity={0.7}>
            {icon}
            <Text style={[
                styles.text,
                {
                    color: getTextColor(),
                    fontSize: size === 'sm' ? 14 : (size === 'lg' ? 18 : 16),
                    marginLeft: icon ? 8 : 0
                }
            ]}>
                {title}
            </Text>
        </TouchableOpacity>
    );
};

const styles = StyleSheet.create({
    container: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
    },
    text: {
        fontFamily: 'NotoSansDevanagari_700Bold',
        fontWeight: '700',
    }
});
