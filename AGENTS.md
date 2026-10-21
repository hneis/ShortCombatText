# ShortCombatText Agent Rules

## Target

- Support only WoW Forever Beta `1.60.1.70338`, Interface `16001`, project
  `WOW_PROJECT_CAMELOT`.
- Runtime code must remain compatible with Lua 5.1.
- Verify unfamiliar APIs and global strings against the pinned Forever
  references in the parent workspace before using them.

## Scope

- Keep the addon dependency-free and deliberately small. Do not add settings,
  SavedVariables, libraries, or compatibility for other WoW clients unless the
  user explicitly requests them.
- `replacements` in `ShortCombatText.lua` is the source of truth for every
  global combat-text override.
- Replacement values must match the pinned enUS Blizzard global strings unless
  the user explicitly requests custom wording or capitalization.
- `messageReplacements` is reserved for localized dynamic combat messages that
  have no global string. Never compare or index a message before confirming it
  is not secret with `issecretvalue`.
- Preserve format placeholders such as `%s` and `%d` when changing replacement
  strings, including Blizzard grammar tokens such as `|4`. Blizzard code
  formats these globals at runtime.
- Reapplying replacements after startup events and short timer delays is
  intentional: Blizzard load-on-demand code can restore localized globals.
- Installing the message replacement wrapper on `_G.CombatText` after
  `Blizzard_CombatText` loads is intentional. XML copies mixin methods to the
  frame, so changing only `CombatTextMixin` later is insufficient.
- NiceDamage is compatible but optional. Do not add it as a dependency or
  duplicate its font configuration.
- Keep `ShortCombatText.toc` and `ShortCombatText_Camelot.toc` metadata and
  runtime file lists identical.
- Do not add post-Lua-5.1 syntax or process secret values in Lua.

## Validation

Run from the repository root:

```bash
./tools/validate.sh
lua5.1 tests/test_short_combat_text.lua
```

Static checks do not replace testing in the Forever client. In game, verify
combat outcomes, Riposte, threat transitions and both `/sctfix` and `/sctdebug`
after `/reload`.
