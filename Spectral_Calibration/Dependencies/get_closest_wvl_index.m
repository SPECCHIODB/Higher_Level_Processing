function [m, i] = get_closest_wvl_index(wvl_vector, wvl)

    [m, i] = min(abs(wvl_vector - wvl));

end