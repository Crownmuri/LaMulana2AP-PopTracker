# LaMulana2AP-PopTracker
A basic Poptracker pack (Items Only, Map Tracker, Entrance Tracker) for La-Mulana 2.

Big thanks to the La-Mulana 2 community: Coookie93 for their original [La-Mulana 2 Randomizer](https://github.com/Coookie93/LaMulana2Randomizer) of which the Archipelago port is derived, and their bundled [Item Tracker](https://github.com/Coookie93/LM2ItemTracker) has also been a huge help in designing this pack. Thank you Trishlanga for the maps. 

Supports auto-tracking through [Archipelago](https://archipelago.gg/) using [this apworld](https://github.com/Crownmuri/Archipelago/releases).

**Note**: In order to play La-Mulana 2 with AP tracking, you will require [this mod](https://github.com/Crownmuri/LaMulana2Archipelago).

## Features
- Items Only, Map Tracker and Entrance Tracker
- Settings: The following settings that may affect tracking are included:
  - Starting Location
  - Logic Difficulty (Normal / Tricky / Minimal)
  - Goal (Ninth Child / DLC / Glossary Hunt)
  - Oannesanity (DLC)
  - DLC item logic
  - Costume Clip logic
  - Remove Statue in IT
  - Require Life Sigil for HoM
  - Require Backside Warp Items
  - Auto Scan
  - Random Research
  - Random Dissonance
  - Costumesanity
  - Potsanity (9 options)
	- Specific coordinates only shown on individual maps
  - Glossanity (4 options)
	- Specific coordinates only shown on individual maps
	- Enemy Glossary is not 100% map specific so it has a tab of its own
  - Required GuardianKills
  - Required Crystal Skulls for Nibiru
  - Guardian Specific Ankh Jewels
	- When Guardian Specific Ankh Jewels is on, the item tracking for bosses is a progressive (0 - unobtained, 1 - ankh obtained, 2 - boss beaten)
	- Guardian Kills are automatically tracked through AP datapackage.
  - [Spoiler] Reveal Entrances (Entrance Randomizer)
  - Out-of-Logic visibility toggle
- Go Mode icon is enabled once the seed's goal is considered reachable.
- Additional Features:
  - Escape Sequence calculator
  - Reference Sheet (Mantra Combinations / Software Combinations / Eternal Prison Gates)
- Map Tracker Features:
  - Shop Memo table -- automatically shows which ammo are for purchase through AP datapackage.
- Entrance Tracker Features:
  - The Full Map has all the transitions mapped. I also mapped minibosses in the individual maps but they are internally already beaten in logic.
  - You can click an entrance (A) followed by clicking an exit (B) and they will become paired.
  - You can find the list of entrance pairs in the Settings popup menu.
  - You can also click transitions from this list. Right clicking the connected pair in this list will disconnect them.
  - You can cycle through the required souls (1, 2, 3, 5, 9) by clicking on the icon next to the Soul Gates.
- AP Connection: Click on AP, fill in the server/slotname/password and it will track obtained items and checked locations
- <Manual> For subweapons: right-click whenever you have located ammo for it. CanUse logic works when the subweapon is obtained and ammo is tracked
- <Manual> For the Pistol: Money Fairy needs to be manually tracked for it to be considered in CanUse logic. Key Fairy is also a manual tracked item

## Issues
- Placeholder images regarding minibosses
- Minibosses/puzzles/fairies are considered autocollected upon becoming reachable, so they are not mapped.
- Fairies/Minibosses are not tracked in AP so they don't auto-track.

## Installation / Launching guide:
1. This will require the Poptracker software to run. The website for it can be found [here](https://poptracker.github.io/) with the most current release found [here](https://github.com/black-sliver/PopTracker/releases). <br>
***Note:*** Once PopTracker is downloaded, it will have a `packs` folder that PopTracker packs are placed within. <br>
2. Download the [latest release](https://github.com/Crownmuri/LaMulana2AP-PopTracker/releases)
3. Place the downloaded `.zip` file into the packs folder in step 1.
4. Open your PopTracker application and click on the *Load Pack* button in the top left.
5. Choose your preferred tracker mode.


