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

% carrier
fldREFLCarrierIn = opt.getFieldEvalNum(nCarrier, nLnkREFLIn);
fldREFLSidebandIn = opt.getFieldEvalNum(nRfUpper, nLnkREFLIn);

% fields to inject at
fieldInjCarrier = zeros(Ndof, 1);
fieldInjCarrier(fldREFLCarrierIn) = 1;
fieldInjSideband = zeros(Ndof, 1);
fieldInjSideband(fldREFLSidebandIn) = 1;

[~, ~, sigAC, ~, ~, ~, tfNFACCarrier] = ...
    opt.tickle([], f, [], Optickle.tfPos, Optickle.tfNF, fieldInjCarrier);

[~, ~, ~, ~, ~, ~, tfNFACSideband] = ...
    opt.tickle([], f, [], Optickle.tfPos, Optickle.tfNF, fieldInjSideband);

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

fldREFLCarrierOut = opt.getFieldEvalNum(nCarrier, nLnkREFLOut);
fldREFLSidebandOut = opt.getFieldEvalNum(nRfUpper, nLnkREFLOut);

tfREFLICarrier = tfNFACCarrier(fldREFLCarrierOut, :);
tfREFLISideband = tfNFACSideband(fldREFLSidebandOut, :);

%% Plot

figure;
zplotlog(f, [tfREFLICarrier; tfREFLISideband]);
title('REFL in -> REFL out');
legend('Carrier', '(Upper) Sideband');

figure;
zplotlog(f, getTF(sigAC, nREFLI, nEX));
title('EX -> REFL transfer function');
ylabel('Response [W/m]');

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