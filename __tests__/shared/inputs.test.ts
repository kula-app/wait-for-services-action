import { vi, describe, it, expect, beforeEach } from 'vitest';
import * as core from '@actions/core';
import { parseInputs } from '../../src/shared/inputs';

vi.mock('@actions/core');

const mockedCore = vi.mocked(core);

describe('parseInputs', () => {
  beforeEach(() => {
    mockedCore.getInput.mockImplementation((name: string) => {
      switch (name) {
        case 'host':
          return 'localhost';
        case 'port':
          return '5432';
        case 'timeout':
          return '30';
        case 'interval':
          return '2';
        case 'wait-indefinitely':
          return 'false';
        case 'username':
          return 'user';
        case 'password':
          return 'pass';
        case 'database':
          return 'mydb';
        default:
          return '';
      }
    });
  });

  it('should parse all inputs correctly', () => {
    const inputs = parseInputs();

    expect(inputs.host).toBe('localhost');
    expect(inputs.port).toBe(5432);
    expect(inputs.timeout).toBe(30);
    expect(inputs.interval).toBe(2);
    expect(inputs.waitIndefinitely).toBe(false);
    expect(inputs.username).toBe('user');
    expect(inputs.password).toBe('pass');
    expect(inputs.database).toBe('mydb');
  });

  it('should use defaults for optional inputs', () => {
    mockedCore.getInput.mockImplementation((name: string) => {
      switch (name) {
        case 'host':
          return 'localhost';
        case 'port':
          return '27017';
        default:
          return '';
      }
    });

    const inputs = parseInputs();

    expect(inputs.timeout).toBe(20);
    expect(inputs.interval).toBe(1);
    expect(inputs.waitIndefinitely).toBe(false);
    expect(inputs.username).toBeUndefined();
    expect(inputs.password).toBeUndefined();
    expect(inputs.database).toBeUndefined();
  });

  it('should parse wait-indefinitely as true', () => {
    mockedCore.getInput.mockImplementation((name: string) => {
      switch (name) {
        case 'host':
          return 'localhost';
        case 'port':
          return '6379';
        case 'wait-indefinitely':
          return 'true';
        default:
          return '';
      }
    });

    const inputs = parseInputs();
    expect(inputs.waitIndefinitely).toBe(true);
  });

  it('should throw on invalid port', () => {
    mockedCore.getInput.mockImplementation((name: string) => {
      switch (name) {
        case 'host':
          return 'localhost';
        case 'port':
          return 'abc';
        default:
          return '';
      }
    });

    expect(() => parseInputs()).toThrow('Invalid port value');
  });

  it('should throw on invalid timeout', () => {
    mockedCore.getInput.mockImplementation((name: string) => {
      switch (name) {
        case 'host':
          return 'localhost';
        case 'port':
          return '5432';
        case 'timeout':
          return 'abc';
        default:
          return '';
      }
    });

    expect(() => parseInputs()).toThrow('Invalid timeout value');
  });
});
