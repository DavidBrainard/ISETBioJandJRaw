function c = excitationsToModulations(e,b)
    c = bsxfun(@minus, e, b);
    c = bsxfun(@times, c, 1./b);
end