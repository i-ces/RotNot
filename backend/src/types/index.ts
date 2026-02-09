export interface ApiResponse<T = unknown> {
  success: boolean;
  message?: string;
  data?: T;
  error?: string;
}

export interface ErrorResponse {
  success: false;
  message: string;
  error?: string;
  stack?: string;
}
