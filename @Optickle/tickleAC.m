% backend function for tickle2
%
% [mOpt, mMech, noiseOpt, noiseMech] = tickleAC(opt, f, vLen, vPhiGouy, ...
%   mPhiFrf, mPrb, mOptGen, mRadFrc, lResp, mQuant, shotPrb)


function varargout = tickleAC(opt, f, vLen, vPhiGouy, ...
  mPhiFrf, mPrb, mOptGen, mRadFrc, lResp, mQuant, shotPrb, nDrive, ...
  fieldTfType, nFieldTfAC)

  % === Field Info
  vFrf = opt.vFrf;
  
  % ==== Sizes of Things
  Ndrv = opt.Ndrive;   % number of drives (internal DOFs)
  Nlnk = opt.Nlink;    % number of links
  Nrf  = length(vFrf); % number of RF components
  Naf  = length(f);    % number of audio frequencies
  Nfld = Nlnk * Nrf;   % number of RF fields
  Narf = 2 * Nfld;     % number of audio fields
  Ndof = Narf + Ndrv;  % number of degrees - of - freedom
  
  isNoise = ~isempty(mQuant);
  
  % ==== Useful Indices
  jAsb = 1:Narf;          % all fields
  jDrv = (1:Ndrv) + Narf; % drives
  
  % combine probe and output matrix
  if isempty(opt.mProbeOut)
    mOut = mPrb;
  elseif size(opt.mProbeOut, 2) == size(mPrb, 1)
    mOut = opt.mProbeOut * mPrb;
  else
    error('opt.mProbeOut must have Nprobe columns')
  end
  Nout = size(mOut, 1);

  % make input to drive matrix
  if ~isempty(nDrive)
    % make input matrix for this nDrive
    jjDrv = 1:opt.Ndrive;
    eyeNdrv = eye(opt.Ndrive);
    mInDrv = eyeNdrv(:, jjDrv(nDrive));
  elseif isempty(opt.mInDrive)
    mInDrv = eye(Ndrv);
  else
    mInDrv = opt.mInDrive;
  end

  mDrvIn = pinv(mInDrv);
  Nin = size(mInDrv, 2);

  % intialize result space
  eyeNdof   = speye(Ndof);
  %mExc      = eyeNdof(:, jDrv) * mInDrv;
  %sigAC     = zeros(Nout, Nin, Naf);
  eyeNarf   = speye(Narf);
  mOpt      = zeros(Nout, Nin, Naf);
  mMech     = zeros(Nin, Nin, Naf);
  noiseOpt  = zeros(Nout, Naf);
  noiseMech = zeros(Nin, Naf);
  
  % is tfAC wanted?
  isOutTfAC = 0; % no, by default
  
  if fieldTfType > Optickle.tfNone
    isOutTfAC = 1;
  end
  
  if fieldTfType == Optickle.tfFF
    % field-to-field TFs
    tfACout = zeros(Ndof, Ndof, Naf);

    % empty excitation matrix (first column: field indices, second column:
    % excitation)
    fieldExc = zeros(Narf, 1);

    % excitation field indices (upper and lower sidebands)
    jFfAsbAC = [jAsb(nFieldTfAC(:, 1)), jAsb(Nfld + nFieldTfAC(:, 1))];

    % set field excitations
    fieldExc(jFfAsbAC) = [nFieldTfAC(:, 2), nFieldTfAC(:, 2)];
  elseif fieldTfType == Optickle.tfOF
    % optic-to-field TFs
    tfACout = zeros(Ndof, Ndrv, Naf); % this should really be number of drive outputs, not total number of drives
  end
  
  % since this can take a while, let's time it
  tic;
  hWaitBar = [];
  tLast = 0;
  
  % prevent scale warnings
  sWarn = warning('off', 'MATLAB:nearlySingularMatrix');

  % audio frequency loop
  for nAF = 1:Naf
    fAudio = f(nAF);

    % propagation phase matrices
    mPhim = Optickle.getPhaseMatrix(vLen, vFrf - fAudio, -vPhiGouy, mPhiFrf);
    mPhip = Optickle.getPhaseMatrix(vLen, vFrf + fAudio, -vPhiGouy, mPhiFrf);
    mPhi = blkdiag(mPhim, conj(mPhip));
    
    % mechanical response matrix
    mResp = diag(lResp(nAF,:));
    
    %%%%%%%%%%%%% Reference Code (matches Optickle 1)
    % % ==== Put it together and solve
    % mDof = [  mPhi * mOptGen
    %          mResp * mRadFrc ];
    %
    % tfAC = (eyeNdof - mDof) \ mExc;

    % % extract optic to probe transfer functions
    % sigAC(:, :, nAF) = 2 * mOut * tfAC(jAsb, :);
    % mMech(:, :, nAF) = mDrvIn * tfAC(jDrv, :);
    
    %%%%%%%%%%%%% Piecewise Inversion
    % see Optickle2 documentation, secion 5.3 AC Matrix Inversion
    %   sigAC == mOpt * mMech
    
    mPhiOptGen = mPhi * mOptGen;
    mFF = mPhiOptGen(:, jAsb);    % field-field
    mOF = mPhiOptGen(:, jDrv);    % optic-field
    
    % mPhi = propagation phase matrix, Narf x Narf
    % mOptGen = Narf x Ndof
    % so mPhiOptGen is Narf x Narf * Narf x Ndof so maps fields to DoFs
    % (DoFs are fields + mechanical drives)
    
    mRespRadFrc = mResp * mRadFrc;
    mFO = mRespRadFrc(:, jAsb);   % field-optic
    mOO = mRespRadFrc(:, jDrv);   % optic-optic
    
    % mFO is Ndrv x Narf
    % mOO is Ndrv x Ndrv
    
    tfOptAC = (eyeNarf - mFF) \ (mOF * mInDrv); % drives to ASB amplitudes
    mOpt(:, :, nAF) = -2 * mOut * tfOptAC;
    mMech(:, :, nAF) = (mInDrv - mOO * mInDrv - mFO * tfOptAC) \ mInDrv;
    
    % mInDrv is eye(Ndrv)
    % mOF maps fields to drives
    % so tfOptAC maps fields to drives (Narf x Ndrv)
    % mOut == mPrb (unless special output is requested)
    % mPrb is Nprb x Narf
    % mPrb maps fields to probes. This already contains coefficients for RF
    % fields, etc.
    % so mOpt is Nprb x Narf * Narf x Ndrv, so it maps drives to probes
    % mMech also maps drives to probes
    
    % field TF matrix wanted?
    if isOutTfAC
      if fieldTfType == Optickle.tfFF
        % empty matrix representing lower right corner of Eq. 11 in manual
        mZero = zeros(Ndrv, Ndrv);
        
        % Eq. 11
        mAC = [mFF, mOF; mFO, mZero];
        
        tfACout(:, :, nAF) = inv(eyeNdof - mAC);
          
        %tfACout(:, :, nAF) = (eyeNarf - mFF) \ eyeNarf;
      elseif fieldTfType == Optickle.tfOF
        mDoFDrv = (eyeNdof - [mPhiOptGen; mRespRadFrc]) \ eyeNdof(:, jDrv);
        %tfACout(:, :, nAF) = mMechField * mOpt(:, :, nAF);
        % mDoFDrv is Ndof x Ndrv
        
        tfACout(:, :, nAF) = mDoFDrv * mOpt(:, :, nAF);
      end
    end
    
    %%% Quantum noise
    if isNoise
      % setup
      mDof = [mPhiOptGen; mRespRadFrc];
      mQinj = blkdiag(mPhi, mResp) * mQuant;
      mNoise = (eyeNdof - mDof) \ mQinj;
      noisePrb = mOut * mNoise(jAsb, :);
      noiseDrv = mDrvIn * mNoise(jDrv, :);
      
      % incoherent sum of amplitude and phase noise
      noiseOpt(:, nAF) = sqrt(sum(abs(noisePrb).^2, 2) + shotPrb);
      noiseMech(:, nAF) = sqrt(sum(abs(noiseDrv).^2, 2));
    end
    
    % ==== Timing and User Interaction
    % NO MODELING HERE (just let the user know how long this will take)
    tNow = toc;
    frac = nAF / Naf;
    tRem = tNow * (1 / frac - 1);
    if tNow > 2 && tRem > 2 && tNow - tLast > 0.5 && opt.debug > 0
      % wait bar string
      str = sprintf('%.1f s used, %.1f s left', tNow, tRem);

      % check and update waitbar
      if isempty(hWaitBar)
        % create wait bar
        try
          strWB = [str ' (close this window to stop)'];
          hWaitBar = waitbar(frac, strWB, 'Name', 'Optickle: Computing...');
          tLast = tNow;
        catch
          % can't make wait bar... use text
          if tNow - tLast > 5
            disp(str)
            tLast = tNow;
          end
        end
      else
        try
          strWB = [str ' (close this window to stop)'];
          findobj(hWaitBar);			% error if wait bar closed
          waitbar(frac, hWaitBar, strWB);	% update wait string
          tLast = tNow;
        catch
          error('Wait bar closed by user.  Exiting.')
        end
      end
    end
  end
    
  % reset scale warning state
  warning(sWarn.state, sWarn.identifier);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ==== Clean Up
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % close wait bar
  if ~isempty(hWaitBar)
    waitbar(1.0, hWaitBar, 'Done computing fields.  Returning...')
    close(hWaitBar)
  end

  % make sure that the wait bar is closed
  drawnow

  % Build the outputs
  varargout{1} = mOpt;
  varargout{2} = mMech;
  if isNoise
    varargout{3} = noiseOpt;
    varargout{4} = noiseMech;
  end
  
  if isOutTfAC
    varargout{end + 1} = tfACout;
  else
    % empty
    varargout{end + 1} = [];
  end
end