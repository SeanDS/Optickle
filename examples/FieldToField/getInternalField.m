function n = getInternalField(opt, nRf, nLink)
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
    
    n = (nRf - 1) * nLinkTotal + nLink;
end