# ShelfSort Master — Deep ASO Research Report (Google Play)

**Research date:** 9 Sep 2026 (live Google Play Store checks, US locale `hl=en&gl=US`)  
**Product researched:** Your Flutter app — 3D shelf / cabinet **goods triple-match** sorting puzzle (replica gameplay of *Goods Puzzle: Sort Challenge™*)  
**Goal:** Maximize organic visibility + conversion toward **1M downloads in ~3 months**

> **Honesty first (no assumptions):**  
> No store listing can make downloads “100% guaranteed.” Google Play ranking + installs depend on **metadata + creatives + retention + reviews + updates + paid UA**.  
> In this niche, apps that hit **1M+** almost always combine strong ASO **with** paid user acquisition. This document places your app where the **highest-download competitors actually sit**, and gives metadata proven by live Store search results.

---

## 1. What this game actually is (from your repo)

| Fact | Source |
|------|--------|
| Internal title today | `ShelfSort Master` (`lib/main.dart`) |
| Genre mechanic | Depth stacks on shelves → move fronts to empty columns → **match 3 identical fronts** → clear |
| Closest market clone | [Goods Puzzle: Sort Challenge™](https://play.google.com/store/apps/details?id=com.fc.goods.sort.matching.puzzle.triplemaster) (FALCON GAMES) |
| Monetization already in code | Ads + IAP + analytics + local notifications |

**Market name for this subgenre:** *Goods Sort / Goods Puzzle / 3D Sorting / Triple Match Goods* — **not** water sort, cake sort, or tile match 3D (those are adjacent but different SERPs).

---

## 2. Live competitor map (Play Store, verified)

### 2.1 Million-download cluster (same / near-exact mechanic)

| App title (live) | Developer | Downloads | Rating | Reviews | Package / link |
|------------------|-----------|-----------|--------|---------|----------------|
| **Goods Sort™ - Sorting Games** | Shinrays Games | **50M+** | 4.8 | 506K | `closet.match.pair.matching.games` |
| **Goods Puzzle: Sort Challenge™** | FALCON GAMES | **50M+** | 4.7 | 751K | `com.fc.goods.sort.matching.puzzle.triplemaster` |
| **Goods 3D Sorting: Match Games** | Pleasure City | **10M+** | 4.9 | 283K | `com.sorting.games.match3d.goods.triple.puzzle` |
| **Goods Puzzle: 3D Sorting Games** | Guru Puzzle Game | **10M+** | ~4.9 | 445K | `sorting.games.goods.sort.triple.match3d.puzzle.stuff` |
| **Goods Group™ - Sort Game** | FlyDogGame | **10M+** | — | 81.7K | `com.merge6.mergeremove.goods` |
| **Goods Triple Match: Sorting 3D** | Joymaster | **5M+** | — | 201K | `com.goods.sorting.games.triple.match3d.puzzle` |
| **Super Sort ® - Goods Puzzle** | Peak Plus | **1M+** | — | 38.2K | `com.supersort.matching.goods.triple.puzzle` |
| **Goods Rush! 3D Sort Puzzle** | Playdayy | **1M+** | — | 162K | `com.triple.match.goods.sort.puzzle.game` |
| **3D Goods Store: Sorting Games** | LifePulse | **1M+** | — | 58.9K | `com.matching.games.goods.sort.triple.puzzle` |
| **Goods Sorting Game** | Veraxen Ltd. | **1M+** | — | 7.44K | `com.veraxen.goodssort` |
| **Goods Challenge - Sort Master** | CLARK STUDIO | **1M+** | — | 38.4K | `com.clarkstudio.an.gs3d` |
| **Goods Jam: Goods Sorting** | iKame / Zego | **1M+** | 4.6 | 95.7K | `com.ig.goods.jam` |

### 2.2 Name collision warning (do not copy your current name)

Live listing already exists:

| Title | Downloads | Rating | Why it matters |
|-------|-----------|--------|----------------|
| **Shelf Sort Master: Goods Match** | **50K+** | 4.3 | Exact brand collision with “ShelfSort Master”. Weak ASO (Casual category, thin short desc). Still blocks clean brand search. |

Also live near-names: *Shelf Sort - Organize & Match*, *Shelf Match 3D: Goods Sort*, *Shelf Sort Puzzle Game*.

**Verdict:** Keep “ShelfSort Master” only as **internal / code** name. **Do not** publish under that Play title.

---

## 3. Best Play Store **placement** (category + tags)

### 3.1 Primary category (mandatory)

**Use: `Puzzle` (`GAME_PUZZLE`)**

Evidence from live listings of million-download clones:

- Sort Challenge → **Puzzle**
- Goods Sort™ → **Puzzle** (+ Pair matching tag)
- Goods 3D Sorting (Pleasure City) → **Puzzle**
- Goods Jam → **Puzzle**
- Nearly every 1M–50M goods-sort title → **Puzzle**

**Do not set primary category to Casual.** Casual appears as a **tag**, not the primary category for winners.

### 3.2 Exact tags winners use (copy this set)

From Falcon / Pleasure City / Shinrays live pages:

| Tag | Why |
|-----|-----|
| **Match 3** | Core mechanic + search affinity |
| **Casual** | Broad discovery |
| **Single player** | Accurate |
| **Stylized** | Visual style filter |
| **Light-hearted** | Mood filter |
| **Shop & supermarket** | Theme affinity (goods / shelves) |
| **Offline** | Strong install conversion for this audience |

Optional if available: pair-matching only if your UI feels more “pair” than triple (yours is triple → prefer **Match 3**).

### 3.3 Content rating

- Target: **Everyone**
- Avoid **Teen** unless assets force it (CLARK’s *Goods Challenge* is Teen + Mild Violence — unnecessary friction for this genre).

### 3.4 Where NOT to place

| Wrong placement | Why |
|-----------------|-----|
| Primary **Casual** only | Winners sit in Puzzle |
| Kids / Family primary | Different policy + creative rules; top goods-sort apps are standard Puzzle |
| Positioning as **Tile Match 3D** / Triple Match 3D (Boombox-style) | Different SERP (`triple match 3d` is dominated by tile find-match, not shelf goods) |
| Positioning as **Water Sort / Cake Sort** | Adjacent “sort” traffic, wrong mechanic → high bounce |

### 3.5 Geographic soft-launch placement (for 1M plan)

Soft-launch first in **high-volume / lower CPI** Android markets, then expand:

1. **India, Indonesia, Brazil, Mexico, Philippines, Turkey, Egypt** (scale installs)  
2. Then **US / UK / DE / JP / KR** (revenue + chart signal)

This is how mid-tier 1M–10M goods titles typically grow; ASO alone does not create that velocity in a 50M-dominated keyword.

---

## 4. Live keyword SERP findings (US Play search)

### Query: `goods sort`
Top results include: Goods Sort™, Sort Challenge™, Veraxen Goods Sorting, Pleasure City, Guru 3D Sorting, Goods Sort Master, Joymaster Triple Match, Goods Rush, Super Sort, 3D Goods Store, Goods Jam, Goods Challenge…

→ **Highest intent keyword in the niche.** Extremely competitive (50M leaders).

### Query: `sorting games`
Top mixes goods-sort **and** food/color/loop sort. Pleasure City + Falcon rank #1–#2 among goods titles.

→ High volume, broader competition.

### Query: `goods puzzle`
Dominated by Falcon Sort Challenge, Guru, Flyfox, Pleasure City, etc.

→ Strong intent, brand-heavy.

### Query: `goods sort puzzle`
Falcon #1, then Goods Rush, Pleasure City, Guru, Veraxen, Super Sort, Joymaster…

→ Best **compound** keyword for a new listing (matches mechanic + genre words).

### Query: `triple match 3d`
Mostly **tile** match games (Boombox, LIHUHU, etc.) — **not** your primary SERP.

→ Use “triple match” in description, **not** as title-only strategy.

### Query: `organize games`
Mix of tidy/home organize + goods sort. Falcon & Pleasure City still appear early.

→ Secondary long-tail for short/full description.

---

## 5. Best short name (Play title ≤ 30 characters)

### 5.1 Naming pattern of winners

Winning titles almost always pack:

1. **Goods** (must-have head term)  
2. **Sort / Sorting / Puzzle**  
3. **3D** and/or **Match / Triple**  
4. Optional brand separator (`:`, `!`, `®`, `™`)

Examples (live):

- `Goods Sort™ - Sorting Games`
- `Goods Puzzle: Sort Challenge™`
- `Goods Puzzle: 3D Sorting Games`
- `Goods Rush! 3D Sort Puzzle`
- `Super Sort ® - Goods Puzzle`
- `3D Goods Store: Sorting Games`

### 5.2 Rejected names

| Name | Reason |
|------|--------|
| ShelfSort Master | Collides with live *Shelf Sort Master: Goods Match*; missing primary keyword **Goods** |
| Goods Sort™ | Trademarked brand of Shinrays |
| Sort Challenge | Falcon brand association |
| Goods Jam | iKame brand |

### 5.3 Recommended titles (character-counted)

| Rank | Play title (≤30) | Chars | Why |
|------|------------------|-------|-----|
| **#1 BEST** | **Goods Sort: Match Puzzle 3D** | 28 | Hits `goods sort` + `match` + `puzzle` + `3D` — aligns with top SERP `goods sort puzzle` |
| #2 | **Goods Puzzle: 3D Sort Match** | 27 | Mirrors Falcon/Guru “Goods Puzzle” head term |
| #3 | **Goods Sort Puzzle: Match 3D** | 28 | Strong compound for `goods sort puzzle` |
| #4 | **3D Goods Sort: Match Puzzle** | 28 | Leads with 3D (visual differentiator in icon/search) |
| #5 | **Goods Match Sort: 3D Puzzle** | 27 | Emphasizes match mechanic |

### 5.4 Recommended short brand (icon / launcher / UA)

Use a **2-word brand** that still contains the money keyword:

- **Primary brand:** `Goods Sort`
- **Alt brand:** `GoodsMatch` / `SortGoods`

Launcher label can be shorter than Play title (Android icon label truncates). Prefer **Goods Sort**.

### 5.5 Package name (set before first publish — permanent)

Follow competitor package style (keyword-rich, irreversible):

```text
com.<yourstudio>.goods.sort.match.puzzle3d
```

Examples of live patterns:  
`...goods.sort...` · `...triple.match3d.puzzle...` · `sorting.games.goods.sort...`

---

## 6. Short description (≤80 chars) — ready to paste

Play indexes short description heavily. Winners stuff **goods / sort / match / 3D / puzzle / shelves**.

### Primary (recommended) — 79 chars

```text
Sort & match 3 identical goods on shelves! Relaxing 3D goods sort puzzle game.
```

### Alt A — 78 chars

```text
Organize shelves, match triple goods, clear cabinets in this 3D sorting puzzle!
```

### Alt B — 77 chars (closer to Falcon tone)

```text
Drag, rearrange & match goods. Addictive 3D sort puzzle matching game offline!
```

### Live short-desc benchmarks (copied from Store)

| App | Live short description |
|-----|------------------------|
| Sort Challenge | Drag, rearrange, match goods. Discover an addictive sort puzzle matching game |
| Guru 3D Sorting | Enjoy sorting goods! Have fun with addictive match 3 games and 3D sort puzzle! |
| Joymaster | Match sort goods 3d,master market sort,triple match goods puzzle sorting games! |
| Goods Rush | Organize shelves, sort goods, and become a 3D sorting game master! |
| Super Sort | Match 3d goods, enjoy goods sort game! Be a matching master! |
| LifePulse | Supermarket Goods casual time! Sort & Match 3D triple goods, be a Goods Master! |
| Veraxen | Sort and match triple goods! Become a goods sorting master in this 3D match game |
| Goods Jam | Sort, match-3 and master goods jam in 3D goods sorting. |

---

## 7. Full description blueprint (≤4000 chars, indexed)

### Structure used by 10M–50M apps

1. Hook (goods + sort + 3D + shelves + time/relax)  
2. How to play (drag → shelf → match 3 → clear → boosters)  
3. Features bullets (levels, goods types, offline, boosters, free)  
4. Keyword paragraph (natural density — **not** comma spam only)  
5. CTA + Privacy / Terms

### Keyword bank (use naturally; do not dump as a wall)

**Primary:** goods sort, sorting games, goods puzzle, 3D sorting, match 3, triple match, organize shelves  
**Secondary:** sorting puzzle, goods matching, supermarket, cabinet, offline puzzle, brain game, casual puzzle  
**Avoid over-weight:** tile match 3D, water sort, cake sort (wrong intent)

### Ready-to-adapt full description (English)

```text
Get ready to sort goods like never before in this addictive 3D goods sort puzzle!

Organize messy shelves, drag identical items, and match 3 goods to clear every cabinet. If you love sorting games, goods puzzle challenges, and relaxing match-3 brain games, this 3D sorting adventure is for you.

HOW TO PLAY
• Drag front goods onto empty shelf columns
• Match 3 identical goods on one shelf to clear them
• Hidden goods slide forward — plan your moves
• Beat the clock and use boosters when you get stuck
• Unlock new goods, rooms, and harder layouts

FEATURES
• Satisfying 3D goods sorting gameplay
• Hundreds of carefully designed puzzle levels
• Freeze, refresh, hammer & extra shelf boosters
• Offline sorting games — play anywhere
• Free to play with optional extras

Become a goods sorting master. Clear shelves, create combos, and enjoy the most relaxing organize & match puzzle on Google Play.

Download now and start your goods sort challenge!
```

Localize top locales after EN: **ES, PT-BR, ID, HI, TR, AR, DE, FR, JA, KO** (same keyword intent, native phrasing).

---

## 8. Creative / conversion placement (ASO is not text-only)

Million-download goods titles convert with:

| Asset | Winning pattern (observed) |
|-------|----------------------------|
| **Icon** | Bright 3D goods on a shelf/cabinet, high contrast, readable at 48px; avoid tiny text |
| **Feature graphic** | Shelf + match-3 action + readable “Sort Goods / Match 3” |
| **Screenshot 1** | Clearest gameplay (before/after tidy shelf) — first screen sells the download |
| **Trailer** | 15–30s: messy shelf → match 3 → clear → win (Falcon/Shinrays style) |
| **Events** | Seasonal event cards (Falcon: “Golden Fall Festival”; others run tennis/soccer themes) |

Play Console **Store Listing Experiments**: A/B icon + screenshot 1 before scaling UA.

---

## 9. Reality check: 1M downloads in 3 months

### What ASO can do

- Put you in the **correct SERP** (`goods sort`, `goods puzzle`, `sorting games`)
- Raise **conversion rate** from impressions (organic + paid)
- Help you appear in **Similar games** next to Falcon / Shinrays / Pleasure City once you have installs + retention

### What ASO cannot do alone

Hit **1M in 90 days** in a niche owned by **two 50M+ titles** with organic only — not realistic for a new listing.

### Required growth stack (evidence-based)

| Lever | Role |
|-------|------|
| ASO (this doc) | Discovery + CVR |
| **Paid UA** (Google UAC, Meta, TikTok, Unity/ironSource) | Volume to 1M |
| Soft launch CPI markets | Cheap learning |
| D1/D7 retention + rating ≥4.6 | Ranking + Similar apps |
| Weekly content / events | Chart + reinstall |

**Rough Android CPI context (2025–2026 industry benchmarks for casual/puzzle):**  
Tier-1 ~$1.20–$3.50 · LATAM/SEA ~$0.15–$0.60 · India ~$0.08–$0.30.  
Blended path to 1M often means **six figures USD** in UA unless virality/featured placement happens (rare, not controllable).

---

## 10. Final recommended Play Console setup (copy checklist)

| Field | Recommended value |
|-------|-------------------|
| **App name (title)** | `Goods Sort: Match Puzzle 3D` |
| **Short brand** | `Goods Sort` |
| **Short description** | `Sort & match 3 identical goods on shelves! Relaxing 3D goods sort puzzle game.` |
| **Category** | **Puzzle** |
| **Tags** | Match 3, Casual, Single player, Stylized, Light-hearted, Shop & supermarket, Offline |
| **Content rating** | Everyone |
| **Contains ads** | Yes (if ads on) |
| **IAP** | Yes (if shop live) |
| **Package** | `com.<studio>.goods.sort.match.puzzle3d` |
| **Do not publish as** | ShelfSort Master |

### 90-day execution order

1. **Week 0:** Rename listing to recommended title; ship icon/screens/trailer; Puzzle + tags  
2. **Week 1–3:** Soft launch 2–3 low-CPI countries; fix CVR via listing experiments; target D1 ≥30%  
3. **Week 4–8:** Scale UA on creatives that show **shelf match-3** clearly; keep weekly updates  
4. **Week 9–12:** Expand geos; push events; aim Similar-apps adjacency to Falcon/Shinrays  

---

## 11. Research sources (live / primary)

Play Store pages & searches opened during research:

- https://play.google.com/store/apps/details?id=com.fc.goods.sort.matching.puzzle.triplemaster  
- https://play.google.com/store/apps/details?id=closet.match.pair.matching.games  
- https://play.google.com/store/apps/details?id=com.sorting.games.match3d.goods.triple.puzzle  
- https://play.google.com/store/apps/details?id=sorting.games.goods.sort.triple.match3d.puzzle.stuff  
- https://play.google.com/store/apps/details?id=com.goods.sorting.games.triple.match3d.puzzle  
- https://play.google.com/store/apps/details?id=com.triple.match.goods.sort.puzzle.game  
- https://play.google.com/store/apps/details?id=com.matching.games.goods.sort.triple.puzzle  
- https://play.google.com/store/apps/details?id=com.supersort.matching.goods.triple.puzzle  
- https://play.google.com/store/apps/details?id=com.ig.goods.jam  
- https://play.google.com/store/apps/details?id=com.veraxen.goodssort  
- https://play.google.com/store/apps/details?id=com.clarkstudio.an.gs3d  
- https://play.google.com/store/apps/details?id=com.vgdlss.shelf.sort.goods.match  
- Searches: `goods sort`, `sorting games`, `goods puzzle`, `goods sort puzzle`, `triple match 3d`, `organize games`  
- Google Play Console help: title ≤30, short desc ≤80, full desc ≤4000  

---

## 12. One-line decision

**Place the app in Puzzle + Match 3 / Shop & supermarket / Offline, publish as `Goods Sort: Match Puzzle 3D`, and treat paid UA + retention as mandatory for the 1M / 3-month target — ASO maximizes the odds; it does not guarantee the number.**
