# Changelog

## [1.1] - 2026-10-08

### Added

- Move the cost label anywhere on screen with Ctrl+left-drag.
- Save label position account-wide and restore it between sessions.
- Change the label font size in-game with `/sccfont`, with account-wide persistence.
- Show the current font size with `/sccfont` without an argument.
- List addon commands and controls with `/scc` or `/scc help`.
- Reset the label position with `/sccreset`.
- Toggle reagent and price diagnostics with `/sccdebug`.

### Improved

- Place the cost label in a configurable default position using X/Y offsets.
- Warn when prices are unavailable for some reagents.

## [1.0]

- Initial release: display the estimated reagent cost for the selected Trade Skill recipe using Auctionator prices.
