% n = getFieldEvalNum(opt, nRf, nLink)
%   get the internal field evaluation point used in Optickle's calculation
%   of field amplitudes corresponding to the specified vFrf field and link

function n = getFieldEvalNum(opt, nRf, nLink)
    % total number of links
    nLinkTotal = opt.Nlink;
    
    % total RF frequencies
    nRfTotal = length(opt.vFrf);
    
    % sanity checks
    if nLink > nLinkTotal
        error('nLnk is greater than the number of links in the system!');
    elseif nRf > nRfTotal
        error('nRf is greater than the number of RF fields in the system!');
    end
    
    % the order of RF fields and links is demonstrated for example in
    % convertLinks: prbList(jPrb).mIn(n, prb.nField + Nlnk * (n - 1)) = 1;
    % (around line 72)
    n = (nRf - 1) * nLinkTotal + nLink;
end