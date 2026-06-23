# claude-say

A `/say` slash command for [Claude Code](https://claude.com/claude-code): read
Claude's last response aloud via OpenAI TTS, with real playback controls
(speed, seek, pause) and over-SSH playback. Manual trigger, no auto-play.

You run a long response past once, then listen to it instead of re-reading. No
copy-paste into a separate TTS app.

## Why it's built this way

- **No auto-play.** `/say` writes the audio to a stable file and prints the play
  command. You launch the player yourself so your keyboard owns it — a player
  Claude launches in the background can take no key presses, so you'd get no
  speed/seek/pause. The deliberate two-step is what buys you the controls.
- **Stable file path, not a tempfile.** Same path every time means over-SSH
  playback just works: pull `~/.config/claude-say/say-last.mp3` to a local
  machine and play it there.
- **Reads the *prior* prose response.** The script skips the tool-calling
  message of the current `/say` turn and reads the real answer before it.
- **Unknown args never cost money.** A typo or bad flag prints usage and exits
  before any paid API call (regression-tested in `scripts/test/`).

## Install

```
/plugin marketplace add assafkip/claude-say
/plugin install claude-say
```

Then set an OpenAI API key. Easiest is the setup script — run it **in your own
terminal** (not through Claude, so the key never enters a chat transcript). It
prompts with the input hidden, verifies the key against OpenAI's free
`/v1/models` endpoint, and writes it `chmod 600`:

```bash
bash scripts/say-setup.sh
# offline / skip the network check:
bash scripts/say-setup.sh --no-verify
```

The key is read in this order, so either of these also works:

1. `$OPENAI_API_KEY` environment variable, or
2. `~/.config/claude-say/openai-key` — a file containing just the key:

```bash
mkdir -p ~/.config/claude-say
printf '%s' 'sk-...' > ~/.config/claude-say/openai-key
chmod 600 ~/.config/claude-say/openai-key
```

For playback controls, install mpv (the only common player with live speed
control; ffplay is a no-speed fallback):

```bash
brew install mpv
```

## Use

After any Claude response:

```
/say            # synthesize the last response, print the play command
/say stop       # clear any stray playback
```

Then play it (you run this in your terminal so the keyboard drives it):

```bash
mpv ~/.config/claude-say/say-last.mp3
# or the helper:
scripts/say-play.sh
# from a local machine, over an existing SSH session:
scripts/say-play.sh --remote <ssh-host>
```

mpv keys: `[` `]` speed · `←`/`→` seek 5s · `↑`/`↓` 60s · `space` pause · `q` quit.

## Configuration

| Env var | Default | What it does |
|---|---|---|
| `OPENAI_API_KEY` | — | API key (preferred over the key file) |
| `CLAUDE_SAY_TTS_MODEL` | `gpt-4o-mini-tts` | OpenAI TTS model |
| `CLAUDE_SAY_TTS_VOICE` | `alloy` | TTS voice |
| `CLAUDE_SAY_HOST` | — | default host for `say-play --remote` |

## Test

No network, key, or audio device needed. The arg guard runs before any
synthesis; the setup test runs against a throwaway `$HOME` so it never touches a
real key file:

```bash
bash scripts/test/test-say-args.sh    # unknown args never cost money
bash scripts/test/test-say-setup.sh   # key stored 600, no network, env wins
```

## License

MIT


---

## Built by Assaf

I spent 12 years in threat intelligence watching teams find the same failure and fix it four times. The learning never stuck. I build tools that make it stick.

This is the free version. The paid kits live at [claudedaddy.io](https://claudedaddy.io).

**Want this wired into your team's repo, or a heavier spec-and-review pipeline?** That's the consulting. [Book a call.](https://calendar.app.google/cMFvhvDsfi9iyWYy9)
