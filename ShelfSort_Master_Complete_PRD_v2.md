📋 PRODUCT REQUIREMENTS DOCUMENT (PRD)
ShelfSort Master — 3D Goods Sorting Puzzle Game
Version: 1.0 | Date: July 26, 2026 | Platform: Android (Google Play Store)
TABLE OF CONTENTS
Executive Summary
Problem Statement & Competitive Gap
Product Vision & Goals
Target Audience
Core Game Concept
Game Mechanics (Detailed)
Level & Progression System
Theme Rooms
UI/UX Requirements
Screen-by-Screen Layout
Art Direction & Visual Style
Sound & ASMR Design
Monetization Strategy
Functional Requirements
Non-Functional Requirements
Player Retention Systems
Technical Specifications
Data & Analytics
Out of Scope (v1.0)
Glossary
1. EXECUTIVE SUMMARY
ShelfSort Master is a 3D casual puzzle game for Android where players sort colorful household objects (mugs, cups, jars, books, toys, etc.) onto shelves by matching color and type. The game targets the fast-growing "sort puzzle" subgenre — the hottest new category in mobile gaming in 2026, with top competitors achieving 10M–100M+ downloads.

This PRD defines a version that directly overcomes the top complaints players have against existing competitors (Sort Mania, Goods Sort, Goods Puzzle, Water Sort), making ShelfSort Master stand out through:

Fair monetization (no aggressive paywalls)
Theme-based progression (fresh environments every 25 levels)
Proper difficulty curve (rewarding challenge, not flat boredom)
Stable, polished build (no crashes)
ASMR-grade sound design
Light narrative ("Help Mia open her dream store")
2. PROBLEM STATEMENT & COMPETITIVE GAP
What Competitors Do Wrong (Validated by Player Reviews):
Problem	Impact on Players
Forced unskippable ads every 2–3 levels	Players quit within first 10 levels
Essential tools (shuffles, hints) locked behind hard paywall	Frustration, 1-star reviews
Flat difficulty — too easy for 100+ levels	Boredom, uninstalls
Same item types across all levels (no novelty)	"Gets repetitive quickly" — #1 complaint
Crashes mid-level = lost progress	Rage uninstalls
Seasonal themes not updated (Christmas in March)	Feels abandoned
No narrative/story hook	No emotional connection
Poor onboarding	Confusion, early drop-off
How ShelfSort Master Solves Each:
Problem	Our Solution
Forced ads	Rewarded ads ONLY — player triggers them voluntarily for bonuses
Locked tools	3 hints + 2 shuffles FREE per day; earn more by watching optional ads
Flat difficulty	Adaptive difficulty curve — Hard level every 5th, Boss level every 25th
Same items	New "Theme Room" every 25 levels with fresh items (10 unique themes at launch)
Crashes	Rigorous QA, local save every 2 seconds, instant crash recovery
Stale seasonal content	Auto-rotating seasonal themes tied to device calendar
No narrative	"Mia's Store" light storyline — players help Mia open and grow her dream shop
Poor onboarding	5-step interactive tutorial with animated coach
3. PRODUCT VISION & GOALS
Vision Statement:
"The most satisfying, fair, and visually beautiful shelf-sorting game on Android — where every level feels fresh and every player feels respected."

Business Goals (Year 1):
1,000,000+ downloads in first 6 months
4.7+ average Play Store rating
Day-1 retention: 50%+
Day-7 retention: 25%+
Day-30 retention: 12%+
ARPDAU (Average Revenue per Daily Active User): $0.08+
Top 50 in "Puzzle Games" on Play Store (US, UK, India, Pakistan)
Design Principles:
Respect the Player — Never block progress with a paywall
Fresh Every Session — New visual theme feels new even at level 200
Satisfying Over Stressful — Relaxation is the product
Sound is Gameplay — ASMR clicks and placements are core to the experience
Honest Ads — Ads shown are exactly what players will find in the game
4. TARGET AUDIENCE
Primary Audience:
Age: 18–45
Gender: Primarily female (65%), male (35%)
Location: Global — Top markets: India, Pakistan, USA, Brazil, Indonesia, Philippines
Device: Mid-range Android (2GB+ RAM), screen size 5.5"–6.7"
Play session: 5–20 minutes during commute, lunch break, before sleep
Motivation: Stress relief, visual satisfaction, sense of accomplishment
Secondary Audience:
Age: 45–65 (casual mobile gamers, non-competitive)
Kids 10–16 (visual + puzzle appeal)
Player Persona — "Ayesha":
Ayesha is a 28-year-old working professional. After a long day, she picks up her phone and plays a casual game for 10–15 minutes before sleep. She loves organizing things — her real wardrobe is color-coded. She wants a game that is visually beautiful, satisfying to play, doesn't ask her for money every 2 minutes, and makes her feel smart when she clears a tough level. She will NOT tolerate ads she didn't ask for.

5. CORE GAME CONCEPT
The Premise:
"Mia's Magical Store" — Mia (the player's character) is opening a dream store. Each world is a different section of the store (Kitchen, Bakery, Library, etc.). Players sort and organize the goods on the shelves to help Mia get each section ready for opening day. When a section is complete (25 levels), a short animated celebration plays and the next store section unlocks.

Core Loop:
Enter Level
    ↓
See cluttered shelf with mixed colored goods
    ↓
Tap a good → it floats in hand
    ↓
Tap an empty slot on the correct shelf
    ↓
Good snaps into place with satisfying ASMR sound
    ↓
Complete shelf = items glow + sparkle animation
    ↓
Clear all shelves = Level Complete screen
    ↓
Stars awarded (1–3) based on moves used
    ↓
Progress bar fills → next level unlocks
    ↓
Every 25 levels: New Theme Room celebration

Win Condition:
All items placed on matching shelves (same color + same type grouped)
No time limit (relaxed mode)
Stars depend on number of moves used (3-star = optimal, 2-star = acceptable, 1-star = just cleared)
Fail Condition:
No fail state — players can always use Shuffle or Undo to continue
If truly stuck: "Reset Level" option (costs no currency)
6. GAME MECHANICS (DETAILED)
6.1 Board Layout
Shelf Grid: 3–6 shelves per level, each shelf has 4–8 slots
Items per Level:
Levels 1–10: 3 colors, 2 item types, 12–18 items
Levels 11–25: 4 colors, 3 item types, 20–28 items
Levels 26–50: 5 colors, 4 item types, 28–36 items
Levels 51+: 6 colors, 5 item types, 36–50 items
Items start mixed across all shelves in random positions
6.2 Player Interaction
Tap to Pick Up: Tap any item → it lifts out with a smooth float animation (0.2s ease-out)
Tap to Place: Tap a valid empty slot → item moves to shelf with snap + click sound
Invalid Move Feedback: Item shakes + red flash (0.15s) + soft "thud" sound
Long Press: Show item info (color name, type name) — accessibility feature
Swipe to Scroll: If shelves exceed screen height, scroll vertically
Double-tap item in hand: Returns it to original position (Undo pick-up)
6.3 Power-Up Tools (UI Buttons on Game Screen)
Tool	Icon	Description	Free Daily	Earn More
Undo	↩️ arrow	Reverse last move	Unlimited	—
Hint	💡 lightbulb	Highlights the best next move	3/day	Watch ad = +1
Shuffle	🔀 arrows	Randomly re-sorts all items	2/day	Watch ad = +1
Auto-Sort	✨ wand	Auto-completes 3 correct moves	1/day	Watch ad = +1
Extra Shelf	➕ shelf	Adds 1 temporary holding shelf	1/day	Watch ad = +1
Design Rule: Tools are NEVER blocked by a paywall. Players can always earn them free via ads or daily reset. Premium purchase = "remove ads + get 2x daily tools."

6.4 Difficulty Curve Design
Level Type       Frequency    Description
──────────────────────────────────────────
Easy             Levels 1–5   Tutorial feel, 3 colors max
Standard         Every 2nd    Normal challenge
Hard             Every 5th    Tight board, limited holds
Tricky           Every 10th   Items have similar shades
Boss             Every 25th   Large board, 6 colors, 2x items
Rest             After boss   Easy "celebration" level

6.5 Matching Rules
Color Match: Items of the same color go on the same shelf
Type Grouping (Optional Bonus): If same color AND same type grouped = "Perfect Placement" bonus (extra stars, satisfying animation)
Mixed is OK: Same color but different type = valid, but not "Perfect"
6.6 Combo System
3 correct placements in a row → "Combo x3!" flash + bonus sparkle + score multiplier
5 in a row → "On Fire!" flash + background pulse effect
Full shelf completed in one run → "Shelf Master!" celebration + +50 coins
7. LEVEL & PROGRESSION SYSTEM
7.1 Level Map Screen
Displayed as a scrollable store blueprint / top-down map
Completed levels show a filled/decorated shelf icon
3-star levels show a golden shine effect
Current level pulses gently to draw attention
Locked levels are greyed out with a padlock icon
Levels unlock sequentially — no energy system (no waiting to play)
7.2 Star System
Performance	Stars	Criteria
Optimal	⭐⭐⭐	Completed in ≤ optimal moves
Good	⭐⭐	Within 20% extra moves
Complete	⭐	Any number of moves
Stars unlock bonus cosmetics (shelf decorations, item skins)
Players can replay any completed level to improve star count
7.3 Currency: Coins & Gems
Coins (Soft Currency):

Earned every level (amount based on stars: 10/20/30 coins)
Used to: buy cosmetic shelf decorations, item skin colors
Never used to unlock levels or power-ups
Gems (Hard Currency):

Earned free: Daily login (5 gems), 3-star bonus (+3 gems), achievements
Also purchasable via IAP
Used for: Remove-Ads package, premium cosmetic themes, extra daily tools bundle
7.4 Daily Login Rewards
Day	Reward
Day 1	50 Coins
Day 2	1 Gem + 1 Hint
Day 3	100 Coins
Day 4	2 Gems
Day 5	1 Shuffle + 100 Coins
Day 6	3 Gems
Day 7	"Lucky Box" (random premium cosmetic)
8. THEME ROOMS
Each Theme Room unlocks every 25 levels. New theme = new items, new shelf style, new background, new color palette, new ambient sounds.

#	Room Name	Items	Shelf Style	Ambience
1	☕ Cozy Kitchen	Mugs, cups, jars	Wooden oak	Coffee shop morning
2	🍰 Sweet Bakery	Cupcakes, cake boxes, macarons	White marble	Warm oven, soft music
3	📚 Vintage Library	Books, candles, globes	Dark walnut	Page-turn, quiet room
4	🌿 Garden Corner	Plant pots, watering cans, seeds	Rustic bamboo	Birds, breeze
5	🧸 Toy Chest	Stuffed toys, blocks, balls	Colorful plastic	Kids room playful
6	💄 Beauty Boutique	Perfume bottles, lipsticks, creams	Mirrored acrylic	Soft spa music
7	🎮 Game Den	Controllers, cartridges, headphones	Industrial metal	Game sounds, neon
8	🍕 Food Market	Cans, sauce bottles, snack boxes	Market stall	Busy market sounds
9	🏡 Home Décor	Vases, frames, candles	Minimalist white	Calm interior
10	🎁 Gift Wrapping	Ribbon boxes, gift bags, ornaments	Festive red/gold	Soft holiday music
Note for Cursor/Dev: Each theme is a "scene pack" — swap background image, shelf texture, item 3D models, and ambient audio track. Core gameplay logic is identical across all themes.

10. SCREEN-BY-SCREEN LAYOUT
SCREEN 1: SPLASH SCREEN
Full-screen animated logo
"ShelfSort Master" wordmark (elegant serif font)
Mia character waving from behind a shelf
Duration: 2.5 seconds → auto-navigate to Home
SCREEN 2: HOME / MAIN MENU
Top Bar:

Left: Player avatar + name
Center: Gem count + Coin count (icons + numbers)
Right: Settings gear icon
Center:

Mia's Store exterior (beautiful illustrated storefront, changes per current theme)
Animated: door open/close, lights flicker on, little birds land on sign
Large glowing "PLAY" button (center bottom)
"Daily Challenge" banner (top-right corner, pulsing if unclaimed)
Bottom Navigation Bar (5 tabs):

🏠 Home
🗺️ Map (level selector)
🎁 Daily Rewards
🛍️ Shop
👤 Profile
SCREEN 3: LEVEL MAP
Horizontal or vertical scroll path
Nodes = levels (circular badges)
Node states: Locked (gray), Unlocked (colored), 1-star (bronze), 2-star (silver), 3-star (gold)
Section headers: "Kitchen Zone (1–25)", "Bakery Zone (26–50)"
Tap locked level → "Keep playing to unlock!" tooltip
SCREEN 4: LEVEL INTRO (Pre-level popup)
Shows: Level number, Theme Room name, Brief objective ("Sort all the mugs!")
Difficulty badge (Easy / Normal / Hard / Boss)
"Play" button + "Back" button
No energy shown — instant play
SCREEN 5: GAMEPLAY SCREEN
Layout (Portrait orientation):

┌─────────────────────────────────┐
│  [← Back]   Level 47  ☆☆☆     │  ← Top bar
│  Moves: 24    [⏸ Pause]        │
├─────────────────────────────────┤
│                                 │
│   [SHELF ROW 1: 6 slots]       │  ← Shelves area (60% of screen)
│   [SHELF ROW 2: 6 slots]       │
│   [SHELF ROW 3: 6 slots]       │
│   [SHELF ROW 4: 6 slots]       │
│                                 │
├─────────────────────────────────┤
│  [↩ Undo] [💡 Hint] [🔀 Shuffle]│  ← Tools bar (always visible)
│  [✨ Auto]  [➕ Shelf]          │
│       Remaining: 3 💡  2 🔀    │  ← Small count indicators
└─────────────────────────────────┘

Visual Rules:

Items have subtle drop shadows when lifted (floating effect)
Correct shelf slots glow GREEN when an item is held above them
Invalid slots glow RED
Completed shelves get a celebratory gold shimmer that fades in 1.5s
SCREEN 6: LEVEL COMPLETE
Confetti burst animation
Stars awarded fly in one by one with sound (★ whoosh, ★ whoosh, ★ whoosh)
"Perfect Placement!" banner if all same-type groupings matched
Coins earned shown with coin-flip animation
3 buttons:
"Next Level" (primary, large)
"Replay" (secondary)
"Map" (text link)
Optional: "Watch ad for 2x coins" (non-intrusive offer, skip-able)
SCREEN 7: DAILY CHALLENGE
Special curated level, refreshes every 24 hours
Different from normal levels — uses a unique "mixed themes" board (e.g., kitchen mugs + bakery boxes together)
Rewards: Exclusive cosmetic item (only earnable via Daily Challenge)
Shows "Time remaining" countdown
Leaderboard tab: shows top 10 players' completion times (social feature)
SCREEN 8: SHOP
Sections:

Remove Ads — "$2.99 — Remove all ads forever" (most prominent, top banner)
Starter Bundle — "$0.99 — 20 Gems + 50 Coins + 5 Hints" (one-time, limited offer)
Gem Packs — $0.99 / $2.99 / $4.99 / $9.99 bundles
Cosmetics — Shelf skins, item color themes, Mia outfit skins (coins or gems)
Daily Tools Bundle — "$1.99 — 2x daily tools for 7 days"
Design Rule: No "mystery boxes" or gambling mechanics. All purchases show exactly what you get.

SCREEN 9: SETTINGS
Sound Effects toggle (on/off)
Music toggle (on/off)
ASMR Mode toggle (louder, more detailed placement sounds)
Vibration/Haptics toggle
Notifications toggle
Language selector
Restore purchases
Privacy Policy / Terms of Service links
"Rate this game" link
App version number
SCREEN 10: PAUSE SCREEN (In-game overlay)
Semi-transparent dark overlay on gameplay
Options: Resume | Restart Level | Settings | Exit to Map
"Are you sure?" confirmation before Restart/Exit (to prevent accidental progress loss)
11. ART DIRECTION & VISUAL STYLE
Overall Aesthetic: "Warm 3D Isometric"
Style: Soft 3D rendered objects with warm lighting, slight cel-shading edges
NOT hyper-realistic — items are cute, stylized, chunky versions of real objects
Color palette: Rich, saturated item colors (not pastel, not neon) — think Pantone-quality
Shelves: Wood-grain textures, warm amber tones for default Kitchen theme
Background: Blurred/depth-of-field bokeh effect — feels like professional product photography
Item Design Rules:
All items have a slightly rounded, toy-like form (not sharp angles)
Color is the primary identifier — each color is clearly distinct (no similar shades in same level)
Items cast soft drop shadows on the shelf surface
Items have subtle gloss/sheen on top surfaces
Size is consistent within a type — all mugs same scale, all jars same scale
Character — Mia:
Appears on: Splash, Home, Level Complete (celebrating), Theme Room unlock
Style: Chibi-style (big head, expressive eyes), warm skin tone, brown hair in ponytail
Outfit changes per Theme Room (chef apron in Bakery, gardening gloves in Garden, etc.)
Expressions: Happy (default), Excited (3-star), Thinking (Hard level), Celebrating (Boss clear)
UI Components Style:
Buttons: Rounded rectangle (16px radius), bold drop shadow, gradient fill
Primary button: Deep orange → amber gradient
Secondary button: White with dark border
Fonts:
Headers/Logo: Rounded bold (suggest: Nunito Bold or Fredoka One)
Body/Scores: Clean sans-serif (suggest: Nunito Regular)
Icons: Outlined style, 2px stroke, filled only when active
Cards: White background, soft shadow (0 4px 12px rgba(0,0,0,0.1))
Color Palette (UI — not items):
Primary:     #FF6B35  (warm orange)
Secondary:   #FFD700  (golden yellow)
Background:  #FFF8F0  (warm off-white)
Surface:     #FFFFFF
Text Dark:   #2D2D2D
Text Light:  #7A7A7A
Success:     #4CAF50  (green)
Error:       #F44336  (red)
Accent:      #9C27B0  (purple — for gems/premium)

12. SOUND & ASMR DESIGN
Sound Design Philosophy:
Sound is a core gameplay feature, not background decoration. Players should be able to play with eyes closed and feel progress through audio alone.

Sound Events:
Action	Sound Description
Pick up item	Soft ceramic/plastic "pick" — light, crisp
Valid placement	Satisfying "clunk" or "click" specific to item type
Invalid placement	Soft muffled "thud" — non-jarring
Complete a shelf	Gentle chime sequence ascending (do-re-mi feel)
Level complete	Full melody burst + crowd cheer (small, delightful)
3-star	Triumphant 3-note fanfare
Combo trigger	Smooth "whoosh + sparkle" sound
Undo	Gentle reverse "swish"
Shuffle	Cards-shuffling sound
Hint glow	Soft notification chime
Button tap	Light "pop"
Daily login	"Good morning!" jingle
Item-Specific Sounds (per theme):
Kitchen: Ceramic mug on wood = hollow "clunk", glass jar = crystal "clink"
Bakery: Soft box = gentle "thud", cupcake tray = slight rattle
Library: Book on shelf = satisfying "thwack", paper rustle on pickup
Garden: Terracotta pot = earthy "thunk", metal can = metallic "ting"
Toy Chest: Plastic block = hollow "clack", stuffed toy = soft squeeze sound
ASMR Mode (Settings Toggle):
All sounds 40% louder
Additional ambient layer added (e.g., quiet kitchen sounds in background)
Placement sounds have longer tail/reverb
Specifically targets ASMR audience — high virality on YouTube/TikTok
Music:
Default: Lo-fi, warm, instrumental — changes per theme room
Kitchen: Soft jazz/coffee shop
Bakery: Light French accordion
Library: Soft classical piano
Adaptive: Music tempo slightly increases during "Boss" levels
13. MONETIZATION STRATEGY
Philosophy: "Earn First, Pay for Comfort"
Players can complete 100% of content without spending a single rupee/dollar. Monetization is for removing friction and getting cosmetics, not unlocking gameplay.

Revenue Streams:
Stream 1: Rewarded Video Ads (Primary Revenue)
Player VOLUNTARILY watches 30-second ad to earn:
+1 Hint
+1 Shuffle
+1 Auto-Sort tool
2x coins on current level
Continue after stuck (special case)
NO forced interstitial ads between levels
NO banner ads on gameplay screen
Banner ad shown ONLY on Level Map screen, at bottom (non-intrusive)
Stream 2: Remove Ads IAP ($2.99)
Removes: Level map banner ad
Keeps: Player's ability to still CHOOSE to watch ads for bonus tools
Most important premium offer — display prominently in Shop
Stream 3: Starter Bundle ($0.99 — One Time)
20 Gems + 50 Coins + 5 Hints
Show on Day 3 of play (when player understands value)
Only offered once, never shown again
Stream 4: Gem Packs
$0.99 = 20 Gems
$2.99 = 75 Gems (best value badge)
$4.99 = 130 Gems
$9.99 = 300 Gems
Stream 5: Cosmetic Items (Coins/Gems)
Shelf skin packs: 500 Coins each
Item color theme: 200 Coins each
Mia outfit: 5 Gems each
Seasonal limited packs: 15 Gems (sold for 7-day windows)
What is NEVER Paywalled:
Levels (all 250+ levels free)
Level progression (no energy system)
Undo button (unlimited)
Basic gameplay tools (3 hints + 2 shuffles per day, free)
Story completion
14. FUNCTIONAL REQUIREMENTS
FR-001: Core Gameplay
FR-001.1: Player can tap any item on the board to pick it up
FR-001.2: Only one item can be held at a time
FR-001.3: Player can place held item on any empty shelf slot
FR-001.4: System validates placement instantly (< 50ms response)
FR-001.5: Item returns to original position if player taps it again while holding
FR-001.6: Level is marked complete when all items are placed on matching shelves
FR-001.7: Move counter increments on every successful placement
FR-001.8: Stars are calculated on level completion based on moves used
FR-002: Level System
FR-002.1: Game launches with 250 pre-designed levels
FR-002.2: Levels unlock sequentially; no skipping allowed (except via gem purchase for $0.49/level)
FR-002.3: Each level stores: best star count, best move count, total plays
FR-002.4: Player can replay any unlocked level
FR-002.5: Level progress auto-saves every 2 seconds (no manual save needed)
FR-002.6: If app is force-closed mid-level, player resumes from exact state on next open
FR-003: Power-Up Tools
FR-003.1: Hint button highlights the optimal next move (glow effect on item + destination)
FR-003.2: Shuffle button redistributes all unplaced items randomly
FR-003.3: Undo button reverses the last move (unlimited uses)
FR-003.4: Auto-Sort performs 3 optimal moves automatically
FR-003.5: Extra Shelf adds a temporary 4-slot shelf for 5 moves
FR-003.6: Daily tool counts reset at midnight (local device time)
FR-003.7: Tool count displays live on gameplay screen (e.g., "3 💡")
FR-003.8: Watching a rewarded ad grants exactly 1 additional use of the chosen tool
FR-004: Monetization & Ads
FR-004.1: No interstitial (forced popup) ads between levels
FR-004.2: No ads during active gameplay
FR-004.3: Banner ad displayed on Level Map screen only (bottom strip, 50dp height)
FR-004.4: Rewarded ad offer appears after level complete or when tools run out (not forced)
FR-004.5: Remove Ads purchase persists permanently (tied to Google account)
FR-004.6: All IAP prices display in local currency (auto-converted via Play Store billing)
FR-004.7: Purchase restoration option available in Settings
FR-005: Daily Challenge
FR-005.1: New challenge board generates daily at 00:00 UTC
FR-005.2: Same board for all players globally (seeded random)
FR-005.3: Player can only complete each daily challenge once
FR-005.4: Completion time is recorded for leaderboard
FR-005.5: Daily challenge reward is claimed immediately on completion
FR-005.6: If player misses a day, reward is forfeited (no makeup)
FR-006: Daily Login Rewards
FR-006.1: Calendar shows 7-day cycle
FR-006.2: Day 1 always claimable on first open of each day
FR-006.3: Streak resets to Day 1 if player misses a day
FR-006.4: Day 7 reward is a "Lucky Box" with random premium cosmetic
FR-006.5: Notification sent 8 hours after last session ("Your daily reward is waiting!")
FR-007: Progression & Story
FR-007.1: Every 25 levels, a "Theme Room Unlock" animation plays (cannot be skipped on first view)
FR-007.2: Mia dialogue appears at: Level 1, every 25th level, and Boss level completions
FR-007.3: "Mia's Store" on home screen visually updates (more shelves, more items) as player progresses
FR-008: Settings & Accessibility
FR-008.1: Sound effects can be toggled off independently from music
FR-008.2: ASMR mode can be enabled/disabled
FR-008.3: Haptic feedback can be enabled/disabled
FR-008.4: Item types display a text label on long-press (for colorblind accessibility)
FR-008.5: High-contrast mode available (items get distinct patterns, not just color)
FR-008.6: Language auto-detects from device locale; manual override available
FR-008.7: Text size follows device accessibility settings
FR-009: Offline Play
FR-009.1: All 250 levels playable fully offline (no internet required)
FR-009.2: Daily challenge and leaderboard require internet
FR-009.3: Purchases sync when internet is restored
FR-009.4: Rewarded ads not shown when offline; alternative (watch when online later) shown
FR-010: Performance
FR-010.1: App launch to Home screen: < 3 seconds on mid-range device
FR-010.2: Level load time: < 1.5 seconds
FR-010.3: Gameplay runs at stable 60 FPS on devices with Snapdragon 660+
FR-010.4: App size: < 150MB initial download
FR-010.5: Additional assets (new themes) downloadable as needed (< 20MB per theme)
15. NON-FUNCTIONAL REQUIREMENTS
NFR-001: Performance
Target FPS: 60 FPS on mid-range Android (Snapdragon 660+, 3GB RAM)
Minimum FPS: 30 FPS on low-end Android (Snapdragon 450, 2GB RAM)
Memory usage: < 300MB RAM at peak
Battery: No excessive background activity; pause all animations when app is backgrounded
Thermal: No device heating during normal play session (30 min)
NFR-002: Stability & Reliability
Crash rate: < 0.1% of sessions
ANR (App Not Responding) rate: < 0.05%
All critical data (level progress, purchases, coins) stored locally AND cloud-synced via Google Play Games
Zero data loss on force-close or crash (auto-save every 2 seconds)
App recovers cleanly from phone call interruption
NFR-003: Compatibility
Minimum Android version: Android 8.0 (API Level 26)
Target Android version: Android 14 (API Level 34)
Screen sizes: 5"–7" (all standard aspect ratios: 16:9, 18:9, 20:9, 21:9)
Notch/punch-hole support: UI elements avoid notch area
Foldable device: Basic support (no crash; not optimized in v1.0)
NFR-004: Security
No personally identifiable information (PII) collected beyond what Google Play requires
GDPR and CCPA compliant consent flow on first launch
COPPA compliant (app rated Everyone — no data collection from under-13)
All IAP transactions handled exclusively by Google Play Billing (no custom payment flow)
No third-party SDKs with excessive permissions
NFR-005: Scalability
Backend (if any) must handle 100,000 concurrent users for Daily Challenge leaderboard
Level data stored as JSON; new levels deployable via remote config without app update
New theme packs deliverable via OTA asset download without app update
NFR-006: Maintainability
Code must follow consistent naming conventions (camelCase for variables, PascalCase for components)
Each game mechanic isolated as independent module (no monolithic files)
Level data (positions, colors, item types) stored in separate JSON files (not hardcoded)
All string copy (UI text, Mia dialogue) in a single localization file per language
All magic numbers defined as named constants
NFR-007: Accessibility
All interactive elements: minimum 44dp touch target size
Color is never the ONLY differentiator (patterns/shapes also used — colorblind support)
Text contrast ratio: minimum 4.5:1 (WCAG AA)
Screen reader (TalkBack) compatibility for main menus (not gameplay — complex)
Support for system font scaling up to 150%
NFR-008: Analytics & Monitoring
All critical events logged to analytics (see Data & Analytics section)
Crash reporting integrated (Firebase Crashlytics)
Performance monitoring: FPS drops, load times tracked automatically
A/B testing framework ready for monetization experiments
NFR-009: Localization
Launch languages: English, Urdu, Hindi, Indonesian, Portuguese (Brazil), Arabic
Arabic: Full RTL (right-to-left) layout support
All text externalized (no hardcoded strings)
Number formatting per locale (e.g., Indian comma system for Hindi)
Date/time formatting per locale
NFR-010: Store Compliance
Google Play Content Rating: Everyone
No violent content, no adult content, no gambling mechanics
Play Store screenshot guidelines: 2–8 screenshots, 16:9 or 9:16
Play Store video: 30-second gameplay trailer required
Privacy Policy URL required (host on simple web page)
Data Safety section accurately filled in Play Console
16. PLAYER RETENTION SYSTEMS
Push Notifications Strategy:
Trigger	Message	Timing
Daily reward ready	"🎁 Your daily reward is waiting, Mia needs you!"	8 hours after last session
Daily challenge	"⏰ Today's challenge is live! Can you beat the clock?"	9:00 AM local time
Streak at risk	"😢 Don't break your streak! You've been going 6 days strong."	22:00 if not played
New theme unlock	"🎉 New Store Section unlocked: The Bakery is calling!"	Immediately on eligibility
Seasonal event	"🎄 Holiday sorting event is LIVE for 7 days only!"	Event start
Social / Sharing:
"Share Score" button on Level Complete screen → generates image card with score + stars
Daily Challenge leaderboard (top 10 globally, + player's rank)
"Challenge a Friend" — share level link (deep link to specific level)
Achievement System (30 achievements at launch):
"First Sort" — Complete Level 1
"Speed Sorter" — Complete any level in < 20 moves
"Perfectionist" — 3-star 10 levels in a row
"Daily Devotee" — 7-day login streak
"Kitchen Master" — Complete all Kitchen levels
"No Help Needed" — Complete 20 levels without using any tools
"ASMR Addict" — Play 1 hour in ASMR mode
(and 23 more...)
Seasonal Events (3 per year):
Ramadan Special: Golden themed levels + limited Mia outfit
Summer Sale: Double coins for 1 week + summer-themed items
Holiday Sort: Christmas/Eid themed theme room (only during holiday weeks)
17. TECHNICAL SPECIFICATIONS
Recommended Technology Stack (for Cursor):
Engine:           Unity 2022 LTS or Godot 4.x (mobile-optimized)
Language:         C# (Unity) or GDScript/C# (Godot)
3D Rendering:     3D assets with URP (Universal Render Pipeline) in Unity
                  OR 2.5D approach: 3D items on 2D shelf layout (simpler, faster)
Ad SDK:           Google AdMob (rewarded + banner)
IAP SDK:          Google Play Billing Library 6.x
Analytics:        Firebase Analytics + Firebase Crashlytics
Save System:      PlayerPrefs (local) + Google Play Games Services (cloud)
Level Data:       JSON files loaded at runtime
Localization:     Unity Localization Package or custom CSV reader
Push Notif:       Firebase Cloud Messaging (FCM)
Build Target:     Android APK + AAB (App Bundle for Play Store)
Min API Level:    26 (Android 8.0)
Target API Level: 34 (Android 14)

Level Data Format (JSON):
{
  "levelId": 47,
  "themeRoom": "kitchen",
  "difficulty": "hard",
  "optimalMoves": 28,
  "shelves": [
    {
      "shelfId": 1,
      "slots": 6,
      "targetColor": "red",
      "targetType": "mug"
    },
    {
      "shelfId": 2,
      "slots": 6,
      "targetColor": "blue",
      "targetType": "cup"
    }
  ],
  "initialPlacement": [
    { "itemId": "mug_red_01", "shelfId": 2, "slot": 3 },
    { "itemId": "cup_blue_01", "shelfId": 1, "slot": 1 }
  ],
  "starThresholds": {
    "3star": 28,
    "2star": 35,
    "1star": 999
  }
}

Project Folder Structure:
ShelfSortMaster/
├── Assets/
│   ├── Art/
│   │   ├── Items/          # 3D models per theme
│   │   ├── Shelves/        # Shelf textures per theme
│   │   ├── Backgrounds/    # Background images per theme
│   │   ├── UI/             # All UI sprites and icons
│   │   └── Characters/     # Mia character sprites
│   ├── Audio/
│   │   ├── SFX/            # All sound effects
│   │   └── Music/          # Background music per theme
│   ├── Data/
│   │   └── Levels/         # level_001.json to level_250.json
│   ├── Scripts/
│   │   ├── Gameplay/       # Core sorting mechanics
│   │   ├── UI/             # All UI controllers
│   │   ├── Systems/        # Save, progression, tools
│   │   ├── Monetization/   # Ads, IAP handlers
│   │   └── Analytics/      # Event tracking
│   └── Scenes/
│       ├── Boot.unity
│       ├── MainMenu.unity
│       ├── LevelMap.unity
│       ├── Gameplay.unity
│       └── Shop.unity

18. DATA & ANALYTICS
Critical Events to Track:
Event Name	Parameters	Purpose
level_start	level_id, theme_room	Funnel tracking
level_complete	level_id, stars, moves, time_ms	Difficulty calibration
level_fail_stuck	level_id, move_count	Find hard levels
tool_used	tool_type, was_free, level_id	Tool demand
ad_watched	ad_type, reward_type, level_id	Revenue tracking
ad_skipped	ad_type, time_watched	Ad performance
iap_initiated	product_id, source_screen	Conversion funnel
iap_complete	product_id, amount	Revenue
iap_cancelled	product_id	Drop-off analysis
daily_login	streak_day	Retention
daily_challenge_complete	time_ms, tools_used	Engagement
theme_room_unlocked	room_name, level_id	Milestone
session_start	time_since_last_session	Session analysis
session_end	session_duration, levels_played	Session depth
app_crash	level_id, action	Stability
Key KPIs Dashboard:
D1/D7/D30 retention rates
Average session length
Levels completed per session
Ad fill rate + eCPM
IAP conversion rate (target: 2–3%)
Level difficulty drop-off (find levels where >30% players quit)
Tools usage rate
19. OUT OF SCOPE (v1.0)
The following features are NOT in v1.0 and should NOT be built initially:

❌ Multiplayer / PvP modes
❌ Social graph (friends list, gifting)
❌ iOS version (Android first; iOS v1.1)
❌ Tablet-specific layout optimization
❌ Level editor (players creating levels)
❌ Chat / community features
❌ Web/PC version
❌ AR mode
❌ Subscription model
❌ Foldable device optimization
❌ More than 10 theme rooms in v1.0
20. GLOSSARY
Term	Definition
Shelf Slot	One individual position on a shelf where a single item can be placed
Item	A 3D object (mug, cup, jar, etc.) that player picks up and places
Theme Room	A visual and thematic environment containing 25 levels
Boss Level	Every 25th level — larger board, more items, higher challenge
Combo	3+ correct placements in a row without any invalid move
Optimal Moves	The minimum number of moves needed to clear a level (used for 3-star calculation)
ASMR Mode	Enhanced audio mode with louder, more detailed placement sounds
Rewarded Ad	Video ad the player voluntarily watches in exchange for a game reward
Hard Currency (Gems)	Premium currency; earned free slowly or purchased via IAP
Soft Currency (Coins)	Regular currency; earned every level, used for cosmetics
IAP	In-App Purchase — a real-money transaction within the app
DAU	Daily Active Users
D1/D7/D30	Day 1/7/30 retention rates — % of users who return after N days
eCPM	Effective Cost Per Mille — ad revenue per 1000 ad views
ANR	App Not Responding — a system-level Android crash type
RTL	Right-to-Left — text direction for Arabic/Urdu languages
OTA	Over The Air — delivering content updates without a full app update
FCM	Firebase Cloud Messaging — push notification service
URP	Universal Render Pipeline — Unity's mobile-optimized rendering system
APPENDIX A: SCREENS CHECKLIST FOR UI DESIGN
The following screens need UI design mockups (give this list to ChatGPT for image generation):

✅ Splash Screen
✅ Main Menu / Home Screen
✅ Level Map Screen (scrollable)
✅ Level Intro Popup
✅ Gameplay Screen — Kitchen Theme (early levels, simple board)
✅ Gameplay Screen — Bakery Theme (mid levels, fuller board)
✅ Gameplay Screen — Item being held (floating state)
✅ Gameplay Screen — Shelf completion celebration (gold shimmer)
✅ Level Complete Screen (3-star)
✅ Level Complete Screen (1-star)
✅ Daily Challenge Screen
✅ Shop Screen
✅ Settings Screen
✅ Pause Screen (in-game overlay)
✅ Daily Login Rewards Calendar
✅ Theme Room Unlock Celebration Animation Frame
✅ Achievement popup
✅ Rewarded Ad offer popup (non-intrusive)
✅ Tutorial overlay (step 1 of 5)
APPENDIX B: PROMPT FOR CHATGPT (UI Image Generation)
Use this as the base prompt for each screen design request to ChatGPT:

Design a mobile game UI screen for "ShelfSort Master" — a 3D goods sorting puzzle game 
for Android. 
Visual style: Warm, soft 3D isometric look. Items are cute, chunky, colorful (mugs, cups, 
ceramic jars). Shelves are wooden oak texture with warm lighting. Background is blurred 
bokeh. Character "Mia" is chibi-style (big expressive eyes, brown hair in ponytail).
Color palette: Primary orange (#FF6B35), golden yellow (#FFD700), warm off-white 
background (#FFF8F0), deep green for success states.
Font feel: Rounded, friendly, bold headers. Clean sans-serif for numbers/body text.
Buttons: Rounded rectangle, gradient fill (orange-to-amber), soft drop shadow.
Specific screen to design: [INSERT SCREEN NAME AND DESCRIPTION FROM APPENDIX A]
Output: Portrait mobile screen (1080x1920px), clean, polished, production-ready.
Include bottom navigation bar with 5 icons: Home, Map, Rewards, Shop, Profile.

---

# 6A. DYNAMIC LEVEL MECHANICS & TWIST SYSTEM — NEW CORE REQUIREMENT

## 6A.1 Purpose

The game must not rely only on increasing item count or adding new colors to create difficulty. As players progress, levels must introduce **new interactive mechanics, movement patterns, hidden layers, timing challenges, and rule combinations**.

The intended player feeling is:

> "I already understand the sorting game, but every few levels something new happens."

This system is a core retention feature and must be treated as a first-class gameplay system, not as cosmetic variation.

The design goal is to create a progression curve inspired by the best-performing 3D sorting puzzle experiences while maintaining the game's own identity, visual language, and fair monetization.

## 6A.2 Core Design Rules

1. Every mechanic must be introduced gradually.
2. Never introduce more than one completely new mechanic in a normal level unless the level is explicitly marked as a tutorial or Boss.
3. The first level containing a new mechanic must teach it visually through animation and a short contextual tutorial.
4. The player must understand the mechanic without reading a long text explanation.
5. Mechanics must remain fair and predictable after introduction.
6. Randomness must never make a solvable level feel impossible.
7. A mechanic must be used repeatedly after introduction; do not introduce a mechanic once and immediately abandon it.
8. New mechanics may be combined with older mechanics in later levels.
9. Boss levels should combine mechanics rather than simply increasing item count.
10. After a difficult Boss level, provide a Rest/Celebration level.
11. All mechanics must work offline.
12. Every mechanic must support save/resume without losing its exact state.
13. Every mechanic must be optimized for stable 60 FPS on supported devices.
14. All moving objects must have clear visual affordances and predictable movement.
15. Color must never be the only way to communicate a mechanic or state.

## 6A.3 Dynamic Mechanic Progression

Recommended progression:

### Levels 1–5: Pure Sorting Foundation
- Static shelves.
- 3 colors maximum.
- 2 item types.
- No hidden items.
- No moving shelves.
- No timing pressure.
- Tutorial teaches pick, place, undo, and valid/invalid placement.

### Levels 6–10: Visual Complexity
- Slightly larger boards.
- 3 colors.
- 2–3 item types.
- Introduce Perfect Placement and Combo system.
- Introduce shelf completion celebrations.

### Levels 11–15: Hidden Back Row
Introduce the **Hidden Back Row** mechanic.

### Levels 16–20: Moving Bottom Trays
Introduce the **Moving Tray** mechanic.

### Levels 21–24: Locked and Sealed Items
Introduce **Locked Items** and simple unlock conditions.

### Level 25: BOSS — Kitchen Master
Combine:
- Hidden Back Row
- Moving Bottom Tray
- Locked Items
- Larger board

### Level 26: Rest/Celebration
- Easy board.
- New theme introduction.
- No new mechanic.
- Reward-focused experience.

### Levels 27–35: Bakery Mechanics
Introduce:
- Sliding Shelves
- Mystery Boxes
- Stacked Items

### Levels 36–40: Timing Mechanics
Introduce:
- Conveyor Shelf
- Rotating Tray

### Levels 41–49: Combination Challenges
Combine 2–3 previously learned mechanics.

### Level 50: BOSS — Bakery Rush
Combine:
- Conveyor Shelf
- Rotating Tray
- Mystery Boxes
- Hidden Back Row

### Levels 51–75: Advanced Interaction
Introduce:
- Frozen/Ice Items
- Moving Dividers
- Chain Release

### Level 75: BOSS — Library Lockdown

### Levels 76–100:
Introduce:
- Theme-specific mechanics.
- More complex combinations.
- Multi-stage reveal sequences.
- Controlled moving shelf layouts.

### Level 100: BOSS — Grand Store Challenge

For levels 101–250, mechanics should continue to evolve through combinations, variations, and theme-specific presentation rather than endlessly introducing unrelated systems.

---

## 6A.4 Mechanic 1 — Hidden Back Row

### Player Experience

The visible front row contains items that block a second row of items behind them. The back-row items are not fully accessible until enough front-row items have been removed.

### Rules

- Front-row items are interactable.
- Back-row items are visually visible but disabled/occluded.
- When a blocking front item is removed, the corresponding back item moves forward.
- The movement must be smooth and satisfying.
- The player must clearly understand that the item was previously behind another item.

### Visual Feedback

- Back-row items are slightly darker or blurred.
- A subtle depth shadow communicates that they are behind.
- On reveal, the item slides forward with a soft bounce.
- Optional sparkle on first reveal.

### Difficulty Variations

1. One hidden row.
2. Two hidden rows.
3. Alternating hidden positions.
4. Hidden row containing a required matching item.
5. Hidden row combined with Locked Items.

### Functional Requirements

- FR-DM-001: Hidden items must retain their exact position in save data.
- FR-DM-002: A hidden item becomes interactable only when its blocking condition is satisfied.
- FR-DM-003: Reveal animation must not alter game state incorrectly.
- FR-DM-004: A level must never become unsolvable because of a reveal ordering bug.

---

## 6A.5 Mechanic 2 — Moving Bottom Tray

### Player Experience

A holding tray at the bottom of the screen moves horizontally between defined positions. The player must place an item into an available slot while the tray is moving.

### Rules

- The tray follows a predictable loop or ping-pong movement.
- The tray contains 4–6 slots.
- The player can tap the tray while it is moving.
- Valid placement is determined by the current slot state.
- The tray must never move so quickly that interaction becomes frustrating.

### Difficulty Variations

- Slow movement.
- Faster movement.
- Multiple stop points.
- Temporary pause zones.
- Two trays moving at different speeds.

### Accessibility

- Reduced Motion mode slows or disables decorative movement.
- The mechanic must remain playable without relying on reaction speed alone.

### Functional Requirements

- FR-DM-005: Tray movement must be deterministic from level seed.
- FR-DM-006: Tray position must be saved when the app is backgrounded.
- FR-DM-007: Tray collision and placement detection must remain accurate during animation.
- FR-DM-008: Player must never lose an item because of a visual-only movement mismatch.

---

## 6A.6 Mechanic 3 — Sliding Shelves

A complete shelf or shelf segment moves horizontally to reveal or hide slots.

### Rules

- Shelf movement follows fixed paths.
- Movement is triggered by player actions or automatically.
- Hidden slots remain part of the level state.
- The player cannot place an item into an inaccessible slot.
- The shelf must visually communicate when it is about to move.

### Variations

- Left/right sliding.
- Alternating shelves.
- One shelf moving while others remain static.
- Sliding shelf revealing a hidden shelf behind it.

---

## 6A.7 Mechanic 4 — Rotating Tray

A circular tray rotates around a central pivot.

### Rules

- Items remain attached to tray slots.
- Rotation is smooth and deterministic.
- Player can interact with accessible slots.
- The tray may rotate after a correct placement.
- Rotation speed must remain comfortable for casual players.

### Advanced Variations

- Rotation after every move.
- Rotation after completing a mini-group.
- Clockwise/counter-clockwise alternating rotation.
- Partial rotation revealing hidden slots.

---

## 6A.8 Mechanic 5 — Conveyor Shelf

Items travel continuously along a conveyor-like shelf.

### Rules

- Items enter from one side and exit from another.
- The player can pick up available items.
- Items cannot be selected after leaving the interaction zone.
- The player can pause the conveyor using a limited mechanic only if the level explicitly provides it.
- Conveyor speed must be predictable.

### Difficulty Variations

- Slow conveyor.
- Multiple item lanes.
- Different speeds.
- Temporary blockers.
- Conveyor + Hidden Back Row.

---

## 6A.9 Mechanic 6 — Locked Items

Some items cannot be moved until a condition is fulfilled.

### Lock Types

- Color Lock: complete a specific color group.
- Type Lock: complete a specific item type.
- Key Lock: find and place a key item.
- Sequence Lock: complete 3 correct moves.
- Shelf Lock: complete an entire shelf.

### Visual Design

Locked items display:
- Lock icon.
- Subtle glow.
- Short unlock animation.

Never hide the reason for a lock.

---

## 6A.10 Mechanic 7 — Mystery Boxes

A box conceals its contents until opened.

### Rules

- Mystery boxes are initially closed.
- The box reveals its item after a defined trigger.
- The reveal cannot create an impossible board.
- The revealed item must be included in the level's solvability calculation.

### Trigger Examples

- Remove the item in front.
- Complete a shelf.
- Place a matching color.
- Open a specific key box.

---

## 6A.11 Mechanic 8 — Stacked Items

Items are physically stacked on top of one another.

### Rules

- Top item must be removed before lower item becomes available.
- Stack depth is limited for readability.
- Each reveal is visually communicated.
- Stacked items may be used as a controlled difficulty modifier.

---

## 6A.12 Mechanic 9 — Frozen/Ice Items

An item is temporarily frozen.

### Rules

- Frozen item cannot be moved.
- A defined unlock action removes the frozen state.
- Ice visually cracks before breaking.
- The mechanic must not be confused with Locked Items.

### Unlock Examples

- Complete a matching shelf.
- Place a warm-colored item.
- Perform 3 correct moves.

---

## 6A.13 Mechanic 10 — Moving Divider

A shelf divider changes available slot groups.

### Rules

- Divider movement is deterministic.
- Slots remain clearly visible.
- The divider cannot create ambiguous valid/invalid placement.
- Divider movement may create temporary grouping constraints.

---

## 6A.14 Mechanic 11 — Chain Release

One correct action triggers a sequence of reveals.

Example:

1. Player completes a red mug group.
2. A locked shelf opens.
3. Three hidden items slide forward.
4. A mystery box opens.
5. The newly revealed items become available.

Chain Release should feel rewarding and cinematic without blocking player control.

---

## 6A.15 Mechanic Combination Matrix

Mechanics should be combined intentionally.

| Combination | Intended Experience |
|---|---|
| Hidden Row + Moving Tray | Spatial planning + timing |
| Locked Items + Hidden Row | Discovery + planning |
| Sliding Shelf + Conveyor | Movement management |
| Rotating Tray + Hidden Row | Spatial awareness |
| Mystery Box + Chain Release | Surprise + reward |
| Frozen Items + Locked Items | Layered unlocking |
| Moving Divider + Sliding Shelf | Dynamic board management |
| Conveyor + Moving Tray | Advanced timing |
| 3+ mechanics | Boss / advanced challenge only |

Do not combine more than 3 major mechanics in normal levels.

---

## 6A.16 Dynamic Mechanic Tutorial System

Every new mechanic must have a micro-tutorial.

### Tutorial Format

1. Pause normal gameplay.
2. Highlight the new mechanic.
3. Animate the expected interaction.
4. Show one short instruction.
5. Player performs one guided action.
6. Tutorial disappears.
7. Player continues normally.

Example:

**Hidden Back Row**
> "Clear the front items to reveal what's behind."

**Moving Tray**
> "The tray is moving! Tap a slot when it's ready."

Tutorials must be:
- Skippable after first successful interaction.
- Shown again from Settings > Help.
- Localized.
- Accessible with high contrast.

---

## 6A.17 Dynamic Level Data Schema

The JSON level format must support dynamic mechanics.

Example:

```json
{
  "levelId": 47,
  "themeRoom": "kitchen",
  "difficulty": "hard",
  "mechanics": [
    "hidden_back_row",
    "moving_bottom_tray"
  ],
  "optimalMoves": 28,
  "mechanicConfig": {
    "hiddenBackRow": {
      "rows": 2,
      "revealMode": "front_clear"
    },
    "movingBottomTray": {
      "slotCount": 5,
      "movementMode": "ping_pong",
      "speed": 0.65,
      "pauseAtEnds": 0.4
    }
  },
  "shelves": [],
  "initialPlacement": [],
  "starThresholds": {
    "3star": 28,
    "2star": 35,
    "1star": 999
  }
}
```

### Required JSON Fields

- `mechanics`
- `mechanicConfig`
- `movementMode`
- `speed`
- `revealMode`
- `unlockCondition`
- `seed`

The system must support multiple mechanics in one level.

---

## 6A.18 Dynamic Mechanics Technical Architecture

Implement each mechanic as an independent module.

Recommended interface:

```text
ILevelMechanic
├── Initialize()
├── Start()
├── Pause()
├── Resume()
├── Reset()
├── SaveState()
├── LoadState()
├── ValidateMove()
└── Dispose()
```

Examples:

```text
HiddenBackRowMechanic
MovingBottomTrayMechanic
SlidingShelfMechanic
RotatingTrayMechanic
ConveyorMechanic
LockedItemMechanic
MysteryBoxMechanic
StackedItemMechanic
FrozenItemMechanic
MovingDividerMechanic
ChainReleaseMechanic
```

The core sorting system must not contain mechanic-specific hardcoded logic.

Each mechanic should:
- Receive level configuration.
- Register with the LevelMechanicManager.
- Subscribe to relevant gameplay events.
- Expose save/load state.
- Be independently testable.
- Be enabled or disabled per level JSON.

---

# 10A. GAMEPLAY SCREEN — UPDATED PRODUCTION UI SPECIFICATION

The Gameplay Screen must evolve beyond a static shelf board.

## Top HUD

Left:
- Mia avatar.
- Current level.
- Theme name.

Center:
- Moves counter.
- Star performance meter.
- Optional combo indicator.

Right:
- Coins.
- Gems.
- Pause.

## Dynamic Objective Card

Display:
- Current objective.
- Active mechanic icon(s).
- Small progress indicator.

Example:

> "Clear the front row to reveal the hidden shelf."

If multiple mechanics are active, show up to 3 compact icons.

## Main Board

The board occupies approximately 55–65% of portrait screen height.

It must support:
- Static shelves.
- Hidden back rows.
- Sliding shelves.
- Moving trays.
- Conveyor shelves.
- Rotating trays.
- Stacked items.
- Locked items.

The board camera should smoothly reframe when dynamic mechanics activate.

## Bottom Interaction Area

The bottom area contains:
- Temporary holding tray.
- Moving tray if active.
- Extra Shelf.
- Selected item preview.
- Contextual mechanic feedback.

Do not permanently reserve a large empty area for mechanics that are not active.

## Right Tool Rail

Buttons:
1. Undo.
2. Hint.
3. Shuffle.
4. Auto-Sort.
5. Extra Shelf.

Each button:
- Minimum 52dp touch target.
- Clear icon.
- Daily count badge.
- Subtle animation when available.
- Disabled state when unavailable.

## Combo Feedback

- Combo x3: small burst.
- Combo x5: stronger screen pulse.
- Combo x7+: "UNSTOPPABLE!" moment.
- Do not obstruct board interaction.

## Mechanic Feedback

When a dynamic mechanic activates:
- Brief haptic.
- Small visual pulse.
- Short ASMR sound.
- No full-screen interruption unless tutorial is required.

---

# 10B. GAMEPLAY STATES TO DESIGN

The UI design system must include these production states:

1. Normal static board.
2. Item selected/floating.
3. Valid destination highlighted.
4. Invalid destination feedback.
5. Hidden back row revealing.
6. Moving tray in motion.
7. Sliding shelf in motion.
8. Rotating tray.
9. Conveyor active.
10. Locked item.
11. Mystery box reveal.
12. Stacked item reveal.
13. Frozen item breaking.
14. Moving divider.
15. Chain release.
16. Combo x3.
17. Combo x5.
18. Shelf complete.
19. Boss level active.
20. Level complete.

All states must share the same visual system and not feel like separate games.

---

# 14A. FUNCTIONAL REQUIREMENTS — DYNAMIC MECHANICS

FR-DM-001: The game supports level-specific mechanics configured by JSON.

FR-DM-002: Multiple mechanics may be active in a single level.

FR-DM-003: Each mechanic is independently enabled/disabled.

FR-DM-004: Mechanics expose save/load state.

FR-DM-005: Force-close recovery restores the exact mechanic state.

FR-DM-006: Mechanics must not modify the player's move count unless explicitly defined by the mechanic.

FR-DM-007: Mechanic animations must pause when the application enters background state.

FR-DM-008: Mechanic timers must use deterministic game time.

FR-DM-009: The level generator must validate solvability before release.

FR-DM-010: Hidden items cannot be accidentally selected before becoming available.

FR-DM-011: Moving trays must maintain accurate collision and touch detection.

FR-DM-012: Sliding shelves must prevent placement into inaccessible slots.

FR-DM-013: Conveyor items must have deterministic entry and exit states.

FR-DM-014: Rotating trays must maintain correct item-slot mapping.

FR-DM-015: Locked items must expose their unlock condition.

FR-DM-016: Mystery boxes must reveal valid, solvable items.

FR-DM-017: Stacked items must preserve stack order.

FR-DM-018: Frozen items must preserve freeze state during save/load.

FR-DM-019: Chain Release events must execute exactly once per trigger.

FR-DM-020: All dynamic mechanics must support reset without state corruption.

FR-DM-021: New mechanics must be introduced through contextual tutorials.

FR-DM-022: Tutorial completion must be stored locally.

FR-DM-023: Reduced Motion accessibility mode must reduce non-essential movement.

FR-DM-024: Colorblind mode must use shape, pattern, icon, or label in addition to color.

FR-DM-025: Dynamic mechanics must run at stable target FPS on supported devices.

---

# 16A. RETENTION IMPROVEMENT THROUGH MECHANIC MASTERY

The game should track mechanic mastery.

For each mechanic, track:
- First introduced level.
- First successful completion.
- Number of uses.
- Levels completed without tools.
- Best star performance.

Optional achievements:

- "Back Row Boss" — Clear 25 hidden-row levels.
- "Tray Tamer" — Complete 20 moving-tray levels.
- "No More Secrets" — Reveal 100 hidden items.
- "Perfect Timing" — Complete 10 moving-tray levels without Undo.
- "Conveyor Champion" — Complete 25 conveyor levels.
- "Unlock Master" — Complete 20 locked-item levels.

Mechanic mastery should reward cosmetics, coins, or achievements, never mandatory progression.

---

# 17A. ANALYTICS — DYNAMIC MECHANICS

Track:

```text
mechanic_introduced
mechanic_tutorial_started
mechanic_tutorial_completed
mechanic_tutorial_skipped
mechanic_activated
mechanic_interaction
mechanic_error
mechanic_completed
mechanic_level_abandoned
mechanic_level_completed
mechanic_combo_triggered
```

Parameters:

- `level_id`
- `theme_room`
- `mechanic_type`
- `mechanic_count`
- `difficulty`
- `moves`
- `time_ms`
- `tools_used`
- `tutorial_state`

KPIs:

- Completion rate by mechanic.
- Abandonment rate by mechanic.
- Average attempts by mechanic.
- Tool usage by mechanic.
- Average session length after mechanic introduction.
- D1/D7/D30 retention before and after mechanic introduction.
- Difficulty spike detection.
- Mechanic-specific crash rate.

If a mechanic causes a >30% completion drop compared with adjacent levels, flag it for design review.

---

# 17B. LEVEL AUTHORING TOOL REQUIREMENTS

For future production efficiency, designers should be able to configure:

- Level ID.
- Theme.
- Difficulty.
- Item types.
- Colors.
- Shelf count.
- Slot count.
- Initial positions.
- Hidden rows.
- Moving tray path.
- Conveyor speed.
- Rotation speed.
- Lock conditions.
- Mystery box triggers.
- Stack depth.
- Freeze conditions.
- Divider movement.
- Chain events.
- Optimal moves.
- Star thresholds.

The level editor is out of scope for player-facing v1.0, but the development pipeline should be structured so an internal editor can be added later.

---

# APPENDIX C. DYNAMIC MECHANIC UI MOCKUP CHECKLIST

Additional gameplay mockups required:

✅ Gameplay — Hidden Back Row visible  
✅ Gameplay — Back Row revealing animation frame  
✅ Gameplay — Moving Bottom Tray  
✅ Gameplay — Moving Tray with item selected  
✅ Gameplay — Sliding Shelf  
✅ Gameplay — Rotating Tray  
✅ Gameplay — Conveyor Shelf  
✅ Gameplay — Locked Item  
✅ Gameplay — Mystery Box reveal  
✅ Gameplay — Stacked Items  
✅ Gameplay — Frozen Item breaking  
✅ Gameplay — Moving Divider  
✅ Gameplay — Chain Release  
✅ Gameplay — Boss Level with 3 mechanics  
✅ Gameplay — New mechanic tutorial overlay  
✅ Gameplay — Mechanic objective card  
✅ Gameplay — Reduced Motion accessibility state  

---

# APPENDIX D. MASTER CURSOR AI IMPLEMENTATION BRIEF

## Product Identity

Build an Android-first 3D casual sorting puzzle game called **ShelfSort Master**.

The game must feel:
- Premium.
- Warm.
- Satisfying.
- Relaxing.
- Responsive.
- Visually rich.
- Easy to understand.
- Deep enough to retain players for hundreds of levels.

## Core Gameplay

Players sort 3D household goods by color and type onto shelves.

The game starts simple but gradually introduces dynamic mechanics.

The primary retention loop is:

```text
Learn sorting
→ Master sorting
→ Discover new mechanic
→ Learn mechanic
→ Combine mechanics
→ Beat Boss
→ Celebrate
→ Unlock new theme
→ Repeat
```

## Critical Implementation Principle

Do NOT build 250 levels as the same static board with different item counts.

Instead, build a reusable **Level Mechanics Framework**.

The framework must allow each level to declare:

```text
theme
difficulty
items
shelves
mechanics
mechanic configuration
movement configuration
unlock conditions
optimal moves
star thresholds
seed
```

The game must be data-driven.

## Priority Order

P0:
- Core sorting.
- Save/resume.
- Undo.
- Hint.
- Shuffle.
- Level completion.
- Star scoring.

P1:
- Hidden Back Row.
- Moving Bottom Tray.
- Locked Items.
- Sliding Shelves.
- Dynamic tutorial.

P2:
- Mystery Boxes.
- Stacked Items.
- Conveyor.
- Rotating Tray.

P3:
- Frozen Items.
- Moving Divider.
- Chain Release.
- Advanced combinations.

## Quality Bar

The final product should not look like a basic clone.

It should compete visually with top casual puzzle games through:
- Strong 3D art.
- Premium lighting.
- Responsive animation.
- ASMR-grade sound.
- Clear UX.
- Dynamic mechanics.
- Theme progression.
- Fair monetization.

The UI must never overwhelm the player. Dynamic mechanics should make the board more interesting, not visually confusing.

## Cursor AI Development Rules

1. Keep gameplay systems modular.
2. Do not put all gameplay logic into one monolithic script.
3. Keep each mechanic in its own class/module.
4. Use JSON for level configuration.
5. Use ScriptableObjects or equivalent configuration assets where useful.
6. Separate game state from visual presentation.
7. Build save/load support before adding advanced mechanics.
8. Test each mechanic independently.
9. Test mechanic combinations.
10. Validate level solvability.
11. Never hardcode level-specific logic into the core game controller.
12. Keep all UI text localized.
13. Support Android 8.0+.
14. Optimize for mid-range Android devices.
15. Maintain 60 FPS target on supported hardware.
16. Never introduce forced interstitial ads during active gameplay.
17. Never require payment to complete a level.
18. Never allow a dynamic mechanic to create an unavoidable dead end unless the level explicitly provides a free recovery route.
19. Every new mechanic must have a first-use tutorial.
20. Every level must be recoverable after app force-close.

## Definition of Done for a Dynamic Mechanic

A mechanic is production-ready only when:

- It works on Android.
- It has a visual state.
- It has animation.
- It has sound.
- It has haptic feedback where appropriate.
- It supports save/load.
- It supports reset.
- It supports pause/resume.
- It supports accessibility.
- It is localized.
- It has analytics events.
- It has unit tests.
- It has at least 5 authored levels.
- It has been tested in combination with at least one existing mechanic.
- It cannot create an unsolvable state due to implementation bugs.

---

# APPENDIX E. FINAL PRODUCT DESIGN NORTH STAR

The experience should feel like:

> **"A relaxing organizing game that constantly surprises me with clever new ways to sort."**

Not:

> "The same shelf puzzle repeated 250 times."

Every 10–25 levels, players should feel that the game has evolved.

Every 25 levels, players should feel that they entered a new world.

Every Boss should feel like a celebration of mechanics the player has already mastered.

The combination of:
- 3D object satisfaction,
- ASMR audio,
- dynamic level mechanics,
- theme-based progression,
- Mia's light story,
- fair monetization,
- and high-quality UI

is the core competitive advantage of ShelfSort Master.
