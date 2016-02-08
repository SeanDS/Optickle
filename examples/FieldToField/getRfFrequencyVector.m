function vFrf = getRfFrequencyVector(par)
    n = (-1 : 1)';
    
    f1 = par.EOM('EOM1').fRF;
    f2 = par.EOM('EOM2').fRF;
    
    vFrf = sortrows(unique([n * f1; n * f2; f1 + f2; f1 - f2; -(f1 + f2); -f1 + f2]));
end