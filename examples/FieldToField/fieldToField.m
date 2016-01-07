% Computes the field-to-field transfer functions for a given
% set of input injections.
%
% Sean Leavey
% December 2015

%% Setup

% use the Fabry-Perot example
opt = optFP();

% frequencies
f = logspace(0, 5, 500);

% carrier frequency (this is here in case you want to look at a second
% carrier's fields)
fCarrier = Optickle.c / 1064e-9;
fRf1 = 20e6;

% carrier RF index
nCarrier = find(Optickle.matchFreqPol(opt, fCarrier, opt.polS));
nRfUpper = find(Optickle.matchFreqPol(opt, fCarrier + fRf1, opt.polS));

% link to inject at
nInj = opt.getLinkNum('Laser', 'AM');

% mirror DOF to drive
nDrive = opt.getDriveNum('IX');

% field injection indices
nFieldTfAC = getInternalField(opt, nCarrier, nInj);

%% Get field-to-field TFs
[~, ~, ~, ~, ~, ~, tfFFAC] = ...
    opt.tickle([], f, [], Optickle.tfPos, Optickle.tfFF, nFieldTfAC);

%% Get optic-to-field TFs
[~, ~, ~, ~, ~, ~, tfOFAC] = ...
    opt.tickle([], f, [], Optickle.tfPos, Optickle.tfOF);

%% Plot
Narf = opt.Nlink * length(opt.vFrf);

% internal field readout
nReadout = getInternalField(opt, nCarrier, opt.getLinkNum('IX', 'REFL'));

% upper and lower signal sidebands
tfFieldAClower = squeeze(tfFFAC(1 : Narf, :));
tfFieldACupper = squeeze(conj(tfFFAC(Narf + 1 : end, :)));

tfOpticAClower = squeeze(tfOFAC(1 : Narf, nDrive, :));
tfOpticACupper = squeeze(tfOFAC(Narf + 1 : end, nDrive, :));

figure;
%zplotlog(f, [tfFieldAClower(nReadout, :); tfFieldACupper(nReadout, :)]);
zplotlog(f, tfFieldAClower(nReadout, :) .* conj(tfFieldACupper(nReadout, :)));
title('Field-to-field');

figure;
zplotlog(f, [tfOpticAClower(nReadout, :); tfOpticACupper(nReadout, :)]);
title('Optic-to-field');