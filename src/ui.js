import { CONFIG } from './config.js';

// A rounded rectangular button with hover feedback. Returns the container so
// callers can position/destroy it. `onClick` fires on pointer up.
export function makeButton(scene, x, y, label, onClick, opts = {}) {
  const m = CONFIG.menu;
  const w = opts.width ?? 260;
  const h = opts.height ?? 64;

  // `active` marks the selected option in a group (e.g. screen format).
  const baseColor = opts.active ? m.buttonHoverColor : m.buttonColor;
  const bg = scene.add.rectangle(0, 0, w, h, baseColor);
  bg.setStrokeStyle(2, opts.active ? m.buttonActiveStroke : 0x3a557f);

  const text = scene.add.text(0, 0, label, {
    fontFamily: 'system-ui, sans-serif',
    fontSize: (opts.fontSize ?? 26) + 'px',
    color: m.buttonTextColor,
  }).setOrigin(0.5);

  const container = scene.add.container(x, y, [bg, text]);
  container.setSize(w, h);
  container.setInteractive({ useHandCursor: true });

  container.on('pointerover', () => bg.setFillStyle(m.buttonHoverColor));
  container.on('pointerout', () => bg.setFillStyle(baseColor));
  container.on('pointerup', onClick);

  return container;
}

// In-game heads-up display: survival time + dodged count, top-left.
export class HUD {
  constructor(scene) {
    this.style = {
      fontFamily: 'system-ui, sans-serif',
      fontSize: '24px',
      color: CONFIG.menu.textColor,
    };
    this.timeText = scene.add.text(CONFIG.arena.margin + 8, CONFIG.arena.margin + 8, '', this.style);
    this.dodgeText = scene.add.text(CONFIG.arena.margin + 8, CONFIG.arena.margin + 40, '', this.style);
  }

  update(seconds, dodged) {
    this.timeText.setText(`Time: ${seconds.toFixed(1)}s`);
    this.dodgeText.setText(`Dodged: ${dodged}`);
  }
}
