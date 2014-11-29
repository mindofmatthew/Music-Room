import ddf.minim.*;
import ddf.minim.ugens.*;

class Instrument {
  
  AudioOutput output;
  Oscil waveform;
  ADSR envelope;
  
  boolean isPlaying = false;
  
  Instrument(AudioOutput output) {
    this.output = output;
    
    envelope = new ADSR();
    waveform = new Oscil(440, 1, Waves.randomNHarms(5));
    waveform.patch(envelope);
    envelope.patch(output);
    envelope.setParameters(1, 0.005, 0.005, 0.4, 0.6, 0, 0);
  }
  
  void noteOn(int pitch) {
    float frequency = pow(2, (pitch - 69) / 12.0) * 440;
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
  
  void destroy() {
    envelope.unpatch(output);
  }
}
