function K = StiffMatGenVcSymGPU(elements,nodes,E,nu)
% STIFFMATGENVCSYMGPU Create the global stiffness matrix for a VECTOR
% problem taking advantage of simmetry and GPU computing.
%   STIFFMATGENVCSYMGPU(elements,nodes,E,nu) returns the lower-triangle of
%   a sparse matrix K from finite element analysis of vector problems in a
%   three-dimensional domain taking advantage of simmetry and GPU
%   computing, where "elements" is the connectivity matrix, "nodes" the
%   nodal coordinates, and "E" (Young's modulus) and "nu" (Poisson ratio)
%   the material property for an isotropic material.
%
%   See also SPARSE, ACCUMARRAY, STIFFMATGENVC, STIFFMATGENVCSYMCPU, STIFFMATGENVCSYMCPUP
%
%   For more information, see <a href="matlab:
%   web('https://github.com/fjramireg/MatGen')">the MatGen Web site</a>.

%   Written by Francisco Javier Ramirez-Gil, fjramireg@gmail.com
%   Universidad Nacional de Colombia - Medellin
%   Created: 16/01/2019. Modified: 28/01/2019. Version: 1.3

%% General declarations
dTE = classUnderlying(elements);            % "elements" data precision. Defines data type of [iK,jK]
dTN = classUnderlying(nodes);              	% "nodes" data precision. Defines data type of [Ke]
N = size(nodes,2);                          % Total number of nodes

%% Inputs check
if ~(existsOnGPU(elements) && existsOnGPU(nodes)) % Check if "elements" & "nodes" are on GPU memory
    error('Inputs "elements" and "nodes" must be on GPU memory. Use "gpuArray"');
elseif ( size(elements,1)~=8 || size(nodes,1)~=3 )% Check if "elements" & "nodes" are 8xnel & 3xnnod.
    error('Input "elements" must be a 8xnel array, and "nodes" of size 3xnnod');
elseif ~( strcmp(dTE,'int32') || strcmp(dTE,'uint32')... % Check data type for "elements"
        || strcmp(dTE,'int64')  || strcmp(dTE,'uint64') || strcmp(dTE,'double') )
    error('Error. Input "elements" must be "int32", "uint32", "int64", "uint64" or "double" ');
elseif ~strcmp(dTN,'double')                      % Check data type for "nodes"
    error('MATLAB only support "double" sparse matrix, i.e. "nodes" must be of type "double" ');
elseif ~( isscalar(E) && isscalar(nu) )           % Check input "E" and "nu"
    error('Error. Inputs "E" and "nu" must be SCALAR variables');
end

%% Index computation
[iK, jK] = IndexVectorSymGPU(elements);             % Row/column indices of tril(K)

%% Element matrix computation
Ke = Hex8vectorSymGPU(elements,nodes,E,nu);         % Entries of tril(K)

%% Assembly of global sparse matrix on GPU
if ( strcmp(dTE,'double') && strcmp(dTN,'double') )
    K = sparse(iK, jK, Ke, 3*N, 3*N);
else
    K = accumarray([iK,jK], Ke, [3*N,3*N], [], [], 1);
end