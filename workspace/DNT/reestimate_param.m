function pf_param = reestimate_param(pf_param)
if  pf_param.minconf > 120 && pf_param.ratio > 1.4%% high confidence
    scale = true;
elseif pf_param.minconf > 120 && pf_param.ratio < 1.38 %% median confidence and resolution
    scale = false;
% elseif pf_param.minconf > 24 && pf_param.ratio > 0.48 %% median confidence and resolution
%     scale = true;
elseif pf_param.minconf > 10 && pf_param.ratio < 0.60 %% high confidence with low resolution
    scale = true;
else 
    scale = false;
end
scale = true;
% scale = false;
if scale
    pf_param.affsig = pf_param.affsig_o;
end
end