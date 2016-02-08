% Create an Optickle Fabry-Perot
%
% This is a modified version of the FabryPerot example. The only change is
% to add a pickoff beamsplitter for REFL instead of just looking at the
% back port of IX, so allow vacuum fluctuations to enter via the REFL sink.

function opt = optFP

  % RF component vector
  Pin = 100;
  vMod = (-1:1)';
  fMod = 20e6;
  vFrf = fMod * [vMod; 0];  % add green carrier, just for fun
  
  lambda = 1064e-9 * [1 1 1 0.5]';  % green is last
  pol = [1 1 1 0]';                 % and green is P-polarization!
  
  % create model
  opt = Optickle(vFrf, lambda, pol);
  
  % add a source
  opt.addSource('Laser', sqrt(Pin) * (vFrf == 0));

  % add an AM modulator (for intensity control, and intensity noise)
  %   opt.addModulator(name, cMod)
  opt.addModulator('AM', 1);
  opt.addLink('Laser', 'out', 'AM', 'in', 0);

  % add an PM modulator (for frequency control and noise)
  opt.addModulator('PM', 1i);
  opt.addLink('AM', 'out', 'PM', 'in', 0);

  % add an RF modulator
  %   opt.addRFmodulator(name, fMod, aMod)
  gamma = 0.2;
  opt.addRFmodulator('Mod1', fMod, 1i * gamma);
  opt.addLink('PM', 'out', 'Mod1', 'in', 1);

  % add mirrors
  %   opt.addMirror(name, aio, Chr, Thr, Lhr, Rar, Lmd, Nmd)
  lCav = 4000;
  opt.addMirror('IX', 0, 0, 0.03);
  opt.addMirror('EX', 0, 0.7 / lCav, 0.003);
  
  % pickoff for REFL
  opt.addBeamSplitter('MREFL', 0, 0, 0.01);

  opt.addLink('Mod1', 'out', 'MREFL', 'frA', 0);
  opt.addLink('MREFL', 'bkA', 'IX', 'bk', 0);
  opt.addLink('IX', 'fr', 'EX', 'fr', lCav);
  opt.addLink('EX', 'fr', 'IX', 'fr', lCav);
  opt.addLink('IX', 'bk', 'MREFL', 'bkB', 0);
  
  % add unphysical intra-cavity probes
  opt.addProbeIn('IX_DC', 'IX', 'fr', 0, 0);
  opt.addProbeIn('EX_DC', 'EX', 'fr', 0, 0);
  
  % set some mechanical transfer functions
  w = 2 * pi * 0.7;      % pendulum resonance frequency
  mI = 40;               % mass of input mirror
  mE = 40;               % mass of end mirror

  w_pit = 2 * pi * 0.5;   % pitch mode resonance frequency

  rTM = 0.17;             % test-mass radius
  tTM = 0.2;              % test-mass thickness
  iTM = (3 * rTM^2 + tTM^2) / 12;  % TM moment / mass

  iI = mE * iTM;          % moment of input mirror
  iE = mE * iTM;          % moment of end mirror

  dampRes = [0.01 + 1i, 0.01 - 1i];
  
  opt.setMechTF('IX', zpk([], -w * dampRes, 1 / mI));
  opt.setMechTF('EX', zpk([], -w * dampRes, 1 / mE));

  opt.setMechTF('IX', zpk([], -w_pit * dampRes, 1 / iI), 2);
  opt.setMechTF('EX', zpk([], -w_pit * dampRes, 1 / iE), 2);
  
  % tell Optickle to use this cavity basis
  opt.setCavityBasis('IX', 'EX');
  
  % add REFL optics
  opt.addSink('REFL');
  opt.addLink('MREFL', 'bkB', 'REFL', 'in', 2);
  opt.addLink('REFL', 'out', 'MREFL', 'bkA', 2);
  
  % add REFL probes (this call adds probes REFL_DC, I and Q)
  phi = 30;
  opt.addReadout('REFL', [fMod, phi]);

  % add TRANS probe
  opt.addSink('TRANS');
  opt.addLink('EX', 'bk', 'TRANS', 'in', 2);
  opt.addProbeIn('TRANS_DC', 'TRANS', 'in', 0, 0);
  opt.addLink('TRANS', 'out', 'EX', 'bk', 2);
  

end
