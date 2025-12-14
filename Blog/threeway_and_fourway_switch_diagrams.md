---
layout: default
title: 3-Way and 4-Way Switch Wiring Diagrams (with Neutral in Every Box)
---

# 3-Way and 4-Way Switch Wiring Diagrams (with Neutral in Every Box)

Why build another electrical diagram?

When wiring 3-way and 4-way switch circuits, it's important to include a neutral in every box for smart-switch compatibility. This is not always intuitive when working from existing diagrams which may be older or not designed with neutrals in mind everywhere.

Also, many of the diagrams I found use pictograms or other non-text-based formats that are not easily searchable or accessible. I wanted to create a set of diagrams that are text-based and easy to understand.

If you have feedback or suggestions, please reach out to me on [LinkedIn](https://www.linkedin.com/in/leonletto/) or [GitHub](https://github.com/leonletto).

## Scenario 1: Switch in one box and light in another

### 1. Clean 3-way wiring diagram (neutral in BOTH boxes)

This is the **recommended modern NEC-compliant pattern**.

Switch A is the line-side 3-way (power enters here); Switch B is the load-side 3-way (light is fed from here).”

#### Cable layout (important first)

* **Power → Switch 1**: 14-2 (hot + neutral)
* **Switch 1 → Switch 2**: 14-3 (two travelers + neutral)
* **Switch 2 → Lights**: 14-2 (switched hot + neutral)

#### Functional wiring

```ascii
POWER (Hot + Neutral)
        |
        v
+------------------+
|  3-WAY SWITCH A  |
|                  |
|  Common: LINE    |
|  Traveler 1 ---- red -----------------------------+
|  Traveler 2 ---- black -----------------------+|  +
|  Neutral  ------ white ------------------|----+|  +
+------------------+                       |    +|  +
                                           |    +|  +
                                     +-----|----+|--+---------------------------+
                                     |  3-WAY SWITCH B                          |
                                     |                                          |
                                     |  Traveler 1 ---- red                     |
                                     |  Traveler 2 ---- black                   |
                                     |  Common: LOAD ---+-----> Switched Hot --- black ---> Lights
                                     |  Neutral -------------------------------- white ---> Lights
                                     +------------------------------------------+

LOAD / SWITCH BOX TERMINAL MAPPING:
(Brass screws = travelers, black screw = common)

Common (black screw): LINE hot (black from feed 14/2)

Traveler screws (brass):
  • red (14/3)   → traveler 1 to switch B
  • black (14/3) → traveler 2 to switch B

Neutral:
  • white (14/3)  → spliced together with wirenut joiner (not on switch unless smart)

Ground (green screw):
  • bare ground

LIGHT / SWITCH B TERMINAL MAPPING:
(Brass screws = travelers, black screw = common)

Common (black screw): switched hot to lights (black from switch B)

Traveler screws (brass):
  • red (14/3)   → traveler 1 from switch A
  • black (14/3) → traveler 2 from switch A

Neutral:
  • white (14/3)  → to lights with wirenut joiner use (not on switch unless smart)

Ground (green screw):
  • bare ground
```

Description:

* Neutral in every box (load / switch box + outboard far 3-way)
* Only hot is switched
* Smart-switch compatible
* Matches your original intent

Neutral handling **(important)**:

* Neutral is **spliced straight through every box - wirenutted**
* It is **not landed** on 3-way terminals
* Still available for smart switches or future code changes

---

### 3. Extending this to a 4-way switch (still neutral everywhere)

Now the nice part: **nothing fundamental changes**.

A 4-way switch **only lives between the two 3-ways**, and it *only touches travelers*.

#### Cable layout (3 switches)

```text
Power → 3-Way A → 4-Way → 3-Way B → Lights
```

Cabling:

* Power → 3-Way A: **14-2**
* 3-Way A → 4-Way: **14-3**
* 4-Way → 3-Way B: **14-3**
* 3-Way B → Lights: **14-2**

#### Wiring logic

```ascii
POWER (Hot + Neutral)
        |
        v
+------------------+
|  3-WAY SWITCH A  |
|                  |
|  Common: LINE    |
|  Traveler 1 ---- red -----------------------------+
|  Traveler 2 ---- black -----------------------+|  +
|  Neutral  ------ white ------------------|----+|  +
+------------------+                       |    +|  +
                                           |    +|  +
                                     +-----|----+|--+-----------------------------+
                                     |  4-WAY SWITCH                              |
                                     |                                            |
                                     |  IN:  Traveler 1 ---- black (14/3)         |
                                     |  IN:  Traveler 2 ---- red (14/3)           |
                                     |       (4-way X / || crossover)             |
                                     |  OUT: Traveler 1 ---- black (14/3)         |
                                     |  OUT: Traveler 2 ---- red (14/3)           |
                                     |  Neutral: white passes through with joiner |
                                     +--------------------------------------------+
                                           |    +|  +
                                     +-----|----+|--+---------------------------+
                                     |  3-WAY SWITCH B                          |
                                     |                                          |
                                     |  Traveler 1 ---- red                     |
                                     |  Traveler 2 ---- black                   |
                                     |  Common: LOAD ---+-----> Switched Hot --- black ---> Lights
                                     |  Neutral -------------------------------- white ---> Lights
                                     +------------------------------------------+

LOAD / SWITCH BOX TERMINAL MAPPING:
(Brass screws = travelers, black screw = common)

Common (black screw): LINE hot (black from feed 14/2)

Traveler screws (brass):
  • red (14/3)   → traveler 1 to switch B
  • black (14/3) → traveler 2 to switch B

Neutral:
  • white (14/2)  → spliced together with wirenut joiner (not on switch unless smart)

Ground (green screw):
  • bare ground

4-WAY SWITCH TERMINAL MAPPING:
(All screws are travelers)

Traveler IN pair (from 3-way A):
  • red (14/3)
  • black (14/3)

Traveler OUT pair (to 3-way B):
  • red (14/3)
  • black (14/3)

Neutral:
  • white (14/2)  → spliced together with wirenut joiner (not on switch unless smart)

Ground (green screw):
  • bare ground

LIGHT / SWITCH B TERMINAL MAPPING:
(Brass screws = travelers, black screw = common)

Common (black screw): switched hot to lights (black from switch B)

Traveler screws (brass):
  • red (14/3)   → traveler 1 from switch A
  • black (14/3) → traveler 2 from switch A

Neutral:
  • white (14/2)  → to lights with wirenut joiner use (not on switch unless smart))

Ground (green screw):
  • bare ground
```

Description:

* Neutral in every box (load / switch box + 4-way + outboard far 3-way)
* Matches NEC post-2011 intent
* Fully smart-switch compatible
* Scales cleanly to 5-way / 6-way (just repeat the 4-way block)

Neutral handling **(important)**:

* Neutral is **spliced straight through every box - wirenutted**
* It is **not landed** on 4-way terminals
* Still available for smart switches or future code changes

---

### 4. Why this is the *correct* solution for todays state of the electrical code

Modern code generally expects a neutral available in most switch boxes (with exceptions). These diagrams
intentionally include a neutral in every box for smart-switch compatibility.

This topology is:

* ✅ NEC 2011+ compliant
* ✅ Smart-switch safe
* ✅ Dimmer compatible
* ✅ Scales to 5-way, 6-way, etc.
* ✅ Matches commercial wiring practice
* ✅ Avoids switch-loop
* ✅ Avoids re-identification in Scenario 1 to keep things simple

---

## Scenario 2: Switch and light in same box - switch in another box - (neutral in BOTH boxes)

This requires a **switch loop** meaning each outboard box requires two NM cables:

* 14/3 for travelers + remote common return (white is re-marked hot)
* 14/2 to ensure a neutral in the outboard box

This is the only practical way using common NM (14/2 + 14/3) while keeping a neutral in the outboard box.

NOTE: If you have access to (14/4) cable, you can use that instead to avoid the switch loop. Its hard to find in the market and I usually only find it in "control" cable - stranded without the normal ground.   Thats why I didn't include it in the diagrams.

It requires a switch loop and re-identification.

Extra notes and warnings are included below.

### 1. Clean 3-way wiring diagram - switch loop

#### Cable layout

```ascii
POWER (Hot + Neutral)
        |
        v
+--------------------------------------+
|  LOAD / SWITCH BOX                   |
|  (Light + 3-WAY Switch A)            |
|                                      |
|  Common: LINE  <--- hot (black 14/2) |
|  Traveler 1 ---- black (14/3) -----------------------------------------------+
|  Traveler 2 ---- red (14/3) -----------------------------------------+|      +
|  Neutral  ------ white (14/2) ----------------------------------|----+|      +
|             |                        |                          |    +|      +
|             |----------- white -------------> Lights            |    +|      +
|  Hot: |---Hot Return wirenutted to black ---> Lights            |    +|      +
+------ | -----------------------------+                          |    +|      +
        |                                                         |    +|      +
        | (Switched Hot Return - re-identified black)       +-----|----+|------+---------------------+
        |                                                   |  3-WAY SWITCH B (Outboard Box)         |
        |                                                   |                                        |
        |                                                   |  Traveler 1 ---- black (14/3)          |
        |                                                   |  Traveler 2 ---- red (14/3)            |
        +<--------- white* (14/3) --------------------------|  Common: RETURN - white* (14/3)        |
                                                            |  Neutral ------- white (14/2) capped   |
                                                            +----------------------------------------+

        * white in the 14/3 is NOT neutral — it is re-identified as HOT (common return)

LOAD / SWITCH BOX TERMINAL MAPPING:
(Brass screws = travelers, black screw = common)

Common (black screw): LINE hot (black from feed 14/2)

Traveler screws (brass):
  • black (14/3) → traveler 1 to Switch B
  • red (14/3)   → traveler 2 to Switch B

Neutral:
  • NOT connected to switch
  • Spliced: feed white + light white + (14/2) white to Switch B

Ground (green screw):
  • bare ground

OUTBOARD 3-WAY SWITCH B TERMINAL MAPPING:
(Brass screws = travelers, black screw = common)

Common (black screw): white* (14/3) re-identified HOT (common return to light)

Traveler screws (brass):
  • black (14/3) → traveler 1 from Switch A
  • red (14/3)   → traveler 2 from Switch A

Neutral:
  • white (14/2) present in box
  • capped / parked (or used for smart switch)

Ground (green screw):
  • bare ground

LIGHT (in Load/Switch Box) TERMINAL MAPPING:

Hot:
  • white* (14/3) ← switched hot return from Switch B

Neutral:
  • white (14/2 feed)

Ground:
  • bare ground

COLOR USE REMINDER (critical):

14/3 white = HOT (re-identified with tape or marker)
14/2 white = NEUTRAL (never on a switch terminal)

```

NOTE: Each outboard box requires two NM runs: 14/3 for travelers+return and 14/2 for neutral.

Description:

* Neutral in every box (load / switch box + outboard far 3-way)
* Matches NEC post-2011 intent
* Fully smart-switch compatible
  
Neutral handling **(important)**:

* Neutral is **running on separate 14/2 and spliced through every box**
* It is **not landed** on 3-way terminals
* Still available for smart switches or future code changes

Hot/white re-identification **(important)**:

* White in 14/3 is re-identified as HOT (common return) everywhere
* It is marked with black tape or a permanent marker
* It is **not** neutral
* It is **only** landed on Common (black screw) on 3-way switch B
* It is **not** used for smart switches or dimmers

### 2. Extending this to a 4-way switch (still neutral everywhere)

Again: **nothing fundamental changes**.

A 4-way switch **only lives between the two 3-ways**, and it *only touches travelers*.

Neutral is present in every box and passes straight through 4-way with a wirenut joiner.

Hot/white re-identification happens everywhere and passes through the 4-way with a wirenut joiner.

#### Cable layout (3 switches) - power and load in same box

```ascii
LOAD / SWITCH BOX (3-WAY A + LIGHT)
   |
   |-- 14/3 (travelers) + 14/2 (neutral)
   v
OUTBOARD BOX #1 (4-WAY)
   |
   |-- 14/3 (travelers) + 14/2 (neutral)
   v
OUTBOARD BOX #2 (3-WAY B)
```

* 14/3: black + red = travelers, white* = switched-hot return
* 14/2: white = neutral (always unswitched)
* white in 14/3 is re-identified HOT

#### Functional wiring diagram

```ascii
POWER (Hot + Neutral)
        |
        v
+--------------------------------------+
|  LOAD / SWITCH BOX                   |
|  (Light + 3-WAY Switch A)            |
|                                      |
|  Common: LINE  <--- hot (black 14/2) |
|  Traveler 1 ---- black (14/3) -----------------------------------------------+
|  Traveler 2 ---- red (14/3) -----------------------------------------+|      +
|  Neutral  ------ white (14/2) ----------------------------------|----+|      +
|             |                        |                          |    +|      +
|             |----------- white -------------> Lights            |    +|      +
|  Hot: |---Hot Return wirenutted to black ---> Lights            |    +|      +
+------ | -----------------------------+                          |    +|      +
        |                                                         |    +|      +
        | (Switched Hot Return - re-identified black)       +-----|----+|------+---------------------+
        |                                                   |  4-WAY SWITCH (Outboard Box #1)        |
        |                                                   |                                        |
        |                                                   |  IN:  Traveler 1 ---- black (14/3)     |
        |                                                   |  IN:  Traveler 2 ---- red (14/3)       |
        |                                                   |       (4-way X / || crossover)         |
        |                                                   |  OUT: Traveler 1 ---- black (14/3)     |
        |                                                   |  OUT: Traveler 2 ---- red (14/3)       |
        |                                                   |                                        |
        |<--------- white* (14/3) -----------|---- Switched-hot return (white* 14/3) spliced through | 
                                             |              |  Neutral: white (14/2) spliced through  ------|
                                             |              +----------------------------------------+      |
                                             |                    |    +|      +                            |
                                             |              +-----|----+|------+---------------------+      |
                                             |              |  3-WAY SWITCH B (Outboard Box #2)      |      |
                                             |              |                                        |      |
                                             |              |  Traveler 1 ---- black (14/3)          |      |
                                             |              |  Traveler 2 ---- red (14/3)            |      |
                                             |---------------  Common: RETURN - white* (14/3)        |      |
                                                            |  Neutral ------- white (14/2) capped ---------|
                                                            +----------------------------------------+

        * white in the 14/3 is NOT neutral — it is re-identified as HOT (common return)

LOAD / SWITCH BOX TERMINAL MAPPING:
(Brass screws = travelers, black screw = common)

(3-WAY A + Light + Feed)

Common (black screw): LINE hot (black from feed 14/2)

Traveler screws (brass):
  • black (14/3) → traveler to 4-way
  • red (14/3)   → traveler to 4-way

Neutral:
  • NOT on switch
  • Splice: feed white + light white + (14/2) white to Box #1

Switched Hot:
  • light hot + (14/3) white* (return from Box #1 / 3-way B in Box #2)

Ground (green screw):
  • all bare grounds tied + switch yoke

OUTBOARD BOX #1 TERMINAL MAPPING:

(4-WAY SWITCH)
(All screws are travelers)

Traveler IN (pair):
  • black (14/3) from Box A
  • red (14/3)   from Box A

Traveler OUT (pair):
  • black (14/3) to Box B
  • red (14/3)   to Box B

Neutral:
  • (14/2) white present
  • spliced THROUGH (or used for smart switch)

Switched-hot return:
  • (14/3) white* spliced THROUGH (not landed) re-identified HOT 

Ground (green screw):
  • bare ground + yoke

OUTBOARD BOX #2 TERMINAL MAPPING:
(Brass screws = travelers, black screw = common)

(3-WAY SWITCH B)

Common (black screw): white* (14/3) re-identified HOT (switched-hot return to light via Box #1 )

Traveler screws (brass):
  • black (14/3) → traveler from 4-way
  • red (14/3)   → traveler from 4-way

Neutral:
  • (14/2) white present
  • capped / parked (or smart switch)

Ground (green screw):
  • bare ground + yoke

LIGHT (in Load/Switch Box) TERMINAL MAPPING:

Hot:
  • white* (14/3) ← switched hot return re-identified HOT wirenutted to black

Neutral:
  • white wirenutted to (14/2) feed + (14/2) white from Box #1

Ground:
  • bare

COLOR USE REMINDER (critical):

14/3 white = HOT (re-mark all ends)
14/2 white = NEUTRAL (never on a switch terminal)
4-way switch never sees line, load, or neutral — travelers only
```

NOTE: Each outboard box requires two NM runs: 14/3 for travelers+return and 14/2 for neutral.

Description:

* Neutral in every box (load, 4-way, far 3-way)
* Matches NEC post-2011 intent
* Fully smart-switch compatible
* Scales cleanly to 5-way / 6-way (just repeat the 4-way block)

Neutral handling **(important)**:

* Neutral is **running on separate 14/2 and spliced through every box**
* It is **not landed** on 3-way terminals
* Still available for smart switches or future code changes

Hot/white re-identification **(important)**:

* White in the 14/3 is re-identified as HOT (common return).
* It is landed only on the COMMON (black screw) of the far 3-way switch and is spliced through all other boxes.
* It is never used as a neutral.
