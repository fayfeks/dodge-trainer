// All gameplay constants live here. Tune freely.

export const CONFIG = {
  // Design resolution (16:9 landscape). Phaser letterboxes this into any window.
  arena: {
    width: 1280,
    height: 720,
    margin: 0,             // gap between arena border and canvas edge (px)
    bgColor: 0x0e1420,
    borderColor: 0x2a3a52,
    borderWidth: 3,
  },

  // Procedural ground-plane background (no image assets needed).
  background: {
    enabled: true,
    // Base fill of the whole canvas behind the arena.
    outerColor: 0x05070c,
    // Two-tone radial-ish feel: arena floor + darker vignette toward edges.
    floorColor: 0x111a2b,
    vignetteColor: 0x070b12,
    vignetteAlpha: 0.55,
    // Grid lines drawn on the arena floor to sell the top-down view.
    gridEnabled: true,
    gridSize: 64,            // spacing between grid lines (px)
    gridColor: 0x1e2c44,
    gridAlpha: 0.6,
    gridWidth: 1,
  },

  player: {
    radius: 18,
    moveSpeed: 300,        // px per second, constant
    stopDistance: 2,       // snap to destination when closer than this (px)
    color: 0x4fc3f7,
    outlineColor: 0xbde7ff,
    // Fake-perspective drop shadow under the champion dot
    shadowSquash: 0.45,    // ellipse height = width * squash
    shadowAlpha: 0.35,
    shadowOffsetY: 10,
  },

  // Right-click move confirmation: center dot + ring that ripples outward
  moveMarker: {
    color: 0x8fd3ff,
    dotRadius: 4,          // center dot, shrinks to nothing
    ringStartRadius: 4,    // ring grows from this...
    ringEndRadius: 18,     // ...to this
    ringWidth: 2,
    squash: 0.5,           // ground-plane squash (height = width * squash)
    duration: 400,         // ms until it fades out
  },

  // --- Menus (main menu + difficulty select) ---
  menu: {
    bgColor: 0x05070c,       // solid backdrop behind menu screens
    titleColor: '#8fd3ff',
    subtitleColor: '#6f89a8',
    textColor: '#cfe4ff',
    buttonColor: 0x1b2740,
    buttonHoverColor: 0x2a3f66,
    buttonTextColor: '#e8f2ff',
  },

  // --- Skillshots: bolt (travelling ball, no telegraph) ---
  // Speed/aim come from the chosen difficulty; visuals live here.
  bolt: {
    radius: 15,              // hitbox + draw radius of the travelling bolt
    color: 0xff5a4f,         // core of the bolt
    glowColor: 0xffb3ad,     // outline/glow
  },

  // --- Skillshots: beam (thin red telegraph -> instant fat white beam) ---
  // A thin warning line shows, then 1s later a 3x-thick white beam snaps onto
  // the same axis, deals damage instantly (no travel), and vanishes.
  beam: {
    telegraphWidth: 7.5,      // thickness of the thin warning line (px)
    telegraphColor: 0xe01414, // vivid red, not a light/pink red
    telegraphAlpha: 0.85,
    telegraphDuration: 1000,  // ms the warning shows before the beam fires
    widthMultiplier: 5,       // beam thickness = telegraphWidth * this
    beamColor: 0xffffff,      // white ray
    beamAlpha: 0.9,
    activeDuration: 500,      // ms the beam stays (fading out) before vanishing
    damageWindow: 80,         // ms after firing during which the beam can hit;
                              // the remaining fade is purely cosmetic (no damage)
  },

  // Where skillshots originate: just outside a random point on the arena edge.
  spawner: {
    edgeInset: 40,           // how far outside the arena border to spawn (px)
    beamChance: 0.1,         // fraction of spawns that are beams (rest are bolts)
  },

  // Difficulty presets. Selected on the difficulty screen; the active one is
  // read at runtime by the spawner and skillshots.
  difficulties: {
    easy: {
      label: 'EASY',
      spawnInterval: 1400,     // ms between skillshot spawns
      spawnIntervalMin: 700,   // fastest spawn rate after ramping
      rampPerSecond: 8,        // ms shaved off the interval each survived second
      projectileSpeed: 300,    // px/s the bolt travels
      aimJitterDeg: 7,         // max random aim offset left/right of the player
    },
    normal: {
      label: 'NORMAL',
      spawnInterval: 1000,
      spawnIntervalMin: 480,
      rampPerSecond: 12,
      projectileSpeed: 400,
      aimJitterDeg: 10,
    },
    hard: {
      label: 'HARD',
      spawnInterval: 650,
      spawnIntervalMin: 320,
      rampPerSecond: 16,
      projectileSpeed: 500,
      aimJitterDeg: 14,
    },
  },
};
