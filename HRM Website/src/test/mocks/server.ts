// Mock MSW server - simplified for Jest compatibility
// We use jest.mock in test files instead of MSW for unit tests
export const server = {
  listen: jest.fn(),
  close: jest.fn(),
  use: jest.fn(),
  resetHandlers: jest.fn(),
};