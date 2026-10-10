import { Component, type ErrorInfo, type ReactNode } from 'react';

interface Props { children: ReactNode }
interface State { error: Error | null }

/**
 * Top-level error boundary. Without this, any throw during the first render
 * leaves `#root` empty and the page looks blank. This surfaces the real error
 * on screen (and logs it to the console) so failures are diagnosable.
 */
export class ErrorBoundary extends Component<Props, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: Error): State {
    return { error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    // eslint-disable-next-line no-console
    console.error('Application crashed during render:', error, info.componentStack);
  }

  render() {
    const { error } = this.state;
    if (!error) return this.props.children;

    return (
      <div
        role="alert"
        style={{
          fontFamily: 'system-ui, sans-serif',
          maxWidth: 760,
          margin: '48px auto',
          padding: '24px',
          border: '1px solid #e2e8f0',
          borderRadius: 12,
          background: '#fff',
          color: '#0f172a',
        }}
      >
        <h1 style={{ fontSize: 20, margin: '0 0 8px' }}>Something went wrong</h1>
        <p style={{ margin: '0 0 16px', color: '#475569' }}>
          The app failed to start. The error below is also printed in your browser
          console (press F12 → Console).
        </p>
        <pre
          style={{
            whiteSpace: 'pre-wrap',
            wordBreak: 'break-word',
            background: '#0f172a',
            color: '#f8fafc',
            padding: 16,
            borderRadius: 8,
            fontSize: 13,
            overflowX: 'auto',
          }}
        >
          {error.name}: {error.message}
          {error.stack ? `\n\n${error.stack}` : ''}
        </pre>
        <button
          type="button"
          onClick={() => window.location.reload()}
          style={{
            marginTop: 16,
            padding: '8px 16px',
            borderRadius: 8,
            border: '1px solid #cbd5e1',
            background: '#f8fafc',
            cursor: 'pointer',
          }}
        >
          Reload
        </button>
      </div>
    );
  }
}
