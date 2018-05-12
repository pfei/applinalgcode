function x=dwt_impl(x, m, wave_name, bd_mode, prefilter_mode, dual, transpose, data_layout, dims)
    % x:         Matrix whose DWT will be computed along the first dimension(s).      
    % m:         Number of resolutions.
    % wave_name: Name of the wavelet. Possible names are:
    %            'cdf97' - CDF 9/7 wavelet
    %            'cdf53' - Spline 5/3 wavelet
    %            'splinex.x' - Spline wavelet with given number of vanishing moments for each filter
    %            'pwl0'  - Piecewise linear wavelets with 0 vanishing moments
    %            'pwl2'  - Piecewise linear wavelets with 2 vanishing moments
    %            'Haar'  - The Haar wavelet
    %            'dbX'   - Daubechies orthnormal wavelet with X vanishing
    %                      moments
    %            'symX'  - Symmlets: A close to symmetric, orthonormal wavelet 
    %                      with X vanishing moments
    % bd_mode:   Boundary extension mode. Possible modes are. 
    %            'per'    - Periodic extension
    %            'symm'   - Symmetric extension (default)
    %            'none'   - Take no extra action at the boundaries
    %            'bd'     - Boundary wavelets
    % prefilter_mode: Possible modes are:
    %            'none' (default)
    %            'filter'
    %            'bd_pre' - Boundary wavelets with preconditioning
    % dual:      Whether to apply the dual wavelet rather than the wavelet itself. Default: 0
    % transpose: Whether the transpose is to be taken. Default: 0
    % data_layout: How data should be assembled. Possible modes are:
    %            'resolution': Lowest resolution first (default)
    %            'time': Sort according to time
    % dims:      the number of dimensions to apply the DWT to. Always applied to the first dimensions. Default: max(dim(x)-1,1).
    %            This means that sound with many channels, and images with many colour components default to a one- and two-dimensional DWT, respectively
    
    if (~exist('bd_mode','var')) bd_mode = 'symm'; end
    if (~exist('prefilter_mode','var')) prefilter_mode = 'none'; end
    if (~exist('dual','var')) dual  = 0; end
    if (~exist('transpose','var')) transpose = 0; end
    if (~exist('data_layout','var')) data_layout = 'resolution'; end
    if (~exist('dims','var')) 
        dims = 1;
        if length(size(x)) > 1
            dims = length(size(x)) - 1; 
        end
    end


    [wav_propsx, dual_wav_propsx] = find_wav_props(m, wave_name, bd_mode, size(x,1));
    [wav_propsx, fx, prefilterx] = find_kernel(wav_propsx, dual_wav_propsx, 1, dual, transpose, prefilter_mode);
    if dims == 1
        if transpose % if transpose, then f will we an idwt_kernel, 
            x = IDWTImpl_internal(x, m, fx, bd_mode, prefilterx, wav_propsx, data_layout);     
        else
            x = DWTImpl_internal(x, m, fx, bd_mode, prefilterx, wav_propsx, data_layout);
        end
    else
        [wav_propsy, dual_wav_propsy] = find_wav_props(m, wave_name, bd_mode, size(x,2));
        [wav_propsy, fy, prefiltery] = find_kernel(wav_propsy, dual_wav_propsy, 1, dual, transpose, prefilter_mode);
        if dims == 2
            if transpose % if transpose, then f will we an idwt_kernel, 
                x = IDWT2Impl_internal(x, m, fx, fy, bd_mode, prefilterx, prefiltery, wav_propsx, wav_propsy, data_layout);     
            else
                x =  DWT2Impl_internal(x, m, fx, fy, bd_mode, prefilterx, prefiltery, wav_propsx, wav_propsy, data_layout);
            end
        else
            [wav_propsz, dual_wav_propsz] = find_wav_props(m, wave_name, bd_mode, size(x,3));
            [wav_propsz, fz, prefilterz] = find_kernel(wav_propsz, dual_wav_propsz, 1, dual, transpose, prefilter_mode);
            if dims == 3 % if not give error message
                if transpose % if transpose, then f will we an idwt_kernel, 
                    x = IDWT3Impl_internal(x, m, fx, fy, fz, bd_mode, prefilterx, prefiltery, prefilterz, wav_propsx, wav_propsy, wav_propsz, data_layout);     
                else
                    x =  DWT3Impl_internal(x, m, fx, fy, fz, bd_mode, prefilterx, prefiltery, prefilterz, wav_propsx, wav_propsy, wav_propsz, data_layout);
                end
            end
        end
    end         
end