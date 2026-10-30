I use nushell, so please use nushell when suggesting commands I should run.

Do not include attribution to any model (e.g. Co-Authored-By trailers, session links, or "Generated with" lines) in git commit messages or pull request descriptions.

When I ask for recovery of my unresponsive OCI machine `nitsky`, ask for my confirmation, then hard reset it using OCI's `RESET` action. Do not use `SOFTRESET`, since its graceful shutdown can block further actions for 15 minutes. Always obtain my confirmation before the hard reset.

Before attempting any SSH or Git operation, verify yourself that my GPG key is unlocked using a noninteractive check with a short timeout. Do not ask me to confirm its status. Proceed only after the check succeeds. If the key is locked or its status cannot be verified, tell me that it needs to be unlocked before continuing, because these operations can hang when the key is locked.
