sets.nel = 300;
sets.dTE = 'uint32';
sets.dTN = 'single';
[Mesh.elements, Mesh.nodes] = CreateMesh2(sets.nel,sets.nel,sets.nel,sets.dTE,sets.dTN);
sets.nel = 27000000;
sets.sz = 36;
sets.edof = 8;
c = 1;
d = gpuDevice;
sets.tbs = d.MaxThreadsPerBlock;
sets.numSMs   = d.MultiprocessorCount;
sets.WarpSize = d.SIMDWidth;
elementsGPU = gpuArray(Mesh.elements');
nodesGPU = gpuArray(Mesh.nodes');

%% EStiff-GPU-Scalar-Symmetry
Ke = eStiff_spsa(elementsGPU, nodesGPU, c, sets);
wait(d);
