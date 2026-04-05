# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A 4x9 free-placement four-in-a-row game (human vs random agent) built with **MATLAB + Psychtoolbox (PTB)**. Designed as an experimental framework with EEG/MEG marker support and trial-level behavioral logging. The game uses free placement (no gravity drop) on a 4-row by 9-column board.

## Running

In MATLAB (R2021+ with Psychtoolbox installed), set the working directory to the project root, then:
```matlab
app/run_game
```

## Testing

```matlab
tests/run_all_tests
```
Tests cover core game logic only (init, legal actions, win detection in all directions, draw, invalid moves). No PTB dependency for tests.

## Architecture

The codebase follows a strict layered design where core logic is fully decoupled from display:

- **`app/`** - Entry point and state machine. `run_game.m` bootstraps paths and config; `main_loop.m` drives the state machine (`wait_start` -> `in_game` -> `result` -> `cleanup`). `load_config.m` holds all hardcoded v1 settings.
- **`core/`** - Pure game logic (no PTB dependency). Board is a `4x9` matrix (`0`=empty, `1`=black, `2`=white). Actions are structs with `.row` and `.col` fields.
- **`players/`** - Unified player interface. Both `human_mouse_player_play.m` and `random_agent_play.m` return `[action, meta]`. Empty action + `meta.aborted` signals ESC exit; empty action + `meta.is_illegal` signals an illegal click.
- **`ui_ptb/`** - All Psychtoolbox rendering: screen management, board/piece drawing, button hit testing, dialog boxes. Visual layout is computed from viewing distance and visual angle (`cell_deg`).
- **`markers/`** - Event name to integer code mapping (`marker_name_to_code.m`) and unified emit interface (`emit_marker.m`). Default callback is `send_marker_stub` (console print); swap `config.marker.callback` for real EEG/MEG hardware.
- **`logging/`** - Trial-level `.mat` log files saved to `logs/`. Captures moves, illegal clicks, marker events, config, and screen parameters.
- **`utils/`** - Visual angle to pixel conversion (`deg2cm.m` -> `cm2px.m`) and display size validation.

## Key Conventions

- All configuration lives in `app/load_config.m` as hardcoded struct fields (no external config files).
- Timestamps use PTB's `Screen('Flip')` return for stimulus times and `GetSecs()` for response times.
- The `prompt.md` file is the authoritative technical specification for the project.
- If screen physical size is misdetected, set `config.display.use_manual_screen_size = true` in `load_config.m`.
