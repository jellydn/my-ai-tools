Resumes work from a previous handoff session which are stored in `.claude/handoffs`.

The handoff folder might not exist if there are none.

Requested handoff file: `$ARGUMENTS`

## Process

### 1. Check handoff file

If no handoff file was provided, list them all.  Eg:

```bash
if [ ! -d ".claude/handoffs" ]; then
  echo "No handoffs directory found. No previous sessions to resume."
  exit 0
fi

echo "## Available Handoffs"
echo ""

found_files=false
for file in .claude/handoffs/*.md; do
  if [ -f "$file" ]; then
    found_files=true
    title=$(grep -m 1 "^# " "$file" | sed 's/^# //')
    basename=$(basename "$file")
    echo "* \`$basename\`: $title"
  fi
done

if [ "$found_files" = false ]; then
  echo "No handoff files found."
else
  echo ""
  echo "To pickup a handoff, use: /pickup <filename>"
fi
```

### 2. Read handoff file

If a handoff file was provided locate it in `.claude/handoffs` and read it.  Note that this file might be misspelled or the user might have only partially listed it.  If there are multiple matches, ask the user which one they want to continue with.  The file contains the instructions for how you should continue.

### 3. Resume working

After reading the handoff file:
1. Review and understand the context, especially sections 5 (Pending Tasks), 6 (Current Work), and 7 (Next Step)
2. If the Next Step is unclear or seems out of date, confirm with the user before proceeding
3. Begin working immediately on the Next Step outlined in the handoff
