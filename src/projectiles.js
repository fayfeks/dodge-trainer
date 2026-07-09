import { CONFIG } from './config.js';

// Length long enough to cross the arena from any edge point along any angle.
const REACH = CONFIG.arena.width + CONFIG.arena.height;

// A bolt skillshot: no telegraph. Fires immediately from its spawn point and
// travels in a straight line until it leaves the arena. Hits the player if the
// travelling bolt overlaps the player's body.
export class BoltSkillshot {
  // x, y  -> spawn point (just outside the arena edge)
  // angle -> travel direction in radians (already aim-jittered by spawner)
  // diff  -> the active difficulty preset (projectile speed)
  constructor(scene, x, y, angle, diff) {
    this.x = x;
    this.y = y;
    this.angle = angle;
    this.speed = diff.projectileSpeed;
    this.dead = false;

    const s = CONFIG.bolt;
    this.bolt = scene.add.circle(x, y, s.radius, s.color);
    this.bolt.setStrokeStyle(2, s.glowColor);
  }

  update(delta) {
    if (this.dead) return;
    const step = this.speed * (delta / 1000);
    this.x += Math.cos(this.angle) * step;
    this.y += Math.sin(this.angle) * step;
    this.bolt.setPosition(this.x, this.y);

    if (this.isOffArena()) this.destroy();
  }

  hits(px, py, playerRadius) {
    if (this.dead) return false;
    const d = Phaser.Math.Distance.Between(this.x, this.y, px, py);
    return d <= playerRadius + CONFIG.bolt.radius;
  }

  isOffArena() {
    const a = CONFIG.arena;
    const pad = CONFIG.spawner.edgeInset + CONFIG.bolt.radius;
    return this.x < -pad || this.y < -pad || this.x > a.width + pad || this.y > a.height + pad;
  }

  destroy() {
    if (this.dead) return;
    this.dead = true;
    this.bolt.destroy();
  }
}

// A beam skillshot: a thin red warning line shows for `telegraphDuration`, then
// a fat white beam snaps onto the exact same axis (centred on the warning) and
// deals damage instantly with no travel. Damage only lands during the brief
// `damageWindow` right after firing; the rest of the fade-out is cosmetic.
export class BeamSkillshot {
  // x, y  -> spawn point (just outside the arena edge)
  // angle -> beam direction in radians (already aim-jittered by spawner)
  constructor(scene, x, y, angle) {
    this.x = x;               // fixed spawn point; the beam never moves
    this.y = y;
    this.angle = angle;
    this.phase = 'telegraph'; // 'telegraph' -> 'active' -> 'dead'
    this.timeLeft = CONFIG.beam.telegraphDuration;
    this.dead = false;
    this.scene = scene;

    const b = CONFIG.beam;

    // Thin warning line, pinned at the spawn point and rotated along the axis.
    this.telegraph = scene.add.rectangle(x, y, REACH, b.telegraphWidth, b.telegraphColor, b.telegraphAlpha);
    this.telegraph.setOrigin(0, 0.5);
    this.telegraph.setRotation(angle);

    this.beam = null;
  }

  update(delta) {
    if (this.phase === 'telegraph') {
      this.timeLeft -= delta;
      if (this.timeLeft <= 0) this.fire();
      return;
    }

    if (this.phase === 'active') {
      this.activeElapsed += delta;
      this.timeLeft -= delta;
      if (this.timeLeft <= 0) this.destroy();
    }
  }

  fire() {
    const b = CONFIG.beam;
    this.telegraph.destroy();
    this.telegraph = null;

    // Fat white beam on the same axis, 3x the telegraph thickness, centred so
    // the earlier thin line sits exactly in its middle third.
    this.beam = this.scene.add.rectangle(
      this.x, this.y, REACH, b.telegraphWidth * b.widthMultiplier, b.beamColor, b.beamAlpha
    );
    this.beam.setOrigin(0, 0.5);
    this.beam.setRotation(this.angle);

    // Fade the beam out over its lifetime instead of a hard cut.
    this.fadeTween = this.scene.tweens.add({
      targets: this.beam,
      alpha: 0,
      duration: b.activeDuration,
      ease: 'Quad.easeIn',
    });

    this.phase = 'active';
    this.timeLeft = b.activeDuration;
    this.activeElapsed = 0;   // time since the beam appeared (drives damage window)
  }

  hits(px, py, playerRadius) {
    // Only lands in the brief window right after firing, never during the fade.
    if (this.phase !== 'active' || this.activeElapsed > CONFIG.beam.damageWindow) return false;

    // Perpendicular distance from the player to the beam's axis line.
    const dx = Math.cos(this.angle);
    const dy = Math.sin(this.angle);
    const rx = px - this.x;
    const ry = py - this.y;

    if (rx * dx + ry * dy < 0) return false; // behind the spawn point
    const perp = Math.abs(rx * -dy + ry * dx);
    const halfWidth = (CONFIG.beam.telegraphWidth * CONFIG.beam.widthMultiplier) / 2;
    return perp <= halfWidth + playerRadius;
  }

  destroy() {
    if (this.dead) return;
    this.dead = true;
    this.phase = 'dead';
    if (this.fadeTween) this.fadeTween.remove();
    if (this.telegraph) this.telegraph.destroy();
    if (this.beam) this.beam.destroy();
  }
}
