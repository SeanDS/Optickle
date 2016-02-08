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

% drive index
nDrive = opt.getDriveNum('EX');

%% Get field-to-field TFs

% NOTE: with tickle2, the ndrive and tfType argument order is swapped!
[~, ~, mOpt, ~, ~, ~, tfFFAC] = ...
    opt.tickle2([], f, Optickle.tfPos, [], Optickle.tfFF);
%[~, ~, mOpt, ~, ~, ~, tfFFAC] = ...
%    opt.tickle([], f, [], Optickle.tfPos, Optickle.tfFF);

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

%% Calculate TF

nLnkFrom = opt.getLinkNum('REFL', 'MREFL');
nLnkTo = opt.getLinkNum('MREFL', 'REFL');

% internal field entering IFO at REFLI
fldREFL = getInternalField(opt, nCarrier, nLnkTo);
fldREFLalt = getInternalField(opt, nCarrier, nLnkFrom);

tfREFLI = squeeze(tfFFAC(nLnkTo, nLnkFrom, :));

%% Plot

figure;
zplotlog(f, [tfREFLI]);
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