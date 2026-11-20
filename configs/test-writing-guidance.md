## Test-writing guidance

- Do not write tests for functions or code with cognitive complexity less than or equal to 5, unless they contain regular expressions. Measure it with [`github.com/moznion/cccc`](https://github.com/moznion/cccc) in the languages it supports. cccc does not analyze shell or Bats; for that code, estimate it by hand (+1 for each `if`, `case`, loop, and `&&`/`||` sequence, plus 1 for each nesting level), and write the test when unsure.
