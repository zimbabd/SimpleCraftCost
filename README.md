# SimpleCraftCost

A lightweight World of Warcraft addon that estimates the material cost of the selected crafting recipe using Auctionator prices.

## Features

- Displays the estimated reagent cost in the Trade Skill window.
- Updates when a recipe is selected or the Trade Skill window changes.
- Lets you reposition the cost label with Ctrl+left-drag and saves its position account-wide.
- Lets you change the label font size in-game and saves the setting account-wide.
- Shows a partial-cost warning when one or more reagent prices are unavailable.
- Includes in-game command help and an optional debug mode.

## Requirements

- World of Warcraft 3.3.5a (Interface version `30300`).
- Auctionator for reagent buyout prices. Price availability depends on Auctionator's auction data and scan history.

## Installation

1. Copy the `SimpleCraftCost` folder into `World of Warcraft/Interface/AddOns/`.
2. Make sure the folder contains `SimpleCraftCost.toc` and `SimpleCraftCost.lua`.
3. Enable **SimpleCraftCost** and **Auctionator** on the character selection screen.
4. Log in and run an Auctionator auction scan so reagent prices are available.
5. Use `/reload` if the addon files were changed while the game was running.

## Positioning

Hold **Ctrl** and left-drag the cost label to move it anywhere on the screen. Its position is saved account-wide, so it is shared by characters on the same WoW account. The addon declares `SimpleCraftCostDB` as an account-level `SavedVariables` entry in its TOC file; WoW writes the saved data when the UI is saved, usually on logout or exit.

Enter `/sccreset` to clear the saved position and return the label to its default location. The default offsets are configured near the top of `SimpleCraftCost.lua`:

```lua
local COST_OFFSET_X = -210
local COST_OFFSET_Y = 70
```

The default position is anchored to the bottom-right corner of the Trade Skill window:

- Negative `COST_OFFSET_X` moves it left; positive moves it right.
- Positive `COST_OFFSET_Y` moves it up; negative moves it down.

Reload the UI with `/reload` after changing the default values. If a custom position has already been saved, use `/sccreset` to return to the new default.

## Font Size

Change the cost label text size in-game with `/sccfont 16` (replace `16` with a value from 8 to 32). The change applies immediately and is saved account-wide. Enter `/sccfont` without a number to display the current size.

The default font size can also be changed near the top of `SimpleCraftCost.lua`:

```lua
local COST_FONT_SIZE = 14
```

Use a larger number to increase the text size or a smaller number to reduce it, then run `/reload`.

## Commands

- `/scc help` or `/scc` - List all addon commands and controls.
- `/sccfont` - Show the current label font size.
- `/sccfont 8-32` - Set the font size immediately; the value is saved account-wide.
- `/sccdebug` - Toggle diagnostic output in chat.
- `/sccreset` - Clear the saved label position and return to the configured default position.

Hold **Ctrl** and left-drag the label to move it anywhere on screen. Its position is saved account-wide.

With debug enabled, select a recipe and check chat for its reagents, Auctionator price results, and calculated total. Enter `/sccdebug` again to turn debug output off.

## Lua Error Reporting

To show Lua errors in-game, run:

```text
/console scriptErrors 1
/reload
```

## Notes

The displayed amount is the estimated cost of the recipe's reagents. It does not calculate sale value, profit, auction house fees, or other costs. A missing Auctionator price is not treated as zero in the warning shown by the addon, though available reagent prices are still included in the displayed subtotal.
