# Software Development Best Practices

## Philosophy

Code is communication between humans. Design for change, not perfection. Optimize for readability and simplicity.

See @~/.ai-tools/fable-guide.md for working with next-generation AI models.

## AI Tool Session Management

### Run Commands in tmux for Debuggability

Run long-running commands in tmux with directory-based session names for easy debugging and monitoring.

```bash
# Create session named after current directory (e.g., "my-project")
SESSION=$(basename "$PWD")
tmux new -d -s "$SESSION" 2>/dev/null || true

# Run dev server with portless if available, otherwise fallback to npm
if command -v portless &>/dev/null; then
    tmux send-keys -t "$SESSION" 'portless run npm run dev' Enter
else
    tmux send-keys -t "$SESSION" 'npm run dev' Enter
fi

# To check status later from another terminal:
tmux ls                          # list all sessions
tmux attach -t my-project        # attach to debug
tmux capture-pane -p -t my-project -S -100  # view last 100 lines without attaching
```

**Benefits:**

- Sessions survive terminal disconnects
- Stable `.localhost` URLs via portless (no port numbers to remember)
- Easy to reattach and debug from any terminal
- Capture output without interrupting the process
- Multiple users/agents can monitor the same session

**Best Practice:** For AI-assisted log analysis, pair with [LogPilot](https://github.com/jellydn/logpilot):

```bash
logpilot watch "$SESSION" --pane "$SESSION:0.0"
```

**Example package.json:**

```json
{
	"scripts": {
		"dev": "portless run next dev"
	}
}
```

---

## Core Principles

### Tidy First Philosophy

Make big changes through small, safe steps. Code is communication between humans, not just instructions for machines.

**Key practices**:
- Separate refactoring from feature work
- Remove complexity rather than managing it
- Balance current effort against future options
- Build for the next developer

### Code Quality Fundamentals

**Don't solve problems, eliminate them**: Look for ways to remove complexity entirely.

**Optimize for readability**: Clear code is maintainable code. Choose boring solutions that are easy to understand.

**Self-documenting**: Meaningful names and clear structure beat comments. Comments explain why, not what.

**Test for confidence**: Write tests that enable change, not tests that constrain it.

## 📦 Dependencies

### 🧠 Choose Libraries Wisely

When adding third-party dependencies:

- Select the most popular and actively maintained option
- Check the library's GitHub repository for:
  - Recent commits (within last 6 months)
  - Active issue resolution
  - Number of stars/downloads
  - Clear documentation

## 🧹 Tidying Practices

### ⏰ When to Tidy

**Before making a change**:

- Will tidying make the change easier? → Yes → Tidy first
- Will tidying take longer than the change? → No → Make change first, tidy after
- Is the change urgent? → Skip tidying for now, schedule for later

### 🔧 Core Tidying Techniques

#### 🛡️ Guard Clauses

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

#### 🗑️ Dead Code Elimination

Delete code that isn't executed or referenced.

#### ⚖️ Normalize Symmetries

Use consistent patterns throughout the codebase.

#### 🆘 Helper Variables and Functions

Extract complex expressions into well-named variables:

```javascript
// ❌ Complex expression
if (
	user.subscription.plan.tier === "premium" &&
	user.subscription.status === "active" &&
	user.subscription.expiresAt > new Date()
) {
	// logic
}

// ✅ Helper variable
const hasActivePremiumSubscription =
	user.subscription.plan.tier === "premium" &&
	user.subscription.status === "active" &&
	user.subscription.expiresAt > new Date();

if (hasActivePremiumSubscription) {
	// logic
}
```

## 🧪 Testing Strategy

### 🏆 The Testing Trophy Approach

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

### 📝 Testing Guidelines

#### 💪 Write Tests That Give Confidence

- Test behavior, not implementation details
- Focus on user-facing functionality
- Prefer integration tests over isolated unit tests

#### 🏗️ Test Structure

```javascript
// ✅ Clear test structure
test("should increment counter when button is clicked", () => {
	// Arrange
	render(<Counter />);
	const button = screen.getByRole("button", { name: /increment/i });
	const counter = screen.getByTestId("counter-value");

	// Act
	expect(counter).toHaveTextContent("0");
	fireEvent.click(button);

	// Assert
	expect(counter).toHaveTextContent("1");
});
```

#### 🙈 Avoid Testing Implementation Details

- Don't test internal state or private methods
- Test the component's public interface
- Mock at the network boundary, not internal functions

## ⚡ Performance Practices

### 📊 Optimize for the Right Metrics

- Focus on user-centric performance (loading, interaction)
- Measure before optimizing
- Avoid premature micro-optimizations

### 📈 Progressive Enhancement

- Build core functionality that works without JavaScript
- Enhance with client-side features
- Use lazy loading for non-critical resources

### 🚀 Performance Patterns

```javascript
// ✅ Lazy loading with Suspense
const HeavyComponent = lazy(() => import("./heavy-component"));

function App() {
	return (
		<Suspense fallback={<Skeleton />}>
			<HeavyComponent />
		</Suspense>
	);
}
```

## 🤝 Collaboration Practices

### 💬 Code as Communication

- Express intent clearly through naming and structure
- Document decisions, not implementation
- Consider the next developer who will read this code

### 🔍 Pull Request Guidelines

**For Authors**:

- Separate tidying commits from behavior changes
- Write clear commit messages
- Include context in PR descriptions

**For Reviewers**:

- Focus on correctness, simplicity, and maintainability
- Ask questions when unclear
- Praise good solutions

### ♻️ Continuous Improvement

- Reflect on decisions and learn from mistakes
- Share knowledge through documentation and mentoring
- Regularly refactor and clean up technical debt
