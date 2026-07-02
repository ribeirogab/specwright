# Verbatim evidence quotes

**Applies to:** any issue artifact that captures transcripts or command output as evidence (`evidence/`, `findings.md`, `learnings.md`).

Verbatim quotes are exempt from the English-only rule for authored artifacts. A captured transcript excerpt, command output, or session turn must be preserved byte-for-byte — translating or paraphrasing it falsifies the evidence the verdict depends on (e.g. a pt-BR reply from a driven session, an emoji inside a quoted turn, machine-local paths in captured output).

Rules:

- Quote verbatim inside fenced blocks or blockquotes, clearly framed as captured evidence (who said it, where it came from).
- All **authored** prose around the quotes — headers, analysis, verdicts, findings — stays in English.
- Never edit a quote after the run it records; if context is needed, add it outside the quote.
- A recording-convention header must not overclaim: label relayed summaries as `(relayed)` and only call `verbatim` what actually is.

Provenance: settled identically by four independent review lanes during the 2026-07-02 e2e-validation milestone.
