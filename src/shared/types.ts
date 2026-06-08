export interface ServiceCheckInputs {
  host: string;
  port: number;
  timeout: number;
  interval: number;
  waitIndefinitely: boolean;
  username?: string;
  password?: string;
  database?: string;
  scheme?: string;
  path?: string;
  method?: string;
  expectedStatus?: string;
}

export type CheckFunction = (inputs: ServiceCheckInputs) => Promise<void>;
