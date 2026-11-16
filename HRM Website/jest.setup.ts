// Import jest-dom first to extend expect
import '@testing-library/jest-dom';

// Enable notifications feature flag for tests
process.env.NEXT_PUBLIC_ENABLE_NOTIFICATIONS = 'true';

// Mock matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: jest.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(),
    removeListener: jest.fn(),
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  })),
});

// Mock localStorage with proper jest mock functions
const localStorageMock = {
  getItem: jest.fn((key: string) => {
    if (key === 'act_hrm_access_token') return 'test-token';
    if (key === 'act_hrm_unread_count') return '0';
    return null;
  }),
  setItem: jest.fn(),
  removeItem: jest.fn(),
  clear: jest.fn(),
};
Object.defineProperty(window, 'localStorage', {
  value: localStorageMock,
  writable: true,
  configurable: true,
});

// Mock document.title
Object.defineProperty(document, 'title', {
  writable: true,
  value: 'ACT HRM',
});

// Mock favicon
const originalQuerySelector = document.querySelector.bind(document);
document.querySelector = jest.fn((selector: string) => {
  if (selector.includes("link[rel*='icon']")) {
    return { href: 'http://localhost/favicon.ico', remove: jest.fn() };
  }
  return originalQuerySelector(selector);
});

// Mock EventSource globally - use a controllable mock that works with fake timers
// Handlers are called synchronously for test triggers (tests wrap in act())
const createMockEventSource = () => {
  const listeners: Record<string, Function[]> = {};
  let isOpen = true; // Start as open - connection is established immediately
  return {
    addEventListener: jest.fn((event: string, handler: Function) => {
      if (!listeners[event]) listeners[event] = [];
      listeners[event].push(handler);
    }),
    removeEventListener: jest.fn((event: string, handler: Function) => {
      if (listeners[event]) {
        listeners[event] = listeners[event].filter(h => h !== handler);
      }
    }),
    close: jest.fn(() => {
      isOpen = false;
    }),
    dispatchEvent: jest.fn((event: Event) => {
      if (listeners[event.type]) {
        listeners[event.type].forEach(h => h(event));
      }
      return true;
    }),
    get onopen() {
      return listeners.open?.[0] || null;
    },
    set onopen(handler: Function | null) {
      if (!listeners.open) listeners.open = [];
      if (handler) listeners.open[0] = handler;
      // Connection is already open, call handler synchronously
      if (isOpen && handler) {
        handler(new Event('open'));
      }
    },
    get onerror() {
      return listeners.error?.[0] || null;
    },
    set onerror(handler: Function | null) {
      if (!listeners.error) listeners.error = [];
      if (handler) listeners.error[0] = handler;
    },
    get onmessage() {
      return listeners.message?.[0] || null;
    },
    set onmessage(handler: Function | null) {
      if (!listeners.message) listeners.message = [];
      if (handler) listeners.message[0] = handler;
    },
    readyState: 1,
    url: '',
    withCredentials: true,
    // Helper to trigger open - works with fake timers
    _triggerOpen: () => {
      isOpen = true;
      if (listeners.open) {
        listeners.open.forEach(h => h(new Event('open')));
      }
    },
    _triggerError: (error: Error) => {
      if (listeners.error) {
        listeners.error.forEach(h => h(error));
      }
    },
    _triggerMessage: (eventType: string, data: any) => {
      if (listeners[eventType]) {
        listeners[eventType].forEach(h => h({ data: JSON.stringify(data), type: eventType }));
      }
    },
  };
};

// Store reference to last created EventSource for test control
let lastMockEventSource: ReturnType<typeof createMockEventSource> | null = null;

global.EventSource = jest.fn().mockImplementation(() => {
  const mockEs = createMockEventSource();
  lastMockEventSource = mockEs;
  return mockEs;
}) as any;

// Export for tests to access the mock
(global as any).__lastMockEventSource = () => lastMockEventSource;

// Mock window.location
delete (window as any).location;
window.location = {
  ...window.location,
  href: 'http://localhost:3000/',
  origin: 'http://localhost:3000',
  protocol: 'http:',
  host: 'localhost:3000',
  hostname: 'localhost',
  port: '3000',
  pathname: '/',
  search: '',
  hash: '',
  assign: jest.fn(),
  replace: jest.fn(),
  reload: jest.fn(),
};

// Mock canvas for TabBadge favicon
const mockCanvasContext = {
  drawImage: jest.fn(),
  arc: jest.fn(),
  fill: jest.fn(),
  beginPath: jest.fn(),
  fillStyle: '',
  fillText: jest.fn(),
  font: '',
  textAlign: '',
  textBaseline: '',
  fillRect: jest.fn(),
  toDataURL: jest.fn().mockReturnValue('data:image/png;base64,test'),
};
HTMLCanvasElement.prototype.getContext = jest.fn().mockReturnValue(mockCanvasContext);

// Mock Image
global.Image = jest.fn().mockImplementation(() => ({
  onload: null,
  onerror: null,
  src: '',
})) as any;

// Default auth token is set in localStorageMock.getItem above