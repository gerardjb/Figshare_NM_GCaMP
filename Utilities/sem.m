function y = sem(mat,stdFLAG,dim)
%SEM standard error of the mean calculation
%   Takes an input matrix or vector and calculates the standard eviation along
%   the specified dimension as well as the number of elements along that
%   dimension. It then takes the std/sqrt(numel). Note that NaN values are 
%
%   Inputs:
%       mat - matrix to calculate the sem for
%       stdFLAG - specifies normalization to the unbiased estimator of
%           variance of the population, N - 1 with value 0 or by N with 1
%           Default: []
%       dim - dimension to calculate the sem along
%           Default: 1
%
%   Output:
%       y - vector containing the dsem values

%Handle cases with fewer than 3 inputs
if nargin==1
    stdFLAG = [];
    [~,dim] = max(size(mat));
elseif nargin==2
    [~,dim] = max(size(mat));
end

%Calculate SEM
n = sum(~isnan(mat),dim)';
y = nanstd(mat,stdFLAG,dim)./sqrt(n');
