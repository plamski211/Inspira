import { render } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { AppProvider } from './contexts/AppContext';
import { ThemeProvider } from './contexts/ThemeContext';
import App from './App';

const TestWrapper = ({ children }) => (
  <AppProvider>
    <ThemeProvider>
      {children}
    </ThemeProvider>
  </AppProvider>
);

describe('App Component', () => {
  it('renders without crashing', () => {
    render(
      <TestWrapper>
        <App />
      </TestWrapper>
    );
    expect(document.body).toBeDefined();
  });
}); 