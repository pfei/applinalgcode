function x=idwt2_impl_internal(x, fx, fy, m, bd_mode, prefilterx, prefiltery, offsets, data_layout)
    % x:         Matrix whose DWT will be computed along the first dimension(s).      
    % m:         Number of resolutions.
    % f:         kernel function
    % bd_mode:   Boundary extension mode. Possible modes are. 
    %            'per'    - Periodic extension
    %            'symm'   - Symmetric extension (default)
    %            'none'   - Take no extra action at the boundaries
    %            'bd'     - Boundary wavelets
    % prefilter: function which computes prefiltering
    % offsets:   offsets at the beginning and the end as used by boundary wavelets. Default: zeros.
    % data_layout: How data should be assembled. Possible modes are:
    %            'resolution': Lowest resolution first (default)
    %            'time': Sort according to time
    
    if (~exist('m','var')) m = 1; end
    if (~exist('bd_mode','var')) bd_mode = 'symm'; end
    if (~exist('prefilter','var')) prefilter = @(x, forward) x; ; end
    if (~exist('offsets','var')) offsets = zeros(2,2); end
    if (~exist('data_layout','var')) data_layout = 'resolution'; end
    
    [x, resstart, resend] = reorganize_coeffs2_reverse(x, m, offsets, data_layout);
    
    lastdim = 1;
    if length(size(x)) == 3
        lastdim = size(x, 3);
    end 
    
    % postconditioning
    indsx = resstart(1,m+1):2^m:resend(1,m+1); indsy = resstart(2,m+1):2^m:resend(2,m+1);
    x=tensor2_kernel(x, indsx, indsy, @(x,bd_mode) prefilterx(x, 1), @(x,bd_mode) prefiltery(x, 1), lastdim, bd_mode);

    for res = (m - 1):(-1):0
        indsx = resstart(1,res+1):2^res:resend(1,res+1); 
        indsy = resstart(2,res+1):2^res:resend(2,res+1);
        x = tensor2_kernel(x, indsx, indsy, fx, fy, lastdim, bd_mode);
    end
    
    % preconditioning
    indsx = resstart(1,1):resend(1,1); indsy = resstart(2,1):resend(2,1);
    x = tensor2_kernel(x, indsx, indsy, @(x,bd_mode) prefilterx(x, 0), @(x,bd_mode) prefiltery(x, 0), lastdim, bd_mode);
end

function [sig_out, resstart, resend]=reorganize_coeffs2_reverse(sig_in, m, offsets, data_layout)
    indsx = 1:size(sig_in,1); indsy = 1:size(sig_in,2);
    sig_out = sig_in;
    resstart = [1:(m+1); 1:(m+1)]; resend = [1:(m+1); 1:(m+1)];
    resstart(1,1) = indsx(1); resend(1,1) = indsx(end);
    resstart(2,1) = indsy(1); resend(2,1) = indsy(end);
    if strcmpi(data_layout, 'time')
        for res=1:m
            indsx = indsx((offsets(1,1)+1):2:(end-offsets(1,2)));
            indsy = indsy((offsets(2,1)+1):2:(end-offsets(2,2)));
            resstart(1,res+1) = indsx(1); resend(1,res+1) = indsx(end);
            resstart(2,res+1) = indsy(1); resend(2,res+1) = indsy(end);
        end
    end
    if strcmpi(data_layout, 'resolution')
        endx = size(sig_in,1); endy = size(sig_in,2);
        for res=1:m
            psiinds_x = [indsx(1:offsets(1,1)) indsx((offsets(1,1) + 2):2:(end-offsets(1,2))) indsx((end-offsets(1,2)+1):end)]; % psi-indices
            psiinds_y = [indsy(1:offsets(2,1)) indsy((offsets(2,1) + 2):2:(end-offsets(2,2))) indsy((end-offsets(2,2)+1):end)];
            phiinds_x = indsx((offsets(1,1) + 1):2:(end-offsets(1,2)));
            
            resstart(1,res+1) = indsx(offsets(1,1)+1); resend(1,res+1)   = indsx(end-offsets(1,2));
            resstart(2,res+1) = indsy(offsets(2,1)+1); resend(2,res+1)   = indsy(end-offsets(2,2));
            
            sig_out(psiinds_x, indsy, :) = sig_in((endx-length(psiinds_x)+1):endx, 1:endy, :);
            sig_out(phiinds_x,psiinds_y, :) = sig_in(1:(endx-length(psiinds_x)), (endy-length(psiinds_y)+1):endy, :);
            
            endx = endx - length(psiinds_x); endy = endy - length(psiinds_y);
            indsx = indsx((offsets(1,1)+1):2:(end-offsets(1,2))); 
            indsy = indsy((offsets(2,1)+1):2:(end-offsets(2,2)));
        end
        sig_out(indsx, indsy, :) = sig_in(1:endx, 1:endy, :);
    end
end
