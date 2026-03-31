# jail-sh

<img src="logo.png" width="250" />

`jail-sh` starts a Bash shell with filesystem access restricted by Linux Landlock. You define named profiles that specify which directories the shell can read or write — everything else is blocked.

The main motivation: running LLM CLI tools (Claude Code, Gemini CLI, Aider, …) with their "trust me" / skip-permissions flags, but without actually trusting them with your whole filesystem. Give the agent access to your project directory and nothing else. 🤖

```bash
jail-sh llm claude --dangerously-skip-permissions
```

## 🤔 Why

Modern LLM CLIs are powerful — and they often ask you to disable their safety guardrails so they can read, write, and execute freely. That's fine for a controlled environment, but handing them unrestricted access to your home directory is not.

`jail-sh` lets you keep the `--dangerously-skip-permissions` workflow while enforcing real kernel-level boundaries:

- The agent can only see the directories you allow.
- Reads of `~/.ssh`, `~/.gnupg`, other projects, shell history, credentials files, etc. are blocked at the kernel level.
- No root required. No daemon. No container overhead.

## 📋 Requirements

- Linux kernel 5.13 or newer (Landlock support)
- `bash`
- a C compiler available as `cc`

## 📦 Install

System-wide:

```bash
sudo install -m 0755 jail-sh /usr/local/bin/jail-sh
```

Per-user (make sure `~/.local/bin` is in your `$PATH`):

```bash
install -d "$HOME/.local/bin"
install -m 0755 jail-sh "$HOME/.local/bin/jail-sh"
```

Or use `install.sh`, which defaults to `/usr/local` and respects a `PREFIX` override:

```bash
sudo bash install.sh
PREFIX=~/.local bash install.sh
```

## 🚀 Usage

Run an LLM CLI inside the sandbox (single command, exits when done):

```bash
jail-sh llm claude --dangerously-skip-permissions
jail-sh llm aider
jail-sh llm gemini
```

Start an interactive sandboxed shell using a profile:

```bash
jail-sh work
```

List all profiles defined in the config file:

```bash
jail-sh --list
```

## ⚙️ Config

The config file lives at `~/.config/jail-sh/config.ini` (or `$XDG_CONFIG_HOME/jail-sh/config.ini` if that variable is set). On first run, `jail-sh` creates the file and exits — edit it to add a profile, then run again.

Example config:

```ini
# Profile for running LLM CLI tools (Claude Code, Codex, …) on a project.
[llm]
start=$PWD
rw=$PWD

# Minimal /dev - specific devices only
rw=/dev/null
rw=/dev/zero
rw=/dev/urandom
rw=/dev/random
rw=/dev/tty
# /proc/self is a symlink; Landlock rules don't survive exec through it — use ro=/proc
ro=/proc
ro=/sys/devices/system/cpu

# Network/name resolution
ro=/etc/ssl
ro=/etc/ca-certificates
ro=/etc/resolv.conf
ro=/etc/hosts
ro=/etc/nsswitch.conf
ro=/etc/passwd
ro=/etc/group

# Claude / Codex
rw=~/.claude/
rw=~/.codex/
ro=~/.local/bin/claude
ro=~/.npm-global/
```

Profile keys:

| Key | Meaning |
|-----|---------|
| `start=DIR` | Working directory when the shell opens. Optional — defaults to the first `rw=` path. |
| `rw=PATH` | Allow read, write, and execute under `PATH`. Can be repeated. |
| `ro=PATH` | Allow read and execute under `PATH` (no writes). Can be repeated. |

Path values support `~`, `$HOME`, and `$PWD` (expanded at runtime).

## ⚠️ Limitations

- **Filesystem only.** Landlock restricts filesystem access. Network, process, IPC, and syscall access are unrestricted — a sandboxed process can still make outbound connections or signal other processes.
- **`/proc/self` is a symlink.** Landlock rules are applied before `exec`, so a rule for `/proc/self` resolves to the launcher's PID directory — not the child's. Use `ro=/proc` to cover the whole procfs.
- **No inter-process isolation.** A sandboxed process can still read from or write to file descriptors it inherits (stdin, stdout, stderr, and any others left open by the parent).
- **Root bypasses Landlock.** If the sandboxed process gains root (e.g. via a setuid binary it can execute), Landlock rules no longer apply.
- Probably more..

## 📝 Notes

- The Landlock helper is compiled on first run and cached under `~/.cache/jail-sh/`.
- A writable temp directory is created automatically at `~/.cache/jail-sh/tmp/<profile>/` and set as `$TMPDIR` inside the shell. Programs that write to `/tmp` will use this instead.
