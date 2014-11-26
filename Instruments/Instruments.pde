import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;

ADSR envelope1;
Oscil waveform1;

ADSR envelope2;
Oscil waveform2;
MoogFilter filter2;
Line bend2;

ADSR envelope3;
Oscil waveform3;
MoogFilter filter3;

void setup() {
  minim = new Minim(this);
  out = minim.getLineOut();
  
  envelope1 = new ADSR();
  waveform1 = new Oscil(440, 1, Waves.SINE);
  waveform1.patch(envelope1);
  envelope1.patch(out);
  envelope1.setParameters(1, 0.005, 0.005, 0.4, 0.6, 0, 0);
  
  envelope2 = new ADSR();
  filter2 = new MoogFilter(8000, 0, MoogFilter.Type.LP);
  bend2 = new Line(0.1, 0, 220);
  waveform2 = new Oscil(220, 0.2, Waves.SQUARE);
  waveform2.patch(filter2);
  filter2.patch(envelope2);
  bend2.patch(waveform2.frequency);
  envelope2.patch(out);
  envelope2.setParameters(1, 0.1, 0.05, 0.6, 0.2, 0, 0);
 
  envelope3 = new ADSR();
  filter3 = new MoogFilter(3000, 0.2, MoogFilter.Type.LP);
  waveform3 = new Oscil(110, 0.3, Waves.SAW);
  waveform3.patch(filter3);
  filter3.patch(envelope3);
  envelope3.patch(out);
  envelope3.setParameters(1, 0.001, 0.5, 0.2, 0.6, 0, 0);
}

void draw() {
  if(frameCount % 60 == 0) {
    tone1On();
  }
  
  if(frameCount % 60 == 6) {
    tone1Off();
  }
  
  if(frameCount % 60 == 12) {
    tone2On();
  }
  
  if(frameCount % 60 == 24) {
    tone2Off();
  }
  
  if(frameCount % 30 == 0) {
    tone3On();
  }
  
  if(frameCount % 30 == 6) {
    tone3Off();
  }
}

void tone1On() {
  envelope1.noteOn();
}

void tone1Off() {
  envelope1.noteOff();
}

void tone2On() {
  envelope2.noteOn();
  bend2.activate();
}

void tone2Off() {
  envelope2.noteOff();
}

void tone3On() {
  envelope3.noteOn();
}

void tone3Off() {
  envelope3.noteOff();
}
