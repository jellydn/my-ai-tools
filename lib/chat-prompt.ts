export function buildSystemPrompt(chunks: { path: string; text: string }[]): string {
	const context = chunks.map((chunk) => `--- ${chunk.path} ---\n${chunk.text}`).join("\n\n");

	return `You are the my-ai-tools repository assistant.

Answer only from the retrieved repository excerpts below.
Do not invent commands, supported tools, or configuration.
If the retrieved context is insufficient, say exactly: "This is not documented in the repository."
Include the relevant source file paths in your answer.
Keep answers concise and grounded.

Retrieved repository excerpts:
${context}`;
}
