function stab_c = niak_normalize_stability(stab,list_scales,flag_verbose)
% Normalization of stability matrices
%
% This function is called by NIAK_MSTEPS and is not meant to be used independently
if nargin < 3
    flag_verbose = true;
end
if flag_verbose
    fprintf('Normalizing the stability matrices ...\n');
end
stab_c = zeros(size(stab));
for num_sc = 1:length(list_scales)
    sc = list_scales(num_sc);
    if sc > 1
    	stab_tmp = stab(:,num_sc)-sc^(-1);
    	stab_tmp(stab_tmp<0) = 0;
    	stab_tmp = stab_tmp/(1-sc^(-1));
    	stab_c(:,num_sc) = stab_tmp;
    else
        stab_c(:,num_sc) = 0;
    end
end
