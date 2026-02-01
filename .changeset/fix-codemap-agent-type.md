---
"@fake-scope/fake-pkg": patch
---

Fix codemap skill to use general-purpose agents instead of explore agents. Explore agents are read-only and don't have write tool access, causing errors when trying to write documentation files. General-purpose agents have full tool access including write capabilities.
