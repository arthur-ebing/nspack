/**
 * Audio functions for Crossbeams.
 * @namespace
 */
const crossbeamsAudio = {

  ctx: new (AudioContext || webkitAudioContext)(),

  /**
   * playSound.
   * Play a sound.
   *
   * @param {} inDuration - duration in ms.
   * @param {} freq - frequency
   */
  playSound: function playSound(inDuration, freq) {
    const osc = crossbeamsAudio.ctx.createOscillator();
    const duration = +inDuration;

    osc.type = 0;
    osc.connect(crossbeamsAudio.ctx.destination);
    osc.frequency.value = freq;

    if (osc.start) {
      osc.start();
    } else {
      osc.noteOn(0);
    }

    setTimeout(
      () => {
        if (osc.stop) {
          osc.stop(0);
        } else {
          osc.noteOff(0);
        }
      },
      duration,
    );
  },

  /**
   * beep.
   * Play a beep tone.
   */
  beep: function beep() {
    crossbeamsAudio.playSound(180, 666);
  },

};
