import React from 'react';
import { Text as RNText, StyleSheet } from 'react-native';

interface TextProps {
  children: React.ReactNode;
  variant?: 'body' | 'heading' | 'caption';
}

export const Text: React.FC<TextProps> = ({ children, variant = 'body' }) => {
  return <RNText style={styles[variant]}>{children}</RNText>;
};

const styles = StyleSheet.create({
  body: {
    fontSize: 14,
    color: '#333',
  },
  heading: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#000',
  },
  caption: {
    fontSize: 12,
    color: '#666',
  },
});