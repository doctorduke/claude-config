export { loadNodeEnv } from './env';

export const config = {
  api: {
    baseUrl: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001',
    timeout: 30000,
  },
  app: {
    name: 'Umemee',
    version: '0.0.1',
  },
  features: {
    enablePWA: true,
    enableOffline: false,
  },
};
