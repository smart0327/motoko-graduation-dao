import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    root: 'src/dao/tests',
    globalSetup: './global-setup.ts',
    testTimeout: 30_000,
  },
});