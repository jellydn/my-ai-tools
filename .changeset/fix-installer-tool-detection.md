---
"my-ai-tools": patch
---

Tidy up global-tool and plugin install feedback: install Go via mise for
`gofmt` (matching the other formatters instead of only printing manual
instructions), omit the empty `()` when a tool's version cannot be detected in
the already-installed message, and skip community plugins whose CLI tool is not
installed with a clear reason instead of reporting a misleading install failure.
