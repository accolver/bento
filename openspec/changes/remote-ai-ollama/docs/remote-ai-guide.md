# Remote AI Guide

## Supported AI Providers

Bento detects and supports the following cloud AI providers via environment
variables on your remote host:

| Rank | Provider         | Env Variable(s)                      | API Format         | Default Model                      |
| ---- | ---------------- | ------------------------------------ | ------------------ | ---------------------------------- |
| 1    | Anthropic Claude | `ANTHROPIC_API_KEY`                  | Anthropic Messages | claude-sonnet-4-20250514           |
| 2    | OpenAI           | `OPENAI_API_KEY`                     | OpenAI-compatible  | gpt-4o                             |
| 3    | OpenRouter       | `OPENROUTER_API_KEY`                 | OpenAI-compatible  | anthropic/claude-sonnet-4-20250514 |
| 4    | Groq             | `GROQ_API_KEY`                       | OpenAI-compatible  | llama-3.3-70b-versatile            |
| 5    | Google Gemini    | `GOOGLE_API_KEY` or `GEMINI_API_KEY` | OpenAI-compatible  | gemini-2.0-flash                   |
| 6    | Mistral AI       | `MISTRAL_API_KEY`                    | OpenAI-compatible  | mistral-large-latest               |
| 7    | xAI (Grok)       | `XAI_API_KEY`                        | OpenAI-compatible  | grok-3                             |
| 8    | DeepSeek         | `DEEPSEEK_API_KEY`                   | OpenAI-compatible  | deepseek-chat                      |
| 9    | Fireworks AI     | `FIREWORKS_API_KEY`                  | OpenAI-compatible  | llama-v3p1-70b-instruct            |
| 10   | Together AI      | `TOGETHER_API_KEY`                   | OpenAI-compatible  | Llama-3.3-70B-Instruct-Turbo       |
| 11   | Cohere           | `COHERE_API_KEY`                     | OpenAI-compatible  | command-r-plus                     |

Additionally, **Ollama** is detected if running on `localhost:11434` on the
remote host. All installed models are enumerated via `/api/tags`.

---

## How Detection Works

When you connect to a remote host via SSH, Bento automatically runs two
detection probes **in parallel**:

### 1. Ollama Detection

Executes via SSH:

```bash
curl -s --connect-timeout 2 localhost:11434/api/tags
```

- If Ollama is running, the JSON response lists all installed models
- If not running or curl fails, Ollama is silently skipped
- 3-second timeout prevents connection delays

### 2. Environment Variable Detection

Executes via SSH:

```bash
test -n "$ANTHROPIC_API_KEY" && echo "ANTHROPIC_API_KEY"
test -n "$OPENAI_API_KEY" && echo "OPENAI_API_KEY"
# ... (all known env vars)
```

- Only checks **existence** of the variable, never reads the value
- If the direct shell doesn't find variables, Bento retries with:
  - `bash -l -c '...'` (login shell — loads `~/.bash_profile`)
  - `zsh -l -c '...'` (login shell — loads `~/.zprofile`)
  - `bash -li -c '...'` (interactive login — loads `~/.bashrc`)
  - `zsh -li -c '...'` (interactive login — loads `~/.zshrc`)
- Results are sorted by quality rank (Anthropic first)
- Duplicate providers are deduplicated (e.g., both `GOOGLE_API_KEY` and
  `GEMINI_API_KEY` count as one Google provider)

### What Bento Does NOT Do

- Does **not** read API key values
- Does **not** send any data to external services during detection
- Does **not** modify any files on the remote host
- Does **not** install anything on the remote host

---

## Security Model: Key-Opaque Architecture

Bento's remote AI feature is designed so that **API keys never leave the remote
machine** and are **never visible to Bento**:

1. **Detection**: Uses `test -n "$VAR"` — only checks if a variable is set,
   never reads its value.

2. **API Calls**: Curl commands use shell variable expansion in headers:
   ```bash
   curl -s https://api.anthropic.com/v1/messages \
     -H "x-api-key: $ANTHROPIC_API_KEY" \
     -d '...'
   ```
   The `$ANTHROPIC_API_KEY` is expanded by the remote shell at execution time.
   Bento only constructs the curl template; the actual key is resolved on the
   remote host.

3. **Response**: Bento only receives the AI-generated text response. No
   authentication tokens appear in the response body.

**FAQ: "Does Bento see my API keys?"** — No. Bento never reads, stores, or
transmits your API key values. The keys exist only in the remote host's
environment and are expanded by the remote shell when executing curl commands.
Bento sees only the command template (with `$VAR_NAME`) and the AI response.

---

## SSH & curl Requirements

### SSH Requirements

- Standard OpenSSH server with exec channel support (default on virtually all
  Linux/macOS servers)
- The SSH user must be able to execute commands (`curl`, `test`, `echo`)
- No special permissions or sudo access required

### curl Requirements

- `curl` must be installed on the remote host
- Must support `-s` (silent mode) and `-N` (no-buffer, for streaming)
- These flags are supported in curl 7.10+ (released 2003), so any modern system
  qualifies
- If curl is not found (exit code 127), Bento shows a clear error: "curl is not
  installed on the remote host"

### Ollama Requirements (optional)

- Ollama must be running and listening on `localhost:11434`
- The `/api/tags` endpoint must be accessible
- The `/v1/chat/completions` endpoint (OpenAI-compatible) must work
- No authentication is required (Ollama uses localhost-only by default)

---

## Setting Up Ollama on Your Server

1. Install Ollama:
   ```bash
   curl -fsSL https://ollama.com/install.sh | sh
   ```

2. Pull a model:
   ```bash
   ollama pull llama3:8b
   ```

3. Verify it's running:
   ```bash
   curl localhost:11434/api/tags
   ```

4. Connect from Bento — Ollama will be detected automatically.

### Recommended Models for Terminal Commands

| Model        | Size  | Speed | Quality | Best For             |
| ------------ | ----- | ----- | ------- | -------------------- |
| llama3:8b    | 4.7GB | Fast  | Good    | General commands     |
| codellama:7b | 3.8GB | Fast  | Good    | Code-focused tasks   |
| mistral:7b   | 4.1GB | Fast  | Good    | Balanced performance |
| llama3:70b   | 40GB  | Slow  | Best    | Complex tasks        |

---

## Troubleshooting

### "curl is not installed on the remote host"

Install curl:

- **Debian/Ubuntu**: `sudo apt install curl`
- **RHEL/CentOS**: `sudo yum install curl`
- **macOS**: curl is pre-installed
- **Alpine**: `apk add curl`

### "No AI providers found on remote host"

1. **Check env vars are set**: SSH in manually and run `echo $ANTHROPIC_API_KEY`
   (or whichever provider). If empty, the variable isn't set in your shell.

2. **Check which shell profile loads**: Env vars set in `~/.bashrc` may not load
   in non-interactive SSH sessions. Try adding them to `~/.bash_profile` or
   `~/.profile` instead.

3. **Verify with Bento's detection**: Bento tries multiple shell strategies
   (direct, bash login, zsh login). If the detection method shows "bashLogin" or
   "zshLogin", your vars are in a login-only profile.

4. **Restart your shell session**: After adding env vars, either log out and
   back in, or run `source ~/.bashrc`.

### "SSH connection lost. Reconnect to use remote AI."

This means the SSH connection dropped. Bento will automatically retry when the
connection is re-established. Common causes:

- Network interruption
- Server restart
- SSH session timeout (configure `ServerAliveInterval` in ssh config)

### Ollama not detected even though it's running

1. **Check Ollama is listening**: `curl -s localhost:11434/api/tags`
2. **Check the port**: Bento checks port 11434 by default. If Ollama uses a
   different port, it won't be detected automatically.
3. **Check Ollama has models**: If Ollama is running but has no models pulled,
   detection succeeds but there are no models to use. Run
   `ollama pull llama3:8b`.

### Rate limiting

If you see rate limit errors, the cloud provider is throttling requests. Bento
will show the retry-after duration when available. Wait and try again, or switch
to a different provider.
