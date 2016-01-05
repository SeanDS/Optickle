% Computes the field-to-field transfer functions for a given
% set of input injections.
%
% Sean Leavey
% December 2015

%% Setup

% use the Fabry-Perot example
opt = optFP();

% frequencies
f = logspace(2, 5, 250);

% carrier frequency (this is here in case you want to look at a second
% carrier's fields)
lambdaCarrier = 1064e-9;

% carrier RF index
nCarrier = find(Optickle.matchFreqPol(opt, Optickle.c / lambdaCarrier, opt.polS));

% link to inject at
nInj = opt.getLinkNum('Laser', 'AM');

% field injection indices
nFieldOutTfAC = getInternalField(opt, nCarrier, nInj);

%% Tickle
[fDC, sigDC, sigAC, mMech, noiseAC, noiseMech, tfACout] = ...
    opt.tickle([], f, [], Optickle.tfPos, nFieldOutTfAC);

%% Plot
Narf = opt.Nlink * length(opt.vFrf);

% internal field readout
nReadout = getInternalField(opt, nCarrier, opt.getLinkNum('IX', 'REFL'));

% combine upper and lower signal sidebands
tfAC = tfACout(1 : Narf, :) .* conj(tfACout(Narf + 1 : end, :));

tf = squeeze(tfAC(nReadout, :));

figure;
zplotlog(f, tf);