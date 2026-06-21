---
description: Synthesize the previous assistant response to audio with controls (manual).
argument-hint: [stop]
allowed-tools: Bash
---

Turn the previous response into audio you can play with speed/seek/pause. No
copy-paste into a TTS app.

`/say` synthesizes the last assistant prose response with OpenAI TTS, writes it
to a stable mp3, and prints the play command. It does NOT auto-play: you launch
the player yourself so your keyboard drives speed, seek, and pause (a player
Claude launches in the background can take no key presses). `/say stop` clears
any stray playback.

Call the script FIRST, with no preamble text. (The script reads the last
*prose* assistant message from the transcript; any text you emit before the
tool call would become that message and get read instead of the intended
response.)

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/say-last-response.py" $ARGUMENTS
```

After it runs, report its stdout verbatim (it prints the ready-to-run play
command). If it exits non-zero, surface stderr verbatim (e.g. the no-key setup
line) and do not retry.

## Playing it (you run this in a terminal)

- Local / in the SSH session: `mpv ~/.config/claude-say/say-last.mp3`
- Local audio over an existing SSH session: `ssh <host> 'cat ~/.config/claude-say/say-last.mp3' | mpv -`
- Convenience helper: `say-play` (local) or `say-play --remote <host>` (pull + play locally)

mpv keys: `[` `]` speed | `<-`/`->` seek 5s | `up`/`down` 60s | `space` pause | `q` quit.
Needs `brew install mpv` (ffplay is a no-speed fallback if mpv is absent).

## Setup

OpenAI API key, read in this order:
1. `$OPENAI_API_KEY` environment variable
2. `~/.config/claude-say/openai-key` (a file containing just the key; `chmod 600`)

Optional env overrides: `CLAUDE_SAY_TTS_MODEL` (default `gpt-4o-mini-tts`),
`CLAUDE_SAY_TTS_VOICE` (default `alloy`), `CLAUDE_SAY_HOST` (default remote for
`say-play --remote`).
