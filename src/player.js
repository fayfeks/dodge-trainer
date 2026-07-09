import { CONFIG } from './config.js';

export class Player {
  constructor(scene, x, y) {
    this.scene = scene;
    this.x = x;
    this.y = y;
    this.target = null; // {x, y} or null when standing still
    this.blinkCooldownLeft = 0; // ms remaining before blink is ready again

    const p = CONFIG.player;

    this.shadow = scene.add.ellipse(
      x,
      y + p.shadowOffsetY,
      p.radius * 2.2,
      p.radius * 2.2 * p.shadowSquash,
      0x000000,
      p.shadowAlpha
    );

    this.body = scene.add.circle(x, y, p.radius, p.color);
    this.body.setStrokeStyle(2, p.outlineColor);
  }

  // Cancel the current move order; stand still until a new one is given.
  stop() {
    this.target = null;
  }

  moveTo(x, y) {
    const a = CONFIG.arena;
    const r = CONFIG.player.radius;
    this.target = {
      x: Phaser.Math.Clamp(x, a.margin + r, a.width - a.margin - r),
      y: Phaser.Math.Clamp(y, a.margin + r, a.height - a.margin - r),
    };
  }

  // Teleport `blink.distance` px toward (tx, ty), clamped to the arena.
  // Returns true if it fired, false if still on cooldown.
  blink(tx, ty) {
    if (this.blinkCooldownLeft > 0) return false;

    const a = CONFIG.arena;
    const r = CONFIG.player.radius;
    const angle = Phaser.Math.Angle.Between(this.x, this.y, tx, ty);

    // Flash toward the cursor, but no farther than the cursor itself.
    const dist = Math.min(
      CONFIG.blink.distance,
      Phaser.Math.Distance.Between(this.x, this.y, tx, ty)
    );

    this.x = Phaser.Math.Clamp(
      this.x + Math.cos(angle) * dist,
      a.margin + r, a.width - a.margin - r
    );
    this.y = Phaser.Math.Clamp(
      this.y + Math.sin(angle) * dist,
      a.margin + r, a.height - a.margin - r
    );

    // Keep the current move order so we walk on toward it after the blink.
    this.blinkCooldownLeft = CONFIG.blink.cooldown;
    return true;
  }

  update(delta) {
    if (this.blinkCooldownLeft > 0) {
      this.blinkCooldownLeft = Math.max(0, this.blinkCooldownLeft - delta);
    }

    if (this.target) {
      const p = CONFIG.player;
      const dist = Phaser.Math.Distance.Between(this.x, this.y, this.target.x, this.target.y);
      const step = p.moveSpeed * (delta / 1000);

      if (dist <= Math.max(step, p.stopDistance)) {
        this.x = this.target.x;
        this.y = this.target.y;
        this.target = null;
      } else {
        const angle = Phaser.Math.Angle.Between(this.x, this.y, this.target.x, this.target.y);
        this.x += Math.cos(angle) * step;
        this.y += Math.sin(angle) * step;
      }
    }

    this.body.setPosition(this.x, this.y);
    this.shadow.setPosition(this.x, this.y + CONFIG.player.shadowOffsetY);
  }
}
