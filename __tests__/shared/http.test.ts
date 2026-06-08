import { describe, it, expect } from 'vitest';
import { parseExpectedStatus, matchesStatus } from '../../src/shared/http';

describe('parseExpectedStatus', () => {
  it('parses a single exact code', () => {
    expect(parseExpectedStatus('200')).toEqual({ codes: [200], ranges: [] });
  });

  it('parses a comma-separated list of codes', () => {
    expect(parseExpectedStatus('200,204')).toEqual({ codes: [200, 204], ranges: [] });
  });

  it('parses a range', () => {
    expect(parseExpectedStatus('300-399')).toEqual({ codes: [], ranges: [[300, 399]] });
  });

  it('parses a mix of codes and ranges and trims whitespace', () => {
    expect(parseExpectedStatus('200, 201, 300-399')).toEqual({
      codes: [200, 201],
      ranges: [[300, 399]],
    });
  });

  it('throws for an empty spec', () => {
    expect(() => parseExpectedStatus('')).toThrow();
    expect(() => parseExpectedStatus('  ')).toThrow();
  });

  it('throws for family shorthand like 2xx', () => {
    expect(() => parseExpectedStatus('2xx')).toThrow();
  });

  it('throws for non-numeric tokens', () => {
    expect(() => parseExpectedStatus('abc')).toThrow();
  });

  it('throws for inverted ranges', () => {
    expect(() => parseExpectedStatus('400-200')).toThrow();
  });
});

describe('matchesStatus', () => {
  it('matches an exact code', () => {
    expect(matchesStatus(200, '200')).toBe(true);
    expect(matchesStatus(201, '200')).toBe(false);
  });

  it('matches any code in a list', () => {
    expect(matchesStatus(204, '200,204')).toBe(true);
    expect(matchesStatus(202, '200,204')).toBe(false);
  });

  it('matches a code within a range, inclusive of boundaries', () => {
    expect(matchesStatus(300, '300-399')).toBe(true);
    expect(matchesStatus(399, '300-399')).toBe(true);
    expect(matchesStatus(350, '300-399')).toBe(true);
    expect(matchesStatus(400, '300-399')).toBe(false);
    expect(matchesStatus(299, '300-399')).toBe(false);
  });

  it('matches across a mix of codes and ranges', () => {
    expect(matchesStatus(201, '200,201,300-399')).toBe(true);
    expect(matchesStatus(301, '200,201,300-399')).toBe(true);
    expect(matchesStatus(250, '200,201,300-399')).toBe(false);
  });
});
