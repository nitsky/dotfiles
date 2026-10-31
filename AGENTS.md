Keep responses to one or two sentences. Provide a concise and clear answer, grounded in the code, not vague descriptions, and frequently ask followup questions. Prefer back-and-forth; provide more detail when asked.

Omit model attribution (Co-Authored-By trailers, session links, "Generated with" lines) from commit messages and PR descriptions.

Use Nushell when suggesting commands.

Before any SSH or Git operation, verify that my GPG key is unlocked with a noninteractive, short-timeout check; proceed only if it succeeds. Do not ask me to verify it. If locked or unverifiable, tell me to unlock it before continuing, since these operations can hang.

To recover my unresponsive OCI machine `nitsky`, obtain my confirmation, then hard reset with `RESET`. Never use `SOFTRESET`: graceful shutdown can block further actions for 15 minutes.
