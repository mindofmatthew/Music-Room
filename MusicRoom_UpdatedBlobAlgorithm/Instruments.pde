import ddf.minim.*;
import ddf.minim.ugens.*;

class Instrument {
  
  AudioOutput output;
  Oscil waveform;
  ADSR envelope;
  UGen effect;
  Delay delay;
  MoogFilter moogFilter;
  
  int instNum=0;
  float registerOffset = 1.0;  // multiply the frequency  by this before playing
  
  boolean isPlaying = false;
  
  Instrument(AudioOutput output) {
    this.output = output;
    
    envelope = new ADSR();
    waveform = new Oscil(440, 1, Waves.randomNHarms(5));
    waveform.patch(envelope);
    envelope.patch(output);
    envelope.setParameters(1, 0.005, 0.005, 0.4, 0.6, 0, 0);
  }
 
 Instrument(AudioOutput output, int instrSelect) {
     this.output = output;
     this.instNum = instrSelect;
     
     switch(instrSelect) {
       case 1:
         instr1();
         break;
       case 2:
         instr2();
         break;
       case 0:
       default:
         instr0();
         break;
     }
 }

 void instr1() {
    envelope = new ADSR();
        delay = new Delay(0.5,.5,true);
    waveform = new Oscil(440, 1, Waves.randomNOddHarms(3));
    waveform.patch(envelope);
    envelope.patch(delay);
    delay.patch(output);
    envelope.setParameters(1, 0.2, 0.1, 0.6, 0.8, 0, 0);
    registerOffset=2/3;  // go down a fourth?
    
 }

 void instr2() {
    envelope = new ADSR();
        delay = new Delay(0.5,.5,true);
    waveform = new Oscil(440, 1, Waves.add( new float[] { 0.5, 0.5 }, Waves.triangle( 0.05 ), Waves.randomNOddHarms( 3 ) ));
    waveform.patch(envelope);
    envelope.patch(delay);
    delay.patch(output);
    envelope.setParameters(1, 0.2, 0.1, 0.6, 0.8, 0, 0);
    registerOffset = 3/2;  // go up a fifth
    
 }
  void instr3() {
    envelope = new ADSR();
    moogFilter = new MoogFilter(440,0.5,MoogFilter.Type.BP); // bandpass filter at 440 hz with .5 resonance
        
    waveform = new Oscil(440, 1, Waves.randomNOddHarms(3));
    waveform.patch(envelope);
    envelope.patch(delay);
    delay.patch(output);
    envelope.setParameters(1, 0.2, 0.1, 0.6, 0.8, 0, 0);
    registerOffset=2/3;  // go down a fourth?
    
 }
 
 void instr0() {
    // Matt's original instrument (same as calling new Instrument(out) without integer)
    envelope = new ADSR();
    waveform = new Oscil(440, 1, Waves.randomNHarms(5));
    waveform.patch(envelope);
    envelope.patch(output);
    envelope.setParameters(1, 0.005, 0.005, 0.4, 0.6, 0, 0);
    registerOffset=1.0;
 }
 
 void noteOn(int pitch) {
    float frequency = pow(2, (pitch - 69) / 12.0) * 440; 
    waveform.setFrequency(frequency);
    
    envelope.noteOn();
    
    isPlaying = true;
  }
  void noteOn(Frequency frequency) {
//    float hertz = frequency.asHz()*registerOffset;
//    println("note on as hertz: "+hertz);
//    frequency.setAsHz(hertz);
     waveform.setFrequency(frequency);
    
    envelope.noteOn();
    
    isPlaying = true;   
  }
  
  void noteOff() {
    envelope.noteOff();
    
    isPlaying = false;
  }
  
  void setVolume(float volume) {
    waveform.setAmplitude(volume);
  }
  
  void setDelay(float delayLength) {
    if (delay != null) {
      delay.setDelTime(delayLength);
    }
  }
  
  void destroy() {
    envelope.unpatch(output);
    if (effect != null) {
      effect.unpatch(output);
    }
    if (delay != null) {
      delay.unpatch(output);
    }
  }
}
