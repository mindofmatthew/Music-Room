import ddf.minim.*;
import ddf.minim.ugens.*;

class Instrument_Sine {
  
  AudioOutput output;
  Oscil waveform;
  ADSR envelope;
  MoogFilter filter;
  Flanger flanger;
  Line bend;
  Pan panner;
  
  boolean isPlaying = false;
  
  Instrument_Sine(AudioOutput output) {
    this.output = output;
    
    //if(centerOfMass.y < camHeight / 3) {
      envelope = new ADSR();
      waveform = new Oscil(440, 1, Waves.SINE);
      filter = new MoogFilter(8000, 0, MoogFilter.Type.BP);
      //flanger = new Flanger(0.5, 5, 0.1, 0.3, 0.5, 0.1);
      panner = new Pan(0);
      waveform.patch(envelope);
      //filter.patch(envelope);
      envelope.setParameters(1, 0.005, 0.005, 0.4, 0.6, 0, 0);
      //flangerWet = new Constant();
      //flangerWet.patch(filter.resonance);
    /*} else if(centerOfMass.y < 2 * camHeight / 3) {
      envelope = new ADSR();
      filter = new MoogFilter(8000, 0, MoogFilter.Type.LP);
      //bend = new Line(0.1, 0, 220);
      waveform = new Oscil(220, 1, Waves.SQUARE);
      waveform.patch(filter);
      filter.patch(envelope);
      //bend.patch(waveform.frequency);
      envelope.patch(out);
      envelope.setParameters(0.2, 0.1, 0.05, 0.6, 0.2, 0, 0);
    } else {
      envelope = new ADSR();
      filter = new MoogFilter(3000, 0.2, MoogFilter.Type.LP);
      waveform = new Oscil(110, 1, Waves.SAW);
      waveform.patch(filter);
      filter.patch(out);
      envelope.patch(out);
      envelope.setParameters(0.3, 0.001, 0.5, 0.2, 0.6, 0, 0);
    }*/
  }
  
  void noteOn(int pitch) {
    float frequency = pow(2, (pitch - 69) / 12.0) * 440;
    waveform.setFrequency(frequency);
    
    if(!isPlaying) {
      envelope.patch(output);
    }
    
    envelope.noteOn();
    
    //waveform.setAmplitude(constrain(map(boundBoxArea, 50000, 100000, 1, 2), 1, 2));
    
    //flangerWet.setConstant(constrain(map(boundBoxRatio, 0, 4, 0, 1), 0, 1));
    
    //if(boundBoxArea > 50000) {
      //timeOfAttack = millis();
    //}
    
    isPlaying = true;
  }
  
  void noteOff() {
    envelope.noteOff();
    
    isPlaying = false;
  }
  
  void setVolume(float volume) {
    waveform.setAmplitude(volume);
  }
  
  void destroy() {
    envelope.unpatch(output);
  }
}
