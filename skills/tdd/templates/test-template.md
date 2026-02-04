import { describe, it, expect } from 'vitest'
import { functionName } from './module'

describe('functionName', () => {
  it('should return formatted output when given valid input', () => {
    // Arrange - Setup test scenario
    const input = 'test input'
    const expectedOutput = 'expected output'

    // Act - Execute the unit under test
    const result = functionName(input)

    // Assert - Verify expected outcome
    expect(result).toBe(expectedOutput)
  })
})
