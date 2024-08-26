import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    root: 'src/dao/e2e-tests',
    testTimeout: 30_000,
  },
});