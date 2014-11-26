import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;

ADSR envelope;
Oscil waveform;
MoogFilter filter;

void setup() {
  minim = new Minim(this);
  out = minim.getLineOut();
  
  envelope = new ADSR();
  filter = new MoogFilter(3000, 0.5, MoogFilter.Type.LP);
  waveform = new Oscil(110, 0.5f, Waves.SAW);
  waveform.patch(filter);
  filter.patch(envelope);
  envelope.patch(out);
  envelope.setParameters(1, 0.001, 0.001, 0.4, 0.6, 0, 0);
}

void draw() {
  
}

void mousePressed() {
  envelope.noteOn();
}

void mouseReleased() {
  envelope.noteOff();
}
