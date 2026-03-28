# LaMulana2AP-PopTracker
A basic Poptracker pack (Items Only & Map Tracker) for La-Mulana 2.

Big thanks to the La-Mulana 2 community: Coookie93 for their original [La-Mulana 2 Randomizer](https://github.com/Coookie93/LaMulana2Randomizer) of which the Archipelago port is derived, and their bundled [Item Tracker](https://github.com/Coookie93/LM2ItemTracker) has also been a huge help in designing this pack. Thank you Trishlanga for the maps. 

Supports auto-tracking through [Archipelago](https://archipelago.gg/) using [this apworld](https://github.com/Crownmuri/Archipelago/releases).

**Note**: In order to play La-Mulana 2 with AP tracking, you will require to patch the original randomizer with [this additional mod](https://github.com/Crownmuri/LaMulana2Archipelago).

## Features
- Item Tracking
- Standard (no ER) map tracking.
- Settings: The following settings that may affect tracking are included:
  - Starting Location
  - Normal / Hard logic
  - Auto Scan
  - Remove Statue in IT
  - Require Life Sigil for HoM
  - Costume Clip logic
  - DLC item logic
  - Guardian Specific Ankh Jewels
  - Required GuardianKills
  - Required Crystal Skulls for Nibiru
- When Guardian Specific Ankh Jewels is on, the item tracking for bosses is a progressive (0 - unobtained, 1 - ankh obtained, 2 - boss beaten)
  - When it's off, the tracking is only between state 0 and state 2
  - Tracking a boss as beaten will automatically remove 1 Ankh Jewel from your tracked items
- Go Mode icon is enabled once Ninth Child is considered reachable.
- AP Connection: Click on AP, fill in the server/slotname/password and it will track obtained items and checked locations
- <Manual> For subweapons: right-click whenever you have located ammo for it. CanUse logic works when the subweapon is obtained and ammo is tracked
- <Manual> For the Pistol: Money Fairy needs to be manually tracked for it to be considered in CanUse logic. Key Fairy is also a manual tracked item

## Issues
- Only the Full map is mapped out for now
- A lot of stubbed images regarding minibosses and settings
- Minibosses/puzzles/fairies are considered autocollected upon becoming reachable
- Subweapon Ammo/Fairies/Minibosses/Guardians are not tracked in AP so they don't auto-track.
- Entrance Randomizer is not supported
- The map tracker may take a few seconds to update the more items you have collected

## Installation / Launching guide:
1. This will require the Poptracker software to run. The website for it can be found [here](https://poptracker.github.io/) with the most current release found [here](https://github.com/black-sliver/PopTracker/releases). <br>
***Note:*** Once PopTracker is downloaded, it will have a `packs` folder that PopTracker packs are placed within. <br> <br>
2. Download the [master zip](https://github.com/Crownmuri/LaMulana2AP-PopTracker/archive/refs/heads/master.zip)
3. Place the downloaded `.zip` file into the packs folder called in in step 1.
4. Open your PopTracker application and click on the *Load Pack* button in the top left.
5. Select either the Items Only mode or the Map Tracker mode.


