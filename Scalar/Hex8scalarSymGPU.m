function KE = Hex8scalarSymGPU(elements,nodes,c,tbs)
% HEX8SCALARSYMGPU Compute the lower symmetric part of all the element
% stiffness matrices for a SCALAR problem taking advantage of simmetry and
% GPU computing.
%   HEX8SCALARSYMGPU(elements,nodes,c,tbs) returns the element stiffness matrix
%   "ke" for all elements in a finite element analysis of a scalar problem
%   in a three-dimensional domain taking advantage of symmetry and GPU
%   computing, where "elements" is the connectivity matrix, "nodes" the
%   nodal coordinates, "c" the material property for an isotropic
%   material, and "tbs" in an optional input referred to ThreadBlockSize.
%
%   See also HEX8SCALARSYMCPU, HEX8SCALARSYMCPUP, STIFFMATGENSCSYMGPU
%
%   For more information, see <a href="matlab:
%   web('https://github.com/fjramireg/MatGen')">the MatGen Web site</a>.

%   Written by Francisco Javier Ramirez-Gil, fjramireg@gmail.com
%   Universidad Nacional de Colombia - Medellin
%   Modified: 04/12/2019. Version: 1.4. Variable number of inputs
%   Modified: 21/01/2019. Version: 1.3
%   Created:  01/12/2018. Version: 1.4

% General variables
dTypeE = classUnderlying(elements);   % Data precision of "elements"
dTypeN = classUnderlying(nodes);      % Data precision of "nodes"
nel = size(elements,2);               % Number of elements
L = dNdrst(dTypeN);                   % Shape functions derivatives in natural coord.

% Check the data type to create the proper CUDA kernel object
% NNZ of type 'single' and indices 'int32', 'uint32'
if ( strcmp(dTypeE,'int32') && strcmp(dTypeN,'single') )        % Indices: 'int32'. NNZ: 'single'
    ker = parallel.gpu.CUDAKernel('Hex8scalarSymGPU.ptx',...    % PTXFILE
        'const int *, const float *, float *',...               % C prototype for kernel
        'Hex8scalarIfi');                                       % Specify entry point
elseif ( strcmp(dTypeE,'uint32') && strcmp(dTypeN,'single') )   % Indices: 'uint32'. NNZ: 'single'
    ker = parallel.gpu.CUDAKernel('Hex8scalarSymGPU.ptx',...
        'const unsigned int *, const float *, float *',...
        'Hex8scalarIfj');
% NNZ of type 'double' and indices 'int32', 'uint32', 'int64', 'uint64', 'double'
elseif ( strcmp(dTypeE,'int32') && strcmp(dTypeN,'double') )    % Indices: 'int32'. NNZ: 'double'
    ker = parallel.gpu.CUDAKernel('Hex8scalarSymGPU.ptx',...
        'const int *, const double *, double *',...
        'Hex8scalarIdi');
elseif ( strcmp(dTypeE,'uint32') && strcmp(dTypeN,'double') )   % Indices: 'uint32'. NNZ: 'double'
    ker = parallel.gpu.CUDAKernel('Hex8scalarSymGPU.ptx',...
        'const unsigned int *, const double *, double *',...
        'Hex8scalarIdj');
elseif ( strcmp(dTypeE,'int64') && strcmp(dTypeN,'double') )    % Indices: 'int64'. NNZ: 'double'
    ker = parallel.gpu.CUDAKernel('Hex8scalarSymGPU.ptx',...
        'const long *, const double *, double *',...
        'Hex8scalarIdl');
elseif ( strcmp(dTypeE,'uint64') && strcmp(dTypeN,'double') )   % Indices: 'uint64'. NNZ: 'double'
    ker = parallel.gpu.CUDAKernel('Hex8scalarSymGPU.ptx',...
        'const unsigned long *, const double *, double *',...
        'Hex8scalarIdm');
elseif ( strcmp(dTypeE,'double') && strcmp(dTypeN,'double') )   % Indices: 'double'. NNZ: 'double'
    ker = parallel.gpu.CUDAKernel('Hex8scalarSymGPU.ptx',...
        'const double *, const double *, double *',...
        'Hex8scalarIdd');
else
    msg = ['Input "elements" must be defined as "int32", "uint32", "int64", "uint64" or "double" ';
           'Input "nodes" must be defined as "single" or "double" '];
    error(msg);
end

% Configure and execute the CUDA kernel
if nargin == 3; tbs = ker.MaxThreadsPerBlock; end                   % Default (MaxThreadsPerBlock)
ker.ThreadBlockSize = [tbs, 1, 1];                                  % Threads per block
ker.GridSize = [ceil(nel/ker.ThreadBlockSize(1)), 1, 1];            % Blocks per grid
setConstantMemory(ker,'L',L,'nel',nel,'c',c);                       % Set constant memory on GPU
KE = feval(ker, elements, nodes, zeros(36*nel,1,dTypeN,'gpuArray'));% GPU code execution
