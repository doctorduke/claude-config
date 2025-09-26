import React from 'react';
import { View as RNView, StyleSheet, ViewStyle } from 'react-native';

interface ViewProps {
  children: React.ReactNode;
  style?: ViewStyle;
}

export const View: React.FC<ViewProps> = ({ children, style }) => {
  return <RNView style={[styles.container, style]}>{children}</RNView>;
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});