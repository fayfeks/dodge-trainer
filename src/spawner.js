import { CONFIG } from './config.js';
import { BoltSkillshot, BeamSkillshot } from './projectiles.js';

// Drives skillshot spawning: picks a random point just outside the arena,
// aims it at the player with a bit of left/right jitter, and ramps the spawn
// rate up the longer the player survives.
export class Spawner {
  constructor(scene, player, diff) {
    this.scene = scene;
    this.player = player;
    this.diff = diff;

    this.shots = [];
    this.timeAlive = 0;        // seconds survived, drives the ramp
    this.sinceLastSpawn = 0;   // ms since the previous spawn
    this.dodged = 0;           // shots that expired without hitting the player
  }

  update(delta) {
    this.timeAlive += delta / 1000;
    this.sinceLastSpawn += delta;

    if (this.sinceLastSpawn >= this.currentInterval()) {
      this.sinceLastSpawn = 0;
      this.spawnOne();
    }

    for (const shot of this.shots) shot.update(delta);

    // A shot that died this frame left the arena without hitting = a dodge.
    // (A shot that hits ends the run, so it never gets counted here.)
    for (const shot of this.shots) {
      if (shot.dead && !shot.counted) {
        shot.counted = true;
        this.dodged++;
      }
    }
    this.shots = this.shots.filter((s) => !s.dead);
  }

  // Interval shrinks with survival time, floored at the difficulty minimum.
  currentInterval() {
    const d = this.diff;
    const ramped = d.spawnInterval - this.timeAlive * d.rampPerSecond;
    return Math.max(d.spawnIntervalMin, ramped);
  }

  spawnOne() {
    const origin = this.randomEdgePoint();

    // Aim at the player, then nudge left/right so shots don't perfectly track.
    const toPlayer = Phaser.Math.Angle.Between(
      origin.x, origin.y, this.player.x, this.player.y
    );
    const jitter = Phaser.Math.DegToRad(
      Phaser.Math.FloatBetween(-this.diff.aimJitterDeg, this.diff.aimJitterDeg)
    );
    const angle = toPlayer + jitter;

    const shot = Math.random() < CONFIG.spawner.beamChance
      ? new BeamSkillshot(this.scene, origin.x, origin.y, angle)
      : new BoltSkillshot(this.scene, origin.x, origin.y, angle, this.diff);

    this.shots.push(shot);
  }

  // A random point just outside one of the four arena edges.
  randomEdgePoint() {
    const a = CONFIG.arena;
    const inset = CONFIG.spawner.edgeInset;
    const side = Phaser.Math.Between(0, 3);

    switch (side) {
      case 0: // top
        return { x: Phaser.Math.Between(0, a.width), y: -inset };
      case 1: // bottom
        return { x: Phaser.Math.Between(0, a.width), y: a.height + inset };
      case 2: // left
        return { x: -inset, y: Phaser.Math.Between(0, a.height) };
      default: // right
        return { x: a.width + inset, y: Phaser.Math.Between(0, a.height) };
    }
  }

  // Has any active bolt reached the player?
  checkHit() {
    for (const shot of this.shots) {
      if (shot.hits(this.player.x, this.player.y, CONFIG.player.radius)) {
        return true;
      }
    }
    return false;
  }

  destroy() {
    for (const shot of this.shots) shot.destroy();
    this.shots = [];
  }
}
