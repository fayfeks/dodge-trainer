import { CONFIG } from './config.js';
import { Player } from './player.js';
import { Spawner } from './spawner.js';
import { HUD, makeButton } from './ui.js';

// --- Main menu -------------------------------------------------------------
class MenuScene extends Phaser.Scene {
  constructor() {
    super('menu');
  }

  create() {
    const a = CONFIG.arena;
    const m = CONFIG.menu;

    this.add.rectangle(a.width / 2, a.height / 2, a.width, a.height, m.bgColor);

    this.add.text(a.width / 2, a.height / 2 - 140, 'DODGE TRAINER', {
      fontFamily: 'system-ui, sans-serif',
      fontSize: '64px',
      fontStyle: 'bold',
      color: m.titleColor,
    }).setOrigin(0.5);

    this.add.text(a.width / 2, a.height / 2 - 70, 'Right-click to move. Dodge the skillshots.', {
      fontFamily: 'system-ui, sans-serif',
      fontSize: '22px',
      color: m.subtitleColor,
    }).setOrigin(0.5);

    makeButton(this, a.width / 2, a.height / 2 + 30, 'PLAY', () => {
      this.scene.start('difficulty');
    });
  }
}

// --- Difficulty select -----------------------------------------------------
class DifficultyScene extends Phaser.Scene {
  constructor() {
    super('difficulty');
  }

  create() {
    const a = CONFIG.arena;
    const m = CONFIG.menu;

    this.add.rectangle(a.width / 2, a.height / 2, a.width, a.height, m.bgColor);

    this.add.text(a.width / 2, a.height / 2 - 160, 'SELECT DIFFICULTY', {
      fontFamily: 'system-ui, sans-serif',
      fontSize: '48px',
      fontStyle: 'bold',
      color: m.titleColor,
    }).setOrigin(0.5);

    const keys = Object.keys(CONFIG.difficulties);
    keys.forEach((key, i) => {
      const diff = CONFIG.difficulties[key];
      makeButton(this, a.width / 2, a.height / 2 - 50 + i * 84, diff.label, () => {
        this.scene.start('game', { difficulty: key });
      });
    });

    makeButton(this, a.width / 2, a.height / 2 + 220, 'BACK', () => {
      this.scene.start('menu');
    }, { width: 160, height: 48, fontSize: 20 });
  }
}

// --- Gameplay --------------------------------------------------------------
class GameScene extends Phaser.Scene {
  constructor() {
    super('game');
  }

  init(data) {
    this.difficultyKey = data.difficulty ?? 'normal';
  }

  create() {
    this.input.mouse.disableContextMenu();
    this.drawArena();

    const a = CONFIG.arena;
    this.player = new Player(this, a.width / 2, a.height / 2);

    const diff = CONFIG.difficulties[this.difficultyKey];
    this.spawner = new Spawner(this, this.player, diff);
    this.hud = new HUD(this);
    this.elapsed = 0;
    this.over = false;

    this.input.on('pointerdown', (pointer) => {
      if (pointer.rightButtonDown()) {
        this.player.moveTo(pointer.worldX, pointer.worldY);
        this.showMoveMarker(pointer.worldX, pointer.worldY);
      }
    });

    // Stop in place on S until a new move order is given.
    this.input.keyboard.on('keydown-S', () => {
      if (this.over) return;
      this.player.stop();
    });
  }

  drawArena() {
    const a = CONFIG.arena;
    const bg = CONFIG.background;

    const x = a.margin;
    const y = a.margin;
    const w = a.width - a.margin * 2;
    const h = a.height - a.margin * 2;

    const g = this.add.graphics();

    if (bg.enabled) {
      g.fillStyle(bg.outerColor, 1);
      g.fillRect(0, 0, a.width, a.height);
      g.fillStyle(bg.floorColor, 1);
      g.fillRect(x, y, w, h);

      if (bg.gridEnabled) {
        g.lineStyle(bg.gridWidth, bg.gridColor, bg.gridAlpha);
        for (let gx = x + bg.gridSize; gx < x + w; gx += bg.gridSize) {
          g.lineBetween(gx, y, gx, y + h);
        }
        for (let gy = y + bg.gridSize; gy < y + h; gy += bg.gridSize) {
          g.lineBetween(x, gy, x + w, gy);
        }
      }

      const steps = 6;
      for (let i = 0; i < steps; i++) {
        const inset = (i / steps) * 90;
        g.lineStyle(18, bg.vignetteColor, (bg.vignetteAlpha / steps) * (steps - i));
        g.strokeRect(x + inset, y + inset, w - inset * 2, h - inset * 2);
      }
    } else {
      g.fillStyle(a.bgColor, 1);
      g.fillRect(x, y, w, h);
    }

    // Inset by half the stroke so the full border stays visible at margin 0.
    const hb = a.borderWidth / 2;
    g.lineStyle(a.borderWidth, a.borderColor, 1);
    g.strokeRect(x + hb, y + hb, w - hb * 2, h - hb * 2);
  }

  showMoveMarker(x, y) {
    const m = CONFIG.moveMarker;
    const g = this.add.graphics();

    // Redraw each frame so the ring keeps a constant line width while it grows.
    this.tweens.addCounter({
      from: 0,
      to: 1,
      duration: m.duration,
      ease: 'Cubic.easeOut',
      onUpdate: (tween) => {
        const t = tween.getValue();
        const alpha = 1 - t;
        const r = m.ringStartRadius + (m.ringEndRadius - m.ringStartRadius) * t;
        const d = m.dotRadius * (1 - t);
        g.clear();
        g.fillStyle(m.color, alpha);
        g.fillEllipse(x, y, d * 2, d * 2 * m.squash);
        g.lineStyle(m.ringWidth, m.color, alpha);
        g.strokeEllipse(x, y, r * 2, r * 2 * m.squash);
      },
      onComplete: () => g.destroy(),
    });
  }

  update(time, delta) {
    if (this.over) return;

    this.elapsed += delta / 1000;
    this.player.update(delta);
    this.spawner.update(delta);
    this.hud.update(this.elapsed, this.spawner.dodged);

    if (this.spawner.checkHit()) {
      this.gameOver();
    }
  }

  gameOver() {
    this.over = true;
    this.scene.start('gameover', {
      difficulty: this.difficultyKey,
      time: this.elapsed,
      dodged: this.spawner.dodged,
    });
  }
}

// --- Game over -------------------------------------------------------------
class GameOverScene extends Phaser.Scene {
  constructor() {
    super('gameover');
  }

  init(data) {
    this.result = data;
  }

  create() {
    const a = CONFIG.arena;
    const m = CONFIG.menu;
    const r = this.result;

    this.add.rectangle(a.width / 2, a.height / 2, a.width, a.height, m.bgColor, 0.92);

    this.add.text(a.width / 2, a.height / 2 - 150, 'YOU GOT HIT', {
      fontFamily: 'system-ui, sans-serif',
      fontSize: '56px',
      fontStyle: 'bold',
      color: '#ff7a70',
    }).setOrigin(0.5);

    this.add.text(a.width / 2, a.height / 2 - 60,
      `Survived ${r.time.toFixed(1)}s  •  Dodged ${r.dodged}`, {
      fontFamily: 'system-ui, sans-serif',
      fontSize: '28px',
      color: m.textColor,
    }).setOrigin(0.5);

    makeButton(this, a.width / 2, a.height / 2 + 30, 'RETRY', () => {
      this.scene.start('game', { difficulty: r.difficulty });
    });

    makeButton(this, a.width / 2, a.height / 2 + 110, 'MENU', () => {
      this.scene.start('menu');
    }, { width: 200, height: 52, fontSize: 22 });
  }
}

new Phaser.Game({
  type: Phaser.AUTO,
  backgroundColor: '#05070c',
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
    width: CONFIG.arena.width,
    height: CONFIG.arena.height,
  },
  scene: [MenuScene, DifficultyScene, GameScene, GameOverScene],
});
