%% Setup

% frequencies
f = logspace(0, 5, 500);

%% Setup simulation

opt = optFP();

%% Get drives
nEXDrive = opt.getDriveNum('EX');

%% Get probes
nREFLI = opt.getProbeNum('REFL_I');

%% Indices

% carrier frequency (this is here in case you want to look at a second
% carrier's fields)
fCarrier = Optickle.c / opt.lambda(1);
fRf = opt.getOptic('Mod1').fMod;

% carrier RF index
nCarrier = find(Optickle.matchFreqPol(opt, fCarrier, opt.polS));
nRfLower = find(Optickle.matchFreqPol(opt, fCarrier - fRf, opt.polS));
nRfUpper = find(Optickle.matchFreqPol(opt, fCarrier + fRf, opt.polS));

% number of audio frequencies to simulate
Narf = opt.Nlink * length(opt.vFrf);

% links to inject at
nLnkLaser = opt.getLinkNum('Laser', 'AM');
nLnkCavEnd = opt.getLinkNum('EX', 'IX');

% laser field
nFieldLaser = getInternalField(opt, nCarrier, nLnkLaser);

% field injection indices
nFieldTfAC = [ ...
    getInternalField(opt, nCarrier, nLnkLaser), sqrt(100);
    getInternalField(opt, nRfLower, nLnkLaser), sqrt(1);
    getInternalField(opt, nRfUpper, nLnkLaser), sqrt(1);
    %getInternalField(opt, nCarrier, nLnkCav), 1e-12;
];

% drive index
nDrive = opt.getDriveNum('EX');

% internal field readout
nReadoutCarrier = getInternalField(opt, nCarrier, opt.getLinkNum('IX', 'REFL'));
nReadoutRf = getInternalField(opt, nRfLower, opt.getLinkNum('IX', 'REFL'));

%% Get field-to-field TFs

% NOTE: with tickle2, the ndrive and tfType argument order is swapped!
[~, ~, mOpt, ~, ~, ~, tfFFAC] = ...
    opt.tickle2([], f, Optickle.tfPos, [], Optickle.tfFF, nFieldTfAC);
%[~, ~, mOpt, ~, ~, ~, tfFFAC] = ...
%    opt.tickle([], f, [], Optickle.tfPos, Optickle.tfFF, nFieldTfAC);

% upper and lower signal sidebands
%tfFieldAClower = squeeze(tfFFAC(1 : Narf, :));
%tfFieldACupper = squeeze(conj(tfFFAC(Narf + 1 : end, :)));
tfFFACa = squeeze(tfFFAC(nReadoutRf, nFieldLaser, :));

%tfFFACa = tfFieldAClower(nReadout, :)';
tfACa = getTF(mOpt, nREFLI, nAMDrive);

%% Get optic-to-field TFs
% [fDC, ~, sigAC, ~, ~, ~, tfOFAC] = ...
%     opt.tickle([], f, [], Optickle.tfPos, Optickle.tfOF);
% %[~, ~, sigAC, ~, ~, ~, tfOFAC] = ...
% %    opt.tickle2([], f, Optickle.tfPos, [], Optickle.tfOF);
% 
% tfOpticAClower = squeeze(tfOFAC(1 : Narf, nDrive, :));
% tfOpticACupper = squeeze(tfOFAC(Narf + 1 : end, nDrive, :));
% 
% tfOFACa = tfOpticAClower(nReadoutRf, :)';
% tfOForiginal = getTF(sigAC, nREFLI, nDrive);

%% Calculate signal on PD

nLnkFrom = opt.getLinkNum('TRANS', 'EX');
nLnkTo = opt.getLinkNum('MREFL', 'REFL');

% internal field entering IFO at REFLI
fldREFL = getInternalField(opt, nCarrier, nLnkTo);
fldREFLalt = getInternalField(opt, nCarrier, nLnkFrom);

sigREFLI = squeeze(tfFFAC(nLnkTo, nLnkFrom, :));

%% Plot

figure;
zplotlog(f, [sigREFLI]);
legend('Field-to-field');

% figure;
% zplotlog(f, [tfOFACa, tfOForiginal]);
% legend('Optic-to-field', 'TF');

%figure;
%zplotlog(f, [tfFieldAClower(nReadout, :); tfFieldACupper(nReadout, :)]);
%zplotlog(f, tfFieldAClower(nReadout, :) .* conj(tfFieldACupper(nReadout, :)));
%title('Field-to-field');

%figure;
%zplotlog(f, [tfOpticAClower(nReadout, :); tfOpticACupper(nReadout, :)]);
%title('Optic-to-field');