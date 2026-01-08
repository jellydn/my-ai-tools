# Software Development Best Practices

## Context

Comprehensive development guidelines for Agent OS projects, based on Kent Beck's "Tidy First?" principles and Kent C. Dodds' programming wisdom.

> "Software design is an exercise in human relationships" - Kent Beck

<conditional-block context-check="core-principles">
IF this Core Principles section already read in current context:
  SKIP: Re-reading this section
  NOTE: "Using Core Principles already in context"
ELSE:
  READ: The following principles

## Core Principles

### Tidy First Philosophy
- **Small, Safe Steps**: Make big changes through small, reversible steps
- **Human Relationships**: Code is communication between humans
- **Economic Thinking**: Balance current effort against future options
- **Eliminate Problems**: Remove complexity rather than managing it

### Code Quality Fundamentals
- **Don't Solve Problems, Eliminate Them**: Look for ways to reduce complexity
- **Optimize for Readability**: Prioritize code clarity over clever solutions
- **Self-Documenting Code**: Use meaningful names and clear structure
- **Test for Confidence**: Write tests that give confidence to change

### Change-Friendly Design
- **Separate Tidying from Behavior Changes**: Keep refactoring separate from new features
- **Build for the Next Developer**: Consider maintainability and understanding
- **Options Over Things**: Create flexibility for uncertain future requirements
- **Progressive Enhancement**: Start simple, add complexity when needed
</conditional-block>

<conditional-block context-check="dependencies" task-condition="choosing-external-library">
IF current task involves choosing an external library:
  IF Dependencies section already read in current context:
    SKIP: Re-reading this section
    NOTE: "Using Dependencies guidelines already in context"
  ELSE:
    READ: The following guidelines
ELSE:
  SKIP: Dependencies section not relevant to current task

## Dependencies

### Choose Libraries Wisely
When adding third-party dependencies:
- Select the most popular and actively maintained option
- Check the library's GitHub repository for:
  - Recent commits (within last 6 months)
  - Active issue resolution
  - Number of stars/downloads
  - Clear documentation
</conditional-block>

<conditional-block context-check="tidying-practices" task-condition="refactoring-or-improving-code">
IF current task involves refactoring or improving existing code:
  IF Tidying Practices section already read in current context:
    SKIP: Re-reading this section
    NOTE: "Using Tidying Practices already in context"
  ELSE:
    READ: The following tidying practices
ELSE:
  SKIP: Tidying practices not relevant to current task

## Tidying Practices

### When to Tidy
**Before making a change**:
- Will tidying make the change easier? → Yes → Tidy first
- Will tidying take longer than the change? → No → Make change first, tidy after
- Is the change urgent? → Skip tidying for now, schedule for later

### Core Tidying Techniques

#### Guard Clauses
Move preconditions to the top and return early:
```javascript
// ❌ Nested conditions
function processUser(user) {
  if (user) {
    if (user.isActive) {
      if (user.hasPermission) {
        // main logic
      }
    }
  }
}

// ✅ Guard clauses
function processUser(user) {
  if (!user) return;
  if (!user.isActive) return;
  if (!user.hasPermission) return;
  
  // main logic
}
```

#### Dead Code Elimination
Delete code that isn't executed or referenced.

#### Normalize Symmetries
Use consistent patterns throughout the codebase.

#### Helper Variables and Functions
Extract complex expressions into well-named variables:
```javascript
// ❌ Complex expression
if (user.subscription.plan.tier === 'premium' && 
    user.subscription.status === 'active' && 
    user.subscription.expiresAt > new Date()) {
  // logic
}

// ✅ Helper variable
const hasActivePremiumSubscription = 
  user.subscription.plan.tier === 'premium' && 
  user.subscription.status === 'active' && 
  user.subscription.expiresAt > new Date();

if (hasActivePremiumSubscription) {
  // logic
}
```
</conditional-block>

<conditional-block context-check="testing-strategy" task-condition="writing-tests">
IF current task involves writing or updating tests:
  IF Testing Strategy section already read in current context:
    SKIP: Re-reading this section
    NOTE: "Using Testing Strategy already in context"
  ELSE:
    READ: The following testing guidelines
ELSE:
  SKIP: Testing strategy not relevant to current task

## Testing Strategy

### The Testing Trophy Approach
Based on Kent C. Dodds' testing philosophy:

```
    🏆 End-to-End (E2E)
      ↑ High confidence, slow, expensive
   🥉 Integration Tests  
      ↑ Good confidence, moderate speed
  🥈 Unit Tests
      ↑ Low confidence, fast, cheap
 🏅 Static Analysis
```

### Testing Guidelines

#### Write Tests That Give Confidence
- Test behavior, not implementation details
- Focus on user-facing functionality
- Prefer integration tests over isolated unit tests

#### Test Structure
```javascript
// ✅ Clear test structure
test('should increment counter when button is clicked', () => {
  // Arrange
  render(<Counter />);
  const button = screen.getByRole('button', { name: /increment/i });
  const counter = screen.getByTestId('counter-value');
  
  // Act
  expect(counter).toHaveTextContent('0');
  fireEvent.click(button);
  
  // Assert
  expect(counter).toHaveTextContent('1');
});
```

#### Avoid Testing Implementation Details
- Don't test internal state or private methods
- Test the component's public interface
- Mock at the network boundary, not internal functions
</conditional-block>

<conditional-block context-check="performance-practices" task-condition="performance-optimization">
IF current task involves performance optimization:
  IF Performance Practices section already read in current context:
    SKIP: Re-reading this section
    NOTE: "Using Performance Practices already in context"
  ELSE:
    READ: The following performance guidelines
ELSE:
  SKIP: Performance practices not relevant to current task

## Performance Practices

### Optimize for the Right Metrics
- Focus on user-centric performance (loading, interaction)
- Measure before optimizing
- Avoid premature micro-optimizations

### Progressive Enhancement
- Build core functionality that works without JavaScript
- Enhance with client-side features
- Use lazy loading for non-critical resources

### Performance Patterns
```javascript
// ✅ Lazy loading with Suspense
const HeavyComponent = lazy(() => import('./heavy-component'));

function App() {
  return (
    <Suspense fallback={<Skeleton />}>
      <HeavyComponent />
    </Suspense>
  );
}
```
</conditional-block>

<conditional-block context-check="collaboration-practices" task-condition="code-review-or-teamwork">
IF current task involves code reviews or team collaboration:
  IF Collaboration Practices section already read in current context:
    SKIP: Re-reading this section
    NOTE: "Using Collaboration Practices already in context"
  ELSE:
    READ: The following collaboration guidelines
ELSE:
  SKIP: Collaboration practices not relevant to current task

## Collaboration Practices

### Code as Communication
- Express intent clearly through naming and structure
- Document decisions, not implementation
- Consider the next developer who will read this code

### Pull Request Guidelines
**For Authors**:
- Separate tidying commits from behavior changes
- Write clear commit messages
- Include context in PR descriptions

**For Reviewers**:
- Focus on correctness, simplicity, and maintainability
- Ask questions when unclear
- Praise good solutions

### Continuous Improvement
- Reflect on decisions and learn from mistakes
- Share knowledge through documentation and mentoring
- Regularly refactor and clean up technical debt
</conditional-block>
