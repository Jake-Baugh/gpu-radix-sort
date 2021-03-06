////////////////////////////////////////////////////////////////////////
//
// Instructional Post-Processing Parallel Reduction with DirectCompute
//
// by Wolfgang Engel 
//
// Last time modified: 01/13/2014
//
///////////////////////////////////////////////////////////////////////

/*
#0 is base line
#1 Interleaved Shared Memory Addressing : Divergent Branching
#2 Interleaved Shared Memory Addressing : Shared Memory Bank Conflicts
#3 Idle Threads in Thread Group : First add during Global Load
#4 Instruction Bottleneck : Unroll last Warp
#5 Completely Unroll
*/
#define OPTIMIZATION 4

StructuredBuffer<float4> Input : register(t0);
RWStructuredBuffer<float> Result : register(u0);

#define THREADX 16 / 2
#define THREADY 16 / 2


cbuffer cbCS : register(b0)
{
	int c_height : packoffset(c0.x);
	int c_width : packoffset(c0.y);		// size view port
/*	
	This is in the constant buffer as well but not used in this shader, so I just keep it in here as a comment
	
	float c_epsilon : packoffset(c0.z);	// julia detail  	
	int c_selfShadow : packoffset(c0.w);  // selfshadowing on or off  
	float4 c_diffuse : packoffset(c1);	// diffuse shading color
	float4 c_mu : packoffset(c2);		// julia quaternion parameter
	float4x4 rotation : packoffset(c3);
	float zoom : packoffset(c7.x);
*/
};

//
// the following shader applies parallel reduction to an image and converts it to luminance
//
#define groupthreads THREADX * THREADY
groupshared float sharedMem[groupthreads];

// SV_DispatchThreadID - index of the thread within the entire dispatch in each dimension: x - 0..x - 1; y - 0..y - 1; z - 0..z - 1
// SV_GroupID - index of a thread group in the dispatch — for example, calling Dispatch(2,1,1) results in possible values of 0,0,0 and 1,0,0, varying from 0 to (numthreadsX * numthreadsY * numThreadsZ) – 1
// SV_GroupThreadID - 3D version of SV_GroupIndex - if you specified numthreads(3,2,1), possible values for the SV_GroupThreadID input value have the range of values (0–2,0–1,0)
// SV_GroupIndex - index of a thread within a thread group
[numthreads(THREADX, THREADY, 1)]
void PostFX( uint3 Gid : SV_GroupID, uint3 DTid : SV_DispatchThreadID, uint3 GTid : SV_GroupThreadID, uint GI : SV_GroupIndex  )
{
	const float4 LumVector = float4(0.2125f, 0.7154f, 0.0721f, 0.0f);

	// read from structured buffer
	uint idx = DTid.x + DTid.y * c_width;

	// #3 Idle Threads in Thread Group : First add during Global Load

	// store in shared memory    
	sharedMem[GI] = dot(Input[idx * 2], LumVector) + dot(Input[idx * 2 + 1], LumVector);


	// wait until everything is transfered from device memory to shared memory
	GroupMemoryBarrierWithGroupSync();

	// wonder if this does anything :-)
	[unroll(groupthreads)]
	for (uint s = groupthreads / 2; s > 32; s >>= 1)
	{
		if (GI < s)
		 // store in shared memory    
		 sharedMem[GI] += sharedMem[GI + s];
		GroupMemoryBarrierWithGroupSync();
	}

	if (GI < 32)
	{
		sharedMem[GI] += sharedMem[GI + 32];
		sharedMem[GI] += sharedMem[GI + 16];
		sharedMem[GI] += sharedMem[GI + 8];
		sharedMem[GI] += sharedMem[GI + 2];
		sharedMem[GI] += sharedMem[GI + 1];
	}


	// Have the first thread write out to the output
	if (GI == 0)
	{
		// write out the result for each thread group
		Result[Gid.x + Gid.y*c_width/16] = sharedMem[0] / (THREADX * THREADY);
	}
}
