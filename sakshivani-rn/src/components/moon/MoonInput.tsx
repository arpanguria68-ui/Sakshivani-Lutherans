import React from 'react';
import { TextInput, StyleSheet, View, TextInputProps } from 'react-native';
import { MoonTheme, ThemeMode } from './theme';
import { Ionicons } from '@expo/vector-icons';

interface MoonInputProps extends TextInputProps {
    mode?: ThemeMode;
    icon?: keyof typeof Ionicons.glyphMap;
}

export const MoonInput: React.FC<MoonInputProps> = ({
    mode = 'moonlight',
    icon,
    style,
    ...props
}) => {
    const theme = MoonTheme.colors[mode];

    return (
        <View style={[
            styles.container,
            {
                backgroundColor: theme.surface,
                borderColor: theme.border,
            },
            style
        ]}>
            {icon && (
                <Ionicons
                    name={icon}
                    size={20}
                    color={theme.textMuted}
                    style={styles.icon}
                />
            )}
            <TextInput
                style={[
                    styles.input,
                    {
                        color: theme.textBody,
                        fontFamily: 'NotoSansDevanagari_400Regular'
                    }
                ]}
                placeholderTextColor={theme.textMuted}
                {...props}
            />
        </View>
    );
};

const styles = StyleSheet.create({
    container: {
        flexDirection: 'row',
        alignItems: 'center',
        borderRadius: MoonTheme.radius.round, // Pill shape
        borderWidth: 1,
        paddingHorizontal: 16,
        height: 56,
    },
    icon: {
        marginRight: 12,
    },
    input: {
        flex: 1,
        fontSize: 16,
        height: '100%',
    }
});
