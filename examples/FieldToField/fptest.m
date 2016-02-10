%% Setup

% frequencies
f = logspace(0, 5, 500);

%% Setup simulation

opt = optFP();

% number of degrees of freedom
Ndof = 2 * length(opt.vFrf) * opt.Nlink + opt.Ndrive;

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
nEX = opt.getDriveNum('EX');

%% Get noise-to-field TFs

nLnkREFLIn = opt.getLinkNum('REFL', 'MREFL');
%nLnkREFLIn = opt.getLinkNum('TRANS', 'EX');
fldREFLIn = getInternalField(opt, nCarrier, nLnkREFLIn);

% fields to inject at
fieldInj = zeros(Ndof, 1);
fieldInj(fldREFLIn) = 1;

% NOTE: with tickle2, the ndrive and tfType argument order is swapped!
[~, ~, sigAC, ~, ~, ~, tfNFAC] = ...
    opt.tickle([], f, [], Optickle.tfPos, Optickle.tfNF, fieldInj);
%[~, ~, mOpt, ~, ~, ~, tfNFAC] = ...
%    opt.tickle2([], f, Optickle.tfPos, [], Optickle.tfNF, fieldInj);

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

nLnkREFLOut = opt.getLinkNum('MREFL', 'REFL');
fldREFLOut = getInternalField(opt, nCarrier, nLnkREFLOut);

tfREFLI = tfNFAC(fldREFLOut, :);

%% Plot

figure;
zplotlog(f, [tfREFLI]);
legend('Noise-to-field');

figure;
zplotlog(f, getTF(sigAC, nREFLI, nEX));

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