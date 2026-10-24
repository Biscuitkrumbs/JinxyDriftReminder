# Jinxy Drift Reminder

Click the pink-ponytail minimap icon to open or close settings and previews.
Drag it around the minimap to reposition it; the position is saved. Hover to
see enabled status and Touch/Soul wording choices. `/jinxydrift` opens the same
menu; `/jinxytouch` remains supported.

The folder remains `JinxyTouchCountdown` to preserve existing installations,
sound paths and saved settings. Install this as an update to that folder,
not as a second addon alongside it.

Companion addon for WoW 12.1.5 (120105), independent of Ellesmere and the coach.

Default cues:
- "Touch in" at 5 seconds before expected readiness, then 3, 2, 1.
- "Soul in" at 5 seconds before expected Soul entry, then 3, 2, 1.

Touch is estimated at 45 seconds after a successful Touch cast (321507).
Soul is estimated at 17.4 seconds after successful Surge (365350), based on
this character's supplied logs, where Surge gain to Soul gain was about 17.4s.
This is not a live aura-expiration reader. Talent/build changes, cooldown resets,
or duration changes can invalidate estimates. Confirm against the in-game buffs.

Install this entire folder in `_retail_/Interface/AddOns/`. Restart WoW for a
first install; `/reload` loads updates to an already discovered addon.

Commands:
- `/jinxytouch`: open the draggable voice menu (Escape closes it).
- Choose Short ("Touch in") or Long ("Touch of the Magi in") in the menu;
  wording and menu position persist between sessions. Both keep the same number timing.
- `/jinxytouch short` or `/jinxytouch long`: change Touch wording directly.
- Soul has its own saved Short ("Soul in") / Long ("Arcane Soul in" + "Burn")
  choice in the menu, or `/jinxytouch soul short` / `/jinxytouch soul long`.
  Long Soul says "Burn" at the configured estimated Soul start, not a measured
  aura gain; it is a timing reminder, not a verified rotation recommendation.
- `/jinxytouch test`: preview Touch wording and countdown.
- `/jinxytouch test soul`: preview Soul wording and countdown.
- `/jinxytouch 3` or `/jinxytouch 5`: choose number countdown length.
- `/jinxytouch soul 17.4`: configure estimated Surge-to-Soul seconds (10 to 30).
- `/jinxytouch off` or `/jinxytouch on`: saved enable preference.
- `/jinxytouch stop`: cancel current reminders (use after training resets).

New Touch and Surge casts replace only their own timers. Death, loading,
reload, and most setting changes cancel pending reminders. Tracking restarts
on the next relevant cast. Sounds use Master and respect WoW sound settings.
The Touch/Soul labels and numbers 3, 2, 1 use the user-supplied ElevenLabs
Brittney recordings (2026-10-24), split into separate PCM WAV clips so the
addon controls countdown timing. Labels are shorter than the two-second gap
before the first number. Optional numbers 5 and 4 still use the original local
speech voice; the default three-second countdown uses Brittney throughout.
Long Touch wording uses the supplied 07:12:25 Brittney recording, trimmed to
the label only. Its 2.01-second label starts 2.25 seconds before the first number.
Long Soul uses the supplied 07:11:38 Brittney recording, split into the label
and "Burn". Both wording options share the existing separately timed 3/2/1 clips.
Existing short/long Touch choices are preserved; Soul defaults to short.
In-game timing/audio must be checked
in WoW; offline source and audio checks do not establish live compatibility.

## Audio credits

Voice audio generated with [ElevenLabs](https://elevenlabs.io), using Brittney
(Social Media Voice - Fun, Youthful & Informative). Voice assets are not offered
under an open-source code license. Confirm the applicable generation-plan rights
before public redistribution or monetization; free-plan output requires attribution
and is restricted to non-commercial use.

## Distribution

The install ZIP must contain a single `JinxyTouchCountdown/` folder, including
`JinxyTouchCountdown.toc`, both Lua files, `Sounds/` and `Media/JinxyIcon.tga`.
The original high-resolution `Media/JinxyIconSource.png` is source artwork and
can be omitted from the install ZIP. Do not package character settings or logs.
