import React from 'react';

interface TextProps {
  children: React.ReactNode;
  variant?: 'body' | 'heading' | 'caption';
  className?: string;
}

export const Text: React.FC<TextProps> = ({
  children,
  variant = 'body',
  className = ''
}) => {
  const variantClasses = {
    body: 'text-base text-gray-700',
    heading: 'text-2xl font-bold text-gray-900',
    caption: 'text-sm text-gray-500'
  };

  return (
    <p className={`${variantClasses[variant]} ${className}`}>
      {children}
    </p>
  );
};