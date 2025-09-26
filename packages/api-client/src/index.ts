import { config } from '@umemee/config';
import type { ApiResponse, User } from '@umemee/types';

class ApiClient {
  private baseUrl: string;

  constructor() {
    this.baseUrl = config.api.baseUrl;
  }

  async fetch<T>(endpoint: string, options?: RequestInit): Promise<ApiResponse<T>> {
    try {
      const response = await fetch(`${this.baseUrl}${endpoint}`, {
        ...options,
        headers: {
          'Content-Type': 'application/json',
          ...options?.headers,
        },
      });

      const data = await response.json() as T;
      return {
        data,
        status: response.status,
      };
    } catch (error) {
      return {
        error: error instanceof Error ? error.message : 'Unknown error',
        status: 500,
      };
    }
  }

  async getUser(id: string): Promise<ApiResponse<User>> {
    return this.fetch<User>(`/users/${id}`);
  }
}

export const apiClient = new ApiClient();
export { ApiClient };