------------------------------------------------------------------------------
-- OpenCL for Lua.
-- Copyright © 2013–2015 Peter Colberg.
-- Distributed under the MIT license. (See accompanying file LICENSE.)
------------------------------------------------------------------------------

local ffi = require("ffi")

ffi.cdef[[
typedef int8_t cl_char;
typedef uint8_t cl_uchar;
typedef int16_t cl_short __attribute__((aligned(2)));
typedef uint16_t cl_ushort __attribute__((aligned(2)));
typedef int32_t cl_int __attribute__((aligned(4)));
typedef uint32_t cl_uint __attribute__((aligned(4)));
typedef int64_t cl_long __attribute__((aligned(8)));
typedef uint64_t cl_ulong __attribute__((aligned(8)));
typedef uint16_t cl_half __attribute__((aligned(2)));
typedef float cl_float __attribute__((aligned(4)));
typedef double cl_double __attribute__((aligned(8)));
typedef unsigned int cl_GLuint;
typedef int cl_GLint;
typedef unsigned int cl_GLenum;
typedef union {
  cl_char s[2] __attribute__((aligned(2)));
  struct {
    cl_char x, y;
  };
  struct {
    cl_char s0, s1;
  };
  struct {
    cl_char lo, hi;
  };
  cl_char __attribute__((vector_size(2))) v2;
} cl_char2;
typedef union {
  cl_char s[4] __attribute__((aligned(4)));
  struct {
    cl_char x, y, z, w;
  };
  struct {
    cl_char s0, s1, s2, s3;
  };
  struct {
    cl_char2 lo, hi;
  };
  cl_char __attribute__((vector_size(2))) v2[2];
  cl_char __attribute__((vector_size(4))) v4;
} cl_char4;
typedef cl_char4 cl_char3;
typedef union {
  cl_char s[8] __attribute__((aligned(8)));
  struct {
    cl_char x, y, z, w;
  };
  struct {
    cl_char s0, s1, s2, s3, s4, s5, s6, s7;
  };
  struct {
    cl_char4 lo, hi;
  };
  cl_char __attribute__((vector_size(2))) v2[4];
  cl_char __attribute__((vector_size(4))) v4[2];
  cl_char __attribute__((vector_size(8))) v8;
} cl_char8;
typedef union {
  cl_char s[16] __attribute__((aligned(16)));
  struct {
    cl_char x, y, z, w, __spacer4, __spacer5, __spacer6, __spacer7, __spacer8, __spacer9, sa, sb, sc, sd, se, sf;
  };
  struct {
    cl_char s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, sA, sB, sC, sD, sE, sF;
  };
  struct {
    cl_char8 lo, hi;
  };
  cl_char __attribute__((vector_size(2))) v2[8];
  cl_char __attribute__((vector_size(4))) v4[4];
  cl_char __attribute__((vector_size(8))) v8[2];
  cl_char __attribute__((vector_size(16))) v16;
} cl_char16;
typedef union {
  cl_uchar s[2] __attribute__((aligned(2)));
  struct {
    cl_uchar x, y;
  };
  struct {
    cl_uchar s0, s1;
  };
  struct {
    cl_uchar lo, hi;
  };
  cl_uchar __attribute__((vector_size(2))) v2;
} cl_uchar2;
typedef union {
  cl_uchar s[4] __attribute__((aligned(4)));
  struct {
    cl_uchar x, y, z, w;
  };
  struct {
    cl_uchar s0, s1, s2, s3;
  };
  struct {
    cl_uchar2 lo, hi;
  };
  cl_uchar __attribute__((vector_size(2))) v2[2];
  cl_uchar __attribute__((vector_size(4))) v4;
} cl_uchar4;
typedef cl_uchar4 cl_uchar3;
typedef union {
  cl_uchar s[8] __attribute__((aligned(8)));
  struct {
    cl_uchar x, y, z, w;
  };
  struct {
    cl_uchar s0, s1, s2, s3, s4, s5, s6, s7;
  };
  struct {
    cl_uchar4 lo, hi;
  };
  cl_uchar __attribute__((vector_size(2))) v2[4];
  cl_uchar __attribute__((vector_size(4))) v4[2];
  cl_uchar __attribute__((vector_size(8))) v8;
} cl_uchar8;
typedef union {
  cl_uchar s[16] __attribute__((aligned(16)));
  struct {
    cl_uchar x, y, z, w, __spacer4, __spacer5, __spacer6, __spacer7, __spacer8, __spacer9, sa, sb, sc, sd, se, sf;
  };
  struct {
    cl_uchar s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, sA, sB, sC, sD, sE, sF;
  };
  struct {
    cl_uchar8 lo, hi;
  };
  cl_uchar __attribute__((vector_size(2))) v2[8];
  cl_uchar __attribute__((vector_size(4))) v4[4];
  cl_uchar __attribute__((vector_size(8))) v8[2];
  cl_uchar __attribute__((vector_size(16))) v16;
} cl_uchar16;
typedef union {
  cl_short s[2] __attribute__((aligned(4)));
  struct {
    cl_short x, y;
  };
  struct {
    cl_short s0, s1;
  };
  struct {
    cl_short lo, hi;
  };
  cl_short __attribute__((vector_size(4))) v2;
} cl_short2;
typedef union {
  cl_short s[4] __attribute__((aligned(8)));
  struct {
    cl_short x, y, z, w;
  };
  struct {
    cl_short s0, s1, s2, s3;
  };
  struct {
    cl_short2 lo, hi;
  };
  cl_short __attribute__((vector_size(4))) v2[2];
  cl_short __attribute__((vector_size(8))) v4;
} cl_short4;
typedef cl_short4 cl_short3;
typedef union {
  cl_short s[8] __attribute__((aligned(16)));
  struct {
    cl_short x, y, z, w;
  };
  struct {
    cl_short s0, s1, s2, s3, s4, s5, s6, s7;
  };
  struct {
    cl_short4 lo, hi;
  };
  cl_short __attribute__((vector_size(4))) v2[4];
  cl_short __attribute__((vector_size(8))) v4[2];
  cl_short __attribute__((vector_size(16))) v8;
} cl_short8;
typedef union {
  cl_short s[16] __attribute__((aligned(32)));
  struct {
    cl_short x, y, z, w, __spacer4, __spacer5, __spacer6, __spacer7, __spacer8, __spacer9, sa, sb, sc, sd, se, sf;
  };
  struct {
    cl_short s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, sA, sB, sC, sD, sE, sF;
  };
  struct {
    cl_short8 lo, hi;
  };
  cl_short __attribute__((vector_size(4))) v2[8];
  cl_short __attribute__((vector_size(8))) v4[4];
  cl_short __attribute__((vector_size(16))) v8[2];
  cl_short __attribute__((vector_size(32))) v16;
} cl_short16;
typedef union {
  cl_ushort s[2] __attribute__((aligned(4)));
  struct {
    cl_ushort x, y;
  };
  struct {
    cl_ushort s0, s1;
  };
  struct {
    cl_ushort lo, hi;
  };
  cl_ushort __attribute__((vector_size(4))) v2;
} cl_ushort2;
typedef union {
  cl_ushort s[4] __attribute__((aligned(8)));
  struct {
    cl_ushort x, y, z, w;
  };
  struct {
    cl_ushort s0, s1, s2, s3;
  };
  struct {
    cl_ushort2 lo, hi;
  };
  cl_ushort __attribute__((vector_size(4))) v2[2];
  cl_ushort __attribute__((vector_size(8))) v4;
} cl_ushort4;
typedef cl_ushort4 cl_ushort3;
typedef union {
  cl_ushort s[8] __attribute__((aligned(16)));
  struct {
    cl_ushort x, y, z, w;
  };
  struct {
    cl_ushort s0, s1, s2, s3, s4, s5, s6, s7;
  };
  struct {
    cl_ushort4 lo, hi;
  };
  cl_ushort __attribute__((vector_size(4))) v2[4];
  cl_ushort __attribute__((vector_size(8))) v4[2];
  cl_ushort __attribute__((vector_size(16))) v8;
} cl_ushort8;
typedef union {
  cl_ushort s[16] __attribute__((aligned(32)));
  struct {
    cl_ushort x, y, z, w, __spacer4, __spacer5, __spacer6, __spacer7, __spacer8, __spacer9, sa, sb, sc, sd, se, sf;
  };
  struct {
    cl_ushort s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, sA, sB, sC, sD, sE, sF;
  };
  struct {
    cl_ushort8 lo, hi;
  };
  cl_ushort __attribute__((vector_size(4))) v2[8];
  cl_ushort __attribute__((vector_size(8))) v4[4];
  cl_ushort __attribute__((vector_size(16))) v8[2];
  cl_ushort __attribute__((vector_size(32))) v16;
} cl_ushort16;
typedef union {
  cl_int s[2] __attribute__((aligned(8)));
  struct {
    cl_int x, y;
  };
  struct {
    cl_int s0, s1;
  };
  struct {
    cl_int lo, hi;
  };
  cl_int __attribute__((vector_size(8))) v2;
} cl_int2;
typedef union {
  cl_int s[4] __attribute__((aligned(16)));
  struct {
    cl_int x, y, z, w;
  };
  struct {
    cl_int s0, s1, s2, s3;
  };
  struct {
    cl_int2 lo, hi;
  };
  cl_int __attribute__((vector_size(8))) v2[2];
  cl_int __attribute__((vector_size(16))) v4;
} cl_int4;
typedef cl_int4 cl_int3;
typedef union {
  cl_int s[8] __attribute__((aligned(32)));
  struct {
    cl_int x, y, z, w;
  };
  struct {
    cl_int s0, s1, s2, s3, s4, s5, s6, s7;
  };
  struct {
    cl_int4 lo, hi;
  };
  cl_int __attribute__((vector_size(8))) v2[4];
  cl_int __attribute__((vector_size(16))) v4[2];
  cl_int __attribute__((vector_size(32))) v8;
} cl_int8;
typedef union {
  cl_int s[16] __attribute__((aligned(64)));
  struct {
    cl_int x, y, z, w, __spacer4, __spacer5, __spacer6, __spacer7, __spacer8, __spacer9, sa, sb, sc, sd, se, sf;
  };
  struct {
    cl_int s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, sA, sB, sC, sD, sE, sF;
  };
  struct {
    cl_int8 lo, hi;
  };
  cl_int __attribute__((vector_size(8))) v2[8];
  cl_int __attribute__((vector_size(16))) v4[4];
  cl_int __attribute__((vector_size(32))) v8[2];
  cl_int __attribute__((vector_size(64))) v16;
} cl_int16;
typedef union {
  cl_uint s[2] __attribute__((aligned(8)));
  struct {
    cl_uint x, y;
  };
  struct {
    cl_uint s0, s1;
  };
  struct {
    cl_uint lo, hi;
  };
  cl_uint __attribute__((vector_size(8))) v2;
} cl_uint2;
typedef union {
  cl_uint s[4] __attribute__((aligned(16)));
  struct {
    cl_uint x, y, z, w;
  };
  struct {
    cl_uint s0, s1, s2, s3;
  };
  struct {
    cl_uint2 lo, hi;
  };
  cl_uint __attribute__((vector_size(8))) v2[2];
  cl_uint __attribute__((vector_size(16))) v4;
} cl_uint4;
typedef cl_uint4 cl_uint3;
typedef union {
  cl_uint s[8] __attribute__((aligned(32)));
  struct {
    cl_uint x, y, z, w;
  };
  struct {
    cl_uint s0, s1, s2, s3, s4, s5, s6, s7;
  };
  struct {
    cl_uint4 lo, hi;
  };
  cl_uint __attribute__((vector_size(8))) v2[4];
  cl_uint __attribute__((vector_size(16))) v4[2];
  cl_uint __attribute__((vector_size(32))) v8;
} cl_uint8;
typedef union {
  cl_uint s[16] __attribute__((aligned(64)));
  struct {
    cl_uint x, y, z, w, __spacer4, __spacer5, __spacer6, __spacer7, __spacer8, __spacer9, sa, sb, sc, sd, se, sf;
  };
  struct {
    cl_uint s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, sA, sB, sC, sD, sE, sF;
  };
  struct {
    cl_uint8 lo, hi;
  };
  cl_uint __attribute__((vector_size(8))) v2[8];
  cl_uint __attribute__((vector_size(16))) v4[4];
  cl_uint __attribute__((vector_size(32))) v8[2];
  cl_uint __attribute__((vector_size(64))) v16;
} cl_uint16;
typedef union {
  cl_long s[2] __attribute__((aligned(16)));
  struct {
    cl_long x, y;
  };
  struct {
    cl_long s0, s1;
  };
  struct {
    cl_long lo, hi;
  };
  cl_long __attribute__((vector_size(16))) v2;
} cl_long2;
typedef union {
  cl_long s[4] __attribute__((aligned(32)));
  struct {
    cl_long x, y, z, w;
  };
  struct {
    cl_long s0, s1, s2, s3;
  };
  struct {
    cl_long2 lo, hi;
  };
  cl_long __attribute__((vector_size(16))) v2[2];
  cl_long __attribute__((vector_size(32))) v4;
} cl_long4;
typedef cl_long4 cl_long3;
typedef union {
  cl_long s[8] __attribute__((aligned(64)));
  struct {
    cl_long x, y, z, w;
  };
  struct {
    cl_long s0, s1, s2, s3, s4, s5, s6, s7;
  };
  struct {
    cl_long4 lo, hi;
  };
  cl_long __attribute__((vector_size(16))) v2[4];
  cl_long __attribute__((vector_size(32))) v4[2];
  cl_long __attribute__((vector_size(64))) v8;
} cl_long8;
typedef union {
  cl_long s[16] __attribute__((aligned(128)));
  struct {
    cl_long x, y, z, w, __spacer4, __spacer5, __spacer6, __spacer7, __spacer8, __spacer9, sa, sb, sc, sd, se, sf;
  };
  struct {
    cl_long s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, sA, sB, sC, sD, sE, sF;
  };
  struct {
    cl_long8 lo, hi;
  };
  cl_long __attribute__((vector_size(16))) v2[8];
  cl_long __attribute__((vector_size(32))) v4[4];
  cl_long __attribute__((vector_size(64))) v8[2];
  cl_long __attribute__((vector_size(128))) v16;
} cl_long16;
typedef union {
  cl_ulong s[2] __attribute__((aligned(16)));
  struct {
    cl_ulong x, y;
  };
  struct {
    cl_ulong s0, s1;
  };
  struct {
    cl_ulong lo, hi;
  };
  cl_ulong __attribute__((vector_size(16))) v2;
} cl_ulong2;
typedef union {
  cl_ulong s[4] __attribute__((aligned(32)));
  struct {
    cl_ulong x, y, z, w;
  };
  struct {
    cl_ulong s0, s1, s2, s3;
  };
  struct {
    cl_ulong2 lo, hi;
  };
  cl_ulong __attribute__((vector_size(16))) v2[2];
  cl_ulong __attribute__((vector_size(32))) v4;
} cl_ulong4;
typedef cl_ulong4 cl_ulong3;
typedef union {
  cl_ulong s[8] __attribute__((aligned(64)));
  struct {
    cl_ulong x, y, z, w;
  };
  struct {
    cl_ulong s0, s1, s2, s3, s4, s5, s6, s7;
  };
  struct {
    cl_ulong4 lo, hi;
  };
  cl_ulong __attribute__((vector_size(16))) v2[4];
  cl_ulong __attribute__((vector_size(32))) v4[2];
  cl_ulong __attribute__((vector_size(64))) v8;
} cl_ulong8;
typedef union {
  cl_ulong s[16] __attribute__((aligned(128)));
  struct {
    cl_ulong x, y, z, w, __spacer4, __spacer5, __spacer6, __spacer7, __spacer8, __spacer9, sa, sb, sc, sd, se, sf;
  };
  struct {
    cl_ulong s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, sA, sB, sC, sD, sE, sF;
  };
  struct {
    cl_ulong8 lo, hi;
  };
  cl_ulong __attribute__((vector_size(16))) v2[8];
  cl_ulong __attribute__((vector_size(32))) v4[4];
  cl_ulong __attribute__((vector_size(64))) v8[2];
  cl_ulong __attribute__((vector_size(128))) v16;
} cl_ulong16;
typedef union {
  cl_float s[2] __attribute__((aligned(8)));
  struct {
    cl_float x, y;
  };
  struct {
    cl_float s0, s1;
  };
  struct {
    cl_float lo, hi;
  };
  cl_float __attribute__((vector_size(8))) v2;
} cl_float2;
typedef union {
  cl_float s[4] __attribute__((aligned(16)));
  struct {
    cl_float x, y, z, w;
  };
  struct {
    cl_float s0, s1, s2, s3;
  };
  struct {
    cl_float2 lo, hi;
  };
  cl_float __attribute__((vector_size(8))) v2[2];
  cl_float __attribute__((vector_size(16))) v4;
} cl_float4;
typedef cl_float4 cl_float3;
typedef union {
  cl_float s[8] __attribute__((aligned(32)));
  struct {
    cl_float x, y, z, w;
  };
  struct {
    cl_float s0, s1, s2, s3, s4, s5, s6, s7;
  };
  struct {
    cl_float4 lo, hi;
  };
  cl_float __attribute__((vector_size(8))) v2[4];
  cl_float __attribute__((vector_size(16))) v4[2];
  cl_float __attribute__((vector_size(32))) v8;
} cl_float8;
typedef union {
  cl_float s[16] __attribute__((aligned(64)));
  struct {
    cl_float x, y, z, w, __spacer4, __spacer5, __spacer6, __spacer7, __spacer8, __spacer9, sa, sb, sc, sd, se, sf;
  };
  struct {
    cl_float s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, sA, sB, sC, sD, sE, sF;
  };
  struct {
    cl_float8 lo, hi;
  };
  cl_float __attribute__((vector_size(8))) v2[8];
  cl_float __attribute__((vector_size(16))) v4[4];
  cl_float __attribute__((vector_size(32))) v8[2];
  cl_float __attribute__((vector_size(64))) v16;
} cl_float16;
typedef union {
  cl_double s[2] __attribute__((aligned(16)));
  struct {
    cl_double x, y;
  };
  struct {
    cl_double s0, s1;
  };
  struct {
    cl_double lo, hi;
  };
  cl_double __attribute__((vector_size(16))) v2;
} cl_double2;
typedef union {
  cl_double s[4] __attribute__((aligned(32)));
  struct {
    cl_double x, y, z, w;
  };
  struct {
    cl_double s0, s1, s2, s3;
  };
  struct {
    cl_double2 lo, hi;
  };
  cl_double __attribute__((vector_size(16))) v2[2];
  cl_double __attribute__((vector_size(32))) v4;
} cl_double4;
typedef cl_double4 cl_double3;
typedef union {
  cl_double s[8] __attribute__((aligned(64)));
  struct {
    cl_double x, y, z, w;
  };
  struct {
    cl_double s0, s1, s2, s3, s4, s5, s6, s7;
  };
  struct {
    cl_double4 lo, hi;
  };
  cl_double __attribute__((vector_size(16))) v2[4];
  cl_double __attribute__((vector_size(32))) v4[2];
  cl_double __attribute__((vector_size(64))) v8;
} cl_double8;
typedef union {
  cl_double s[16] __attribute__((aligned(128)));
  struct {
    cl_double x, y, z, w, __spacer4, __spacer5, __spacer6, __spacer7, __spacer8, __spacer9, sa, sb, sc, sd, se, sf;
  };
  struct {
    cl_double s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, sA, sB, sC, sD, sE, sF;
  };
  struct {
    cl_double8 lo, hi;
  };
  cl_double __attribute__((vector_size(16))) v2[8];
  cl_double __attribute__((vector_size(32))) v4[4];
  cl_double __attribute__((vector_size(64))) v8[2];
  cl_double __attribute__((vector_size(128))) v16;
} cl_double16;
typedef struct _cl_platform_id *cl_platform_id;
typedef struct _cl_device_id *cl_device_id;
typedef struct _cl_context *cl_context;
typedef struct _cl_command_queue *cl_command_queue;
typedef struct _cl_mem *cl_mem;
typedef struct _cl_program *cl_program;
typedef struct _cl_kernel *cl_kernel;
typedef struct _cl_event *cl_event;
typedef struct _cl_sampler *cl_sampler;
typedef cl_uint cl_bool;
typedef cl_ulong cl_bitfield;
typedef cl_bitfield cl_device_type;
typedef cl_uint cl_platform_info;
typedef cl_uint cl_device_info;
typedef cl_bitfield cl_device_fp_config;
typedef cl_uint cl_device_mem_cache_type;
typedef cl_uint cl_device_local_mem_type;
typedef cl_bitfield cl_device_exec_capabilities;
typedef cl_bitfield cl_command_queue_properties;
typedef intptr_t cl_device_partition_property;
typedef cl_bitfield cl_device_affinity_domain;
typedef intptr_t cl_context_properties;
typedef cl_uint cl_context_info;
typedef cl_uint cl_command_queue_info;
typedef cl_uint cl_channel_order;
typedef cl_uint cl_channel_type;
typedef cl_bitfield cl_mem_flags;
typedef cl_uint cl_mem_object_type;
typedef cl_uint cl_mem_info;
typedef cl_bitfield cl_mem_migration_flags;
typedef cl_uint cl_image_info;
typedef cl_uint cl_buffer_create_type;
typedef cl_uint cl_addressing_mode;
typedef cl_uint cl_filter_mode;
typedef cl_uint cl_sampler_info;
typedef cl_bitfield cl_map_flags;
typedef cl_uint cl_program_info;
typedef cl_uint cl_program_build_info;
typedef cl_uint cl_program_binary_type;
typedef cl_int cl_build_status;
typedef cl_uint cl_kernel_info;
typedef cl_uint cl_kernel_arg_info;
typedef cl_uint cl_kernel_arg_address_qualifier;
typedef cl_uint cl_kernel_arg_access_qualifier;
typedef cl_bitfield cl_kernel_arg_type_qualifier;
typedef cl_uint cl_kernel_work_group_info;
typedef cl_uint cl_event_info;
typedef cl_uint cl_command_type;
typedef cl_uint cl_profiling_info;
typedef struct cl_image_format cl_image_format;
struct cl_image_format {
  cl_channel_order image_channel_order;
  cl_channel_type image_channel_data_type;
};
typedef struct cl_image_desc cl_image_desc;
struct cl_image_desc {
  cl_mem_object_type image_type;
  size_t image_width;
  size_t image_height;
  size_t image_depth;
  size_t image_array_size;
  size_t image_row_pitch;
  size_t image_slice_pitch;
  cl_uint num_mip_levels;
  cl_uint num_samples;
  cl_mem mem_object;
};
typedef struct cl_buffer_region cl_buffer_region;
struct cl_buffer_region {
  size_t origin;
  size_t size;
};
static const int CL_SUCCESS = 0;
static const int CL_DEVICE_NOT_FOUND = -1;
static const int CL_DEVICE_NOT_AVAILABLE = -2;
static const int CL_COMPILER_NOT_AVAILABLE = -3;
static const int CL_MEM_OBJECT_ALLOCATION_FAILURE = -4;
static const int CL_OUT_OF_RESOURCES = -5;
static const int CL_OUT_OF_HOST_MEMORY = -6;
static const int CL_PROFILING_INFO_NOT_AVAILABLE = -7;
static const int CL_MEM_COPY_OVERLAP = -8;
static const int CL_IMAGE_FORMAT_MISMATCH = -9;
static const int CL_IMAGE_FORMAT_NOT_SUPPORTED = -10;
static const int CL_BUILD_PROGRAM_FAILURE = -11;
static const int CL_MAP_FAILURE = -12;
static const int CL_MISALIGNED_SUB_BUFFER_OFFSET = -13;
static const int CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST = -14;
static const int CL_COMPILE_PROGRAM_FAILURE = -15;
static const int CL_LINKER_NOT_AVAILABLE = -16;
static const int CL_LINK_PROGRAM_FAILURE = -17;
static const int CL_DEVICE_PARTITION_FAILED = -18;
static const int CL_KERNEL_ARG_INFO_NOT_AVAILABLE = -19;
static const int CL_INVALID_VALUE = -30;
static const int CL_INVALID_DEVICE_TYPE = -31;
static const int CL_INVALID_PLATFORM = -32;
static const int CL_INVALID_DEVICE = -33;
static const int CL_INVALID_CONTEXT = -34;
static const int CL_INVALID_QUEUE_PROPERTIES = -35;
static const int CL_INVALID_COMMAND_QUEUE = -36;
static const int CL_INVALID_HOST_PTR = -37;
static const int CL_INVALID_MEM_OBJECT = -38;
static const int CL_INVALID_IMAGE_FORMAT_DESCRIPTOR = -39;
static const int CL_INVALID_IMAGE_SIZE = -40;
static const int CL_INVALID_SAMPLER = -41;
static const int CL_INVALID_BINARY = -42;
static const int CL_INVALID_BUILD_OPTIONS = -43;
static const int CL_INVALID_PROGRAM = -44;
static const int CL_INVALID_PROGRAM_EXECUTABLE = -45;
static const int CL_INVALID_KERNEL_NAME = -46;
static const int CL_INVALID_KERNEL_DEFINITION = -47;
static const int CL_INVALID_KERNEL = -48;
static const int CL_INVALID_ARG_INDEX = -49;
static const int CL_INVALID_ARG_VALUE = -50;
static const int CL_INVALID_ARG_SIZE = -51;
static const int CL_INVALID_KERNEL_ARGS = -52;
static const int CL_INVALID_WORK_DIMENSION = -53;
static const int CL_INVALID_WORK_GROUP_SIZE = -54;
static const int CL_INVALID_WORK_ITEM_SIZE = -55;
static const int CL_INVALID_GLOBAL_OFFSET = -56;
static const int CL_INVALID_EVENT_WAIT_LIST = -57;
static const int CL_INVALID_EVENT = -58;
static const int CL_INVALID_OPERATION = -59;
static const int CL_INVALID_GL_OBJECT = -60;
static const int CL_INVALID_BUFFER_SIZE = -61;
static const int CL_INVALID_MIP_LEVEL = -62;
static const int CL_INVALID_GLOBAL_WORK_SIZE = -63;
static const int CL_INVALID_PROPERTY = -64;
static const int CL_INVALID_IMAGE_DESCRIPTOR = -65;
static const int CL_INVALID_COMPILER_OPTIONS = -66;
static const int CL_INVALID_LINKER_OPTIONS = -67;
static const int CL_INVALID_DEVICE_PARTITION_COUNT = -68;
static const int CL_VERSION_1_0 = 1;
static const int CL_VERSION_1_1 = 1;
static const int CL_VERSION_1_2 = 1;
static const int CL_FALSE = 0;
static const int CL_TRUE = 1;
static const int CL_BLOCKING = CL_TRUE;
static const int CL_NON_BLOCKING = CL_FALSE;
static const int CL_PLATFORM_PROFILE = 0x0900;
static const int CL_PLATFORM_VERSION = 0x0901;
static const int CL_PLATFORM_NAME = 0x0902;
static const int CL_PLATFORM_VENDOR = 0x0903;
static const int CL_PLATFORM_EXTENSIONS = 0x0904;
static const int CL_DEVICE_TYPE_DEFAULT = (1 << 0);
static const int CL_DEVICE_TYPE_CPU = (1 << 1);
static const int CL_DEVICE_TYPE_GPU = (1 << 2);
static const int CL_DEVICE_TYPE_ACCELERATOR = (1 << 3);
static const int CL_DEVICE_TYPE_CUSTOM = (1 << 4);
static const uint32_t CL_DEVICE_TYPE_ALL = 0xFFFFFFFF;
static const int CL_DEVICE_TYPE = 0x1000;
static const int CL_DEVICE_VENDOR_ID = 0x1001;
static const int CL_DEVICE_MAX_COMPUTE_UNITS = 0x1002;
static const int CL_DEVICE_MAX_WORK_ITEM_DIMENSIONS = 0x1003;
static const int CL_DEVICE_MAX_WORK_GROUP_SIZE = 0x1004;
static const int CL_DEVICE_MAX_WORK_ITEM_SIZES = 0x1005;
static const int CL_DEVICE_PREFERRED_VECTOR_WIDTH_CHAR = 0x1006;
static const int CL_DEVICE_PREFERRED_VECTOR_WIDTH_SHORT = 0x1007;
static const int CL_DEVICE_PREFERRED_VECTOR_WIDTH_INT = 0x1008;
static const int CL_DEVICE_PREFERRED_VECTOR_WIDTH_LONG = 0x1009;
static const int CL_DEVICE_PREFERRED_VECTOR_WIDTH_FLOAT = 0x100A;
static const int CL_DEVICE_PREFERRED_VECTOR_WIDTH_DOUBLE = 0x100B;
static const int CL_DEVICE_MAX_CLOCK_FREQUENCY = 0x100C;
static const int CL_DEVICE_ADDRESS_BITS = 0x100D;
static const int CL_DEVICE_MAX_READ_IMAGE_ARGS = 0x100E;
static const int CL_DEVICE_MAX_WRITE_IMAGE_ARGS = 0x100F;
static const int CL_DEVICE_MAX_MEM_ALLOC_SIZE = 0x1010;
static const int CL_DEVICE_IMAGE2D_MAX_WIDTH = 0x1011;
static const int CL_DEVICE_IMAGE2D_MAX_HEIGHT = 0x1012;
static const int CL_DEVICE_IMAGE3D_MAX_WIDTH = 0x1013;
static const int CL_DEVICE_IMAGE3D_MAX_HEIGHT = 0x1014;
static const int CL_DEVICE_IMAGE3D_MAX_DEPTH = 0x1015;
static const int CL_DEVICE_IMAGE_SUPPORT = 0x1016;
static const int CL_DEVICE_MAX_PARAMETER_SIZE = 0x1017;
static const int CL_DEVICE_MAX_SAMPLERS = 0x1018;
static const int CL_DEVICE_MEM_BASE_ADDR_ALIGN = 0x1019;
static const int CL_DEVICE_MIN_DATA_TYPE_ALIGN_SIZE = 0x101A;
static const int CL_DEVICE_SINGLE_FP_CONFIG = 0x101B;
static const int CL_DEVICE_GLOBAL_MEM_CACHE_TYPE = 0x101C;
static const int CL_DEVICE_GLOBAL_MEM_CACHELINE_SIZE = 0x101D;
static const int CL_DEVICE_GLOBAL_MEM_CACHE_SIZE = 0x101E;
static const int CL_DEVICE_GLOBAL_MEM_SIZE = 0x101F;
static const int CL_DEVICE_MAX_CONSTANT_BUFFER_SIZE = 0x1020;
static const int CL_DEVICE_MAX_CONSTANT_ARGS = 0x1021;
static const int CL_DEVICE_LOCAL_MEM_TYPE = 0x1022;
static const int CL_DEVICE_LOCAL_MEM_SIZE = 0x1023;
static const int CL_DEVICE_ERROR_CORRECTION_SUPPORT = 0x1024;
static const int CL_DEVICE_PROFILING_TIMER_RESOLUTION = 0x1025;
static const int CL_DEVICE_ENDIAN_LITTLE = 0x1026;
static const int CL_DEVICE_AVAILABLE = 0x1027;
static const int CL_DEVICE_COMPILER_AVAILABLE = 0x1028;
static const int CL_DEVICE_EXECUTION_CAPABILITIES = 0x1029;
static const int CL_DEVICE_QUEUE_PROPERTIES = 0x102A;
static const int CL_DEVICE_NAME = 0x102B;
static const int CL_DEVICE_VENDOR = 0x102C;
static const int CL_DRIVER_VERSION = 0x102D;
static const int CL_DEVICE_PROFILE = 0x102E;
static const int CL_DEVICE_VERSION = 0x102F;
static const int CL_DEVICE_EXTENSIONS = 0x1030;
static const int CL_DEVICE_PLATFORM = 0x1031;
static const int CL_DEVICE_DOUBLE_FP_CONFIG = 0x1032;
static const int CL_DEVICE_PREFERRED_VECTOR_WIDTH_HALF = 0x1034;
static const int CL_DEVICE_HOST_UNIFIED_MEMORY = 0x1035;
static const int CL_DEVICE_HALF_FP_CONFIG = 0x1033;
static const int CL_DEVICE_NATIVE_VECTOR_WIDTH_CHAR = 0x1036;
static const int CL_DEVICE_NATIVE_VECTOR_WIDTH_SHORT = 0x1037;
static const int CL_DEVICE_NATIVE_VECTOR_WIDTH_INT = 0x1038;
static const int CL_DEVICE_NATIVE_VECTOR_WIDTH_LONG = 0x1039;
static const int CL_DEVICE_NATIVE_VECTOR_WIDTH_FLOAT = 0x103A;
static const int CL_DEVICE_NATIVE_VECTOR_WIDTH_DOUBLE = 0x103B;
static const int CL_DEVICE_NATIVE_VECTOR_WIDTH_HALF = 0x103C;
static const int CL_DEVICE_OPENCL_C_VERSION = 0x103D;
static const int CL_DEVICE_LINKER_AVAILABLE = 0x103E;
static const int CL_DEVICE_BUILT_IN_KERNELS = 0x103F;
static const int CL_DEVICE_IMAGE_MAX_BUFFER_SIZE = 0x1040;
static const int CL_DEVICE_IMAGE_MAX_ARRAY_SIZE = 0x1041;
static const int CL_DEVICE_PARENT_DEVICE = 0x1042;
static const int CL_DEVICE_PARTITION_MAX_SUB_DEVICES = 0x1043;
static const int CL_DEVICE_PARTITION_PROPERTIES = 0x1044;
static const int CL_DEVICE_PARTITION_AFFINITY_DOMAIN = 0x1045;
static const int CL_DEVICE_PARTITION_TYPE = 0x1046;
static const int CL_DEVICE_REFERENCE_COUNT = 0x1047;
static const int CL_DEVICE_PREFERRED_INTEROP_USER_SYNC = 0x1048;
static const int CL_DEVICE_PRINTF_BUFFER_SIZE = 0x1049;
static const int CL_DEVICE_IMAGE_PITCH_ALIGNMENT = 0x104A;
static const int CL_DEVICE_IMAGE_BASE_ADDRESS_ALIGNMENT = 0x104B;
static const int CL_FP_DENORM = (1 << 0);
static const int CL_FP_INF_NAN = (1 << 1);
static const int CL_FP_ROUND_TO_NEAREST = (1 << 2);
static const int CL_FP_ROUND_TO_ZERO = (1 << 3);
static const int CL_FP_ROUND_TO_INF = (1 << 4);
static const int CL_FP_FMA = (1 << 5);
static const int CL_FP_SOFT_FLOAT = (1 << 6);
static const int CL_FP_CORRECTLY_ROUNDED_DIVIDE_SQRT = (1 << 7);
static const int CL_NONE = 0x0;
static const int CL_READ_ONLY_CACHE = 0x1;
static const int CL_READ_WRITE_CACHE = 0x2;
static const int CL_LOCAL = 0x1;
static const int CL_GLOBAL = 0x2;
static const int CL_EXEC_KERNEL = (1 << 0);
static const int CL_EXEC_NATIVE_KERNEL = (1 << 1);
static const int CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE = (1 << 0);
static const int CL_QUEUE_PROFILING_ENABLE = (1 << 1);
static const int CL_CONTEXT_REFERENCE_COUNT = 0x1080;
static const int CL_CONTEXT_DEVICES = 0x1081;
static const int CL_CONTEXT_PROPERTIES = 0x1082;
static const int CL_CONTEXT_NUM_DEVICES = 0x1083;
static const int CL_CONTEXT_PLATFORM = 0x1084;
static const int CL_CONTEXT_INTEROP_USER_SYNC = 0x1085;
static const int CL_DEVICE_PARTITION_EQUALLY = 0x1086;
static const int CL_DEVICE_PARTITION_BY_COUNTS = 0x1087;
static const int CL_DEVICE_PARTITION_BY_COUNTS_LIST_END = 0x0;
static const int CL_DEVICE_PARTITION_BY_AFFINITY_DOMAIN = 0x1088;
static const int CL_DEVICE_AFFINITY_DOMAIN_NUMA = (1 << 0);
static const int CL_DEVICE_AFFINITY_DOMAIN_L4_CACHE = (1 << 1);
static const int CL_DEVICE_AFFINITY_DOMAIN_L3_CACHE = (1 << 2);
static const int CL_DEVICE_AFFINITY_DOMAIN_L2_CACHE = (1 << 3);
static const int CL_DEVICE_AFFINITY_DOMAIN_L1_CACHE = (1 << 4);
static const int CL_DEVICE_AFFINITY_DOMAIN_NEXT_PARTITIONABLE = (1 << 5);
static const int CL_QUEUE_CONTEXT = 0x1090;
static const int CL_QUEUE_DEVICE = 0x1091;
static const int CL_QUEUE_REFERENCE_COUNT = 0x1092;
static const int CL_QUEUE_PROPERTIES = 0x1093;
static const int CL_MEM_READ_WRITE = (1 << 0);
static const int CL_MEM_WRITE_ONLY = (1 << 1);
static const int CL_MEM_READ_ONLY = (1 << 2);
static const int CL_MEM_USE_HOST_PTR = (1 << 3);
static const int CL_MEM_ALLOC_HOST_PTR = (1 << 4);
static const int CL_MEM_COPY_HOST_PTR = (1 << 5);
static const int CL_MEM_HOST_WRITE_ONLY = (1 << 7);
static const int CL_MEM_HOST_READ_ONLY = (1 << 8);
static const int CL_MEM_HOST_NO_ACCESS = (1 << 9);
static const int CL_MIGRATE_MEM_OBJECT_HOST = (1 << 0);
static const int CL_MIGRATE_MEM_OBJECT_CONTENT_UNDEFINED = (1 << 1);
static const int CL_R = 0x10B0;
static const int CL_A = 0x10B1;
static const int CL_RG = 0x10B2;
static const int CL_RA = 0x10B3;
static const int CL_RGB = 0x10B4;
static const int CL_RGBA = 0x10B5;
static const int CL_BGRA = 0x10B6;
static const int CL_ARGB = 0x10B7;
static const int CL_INTENSITY = 0x10B8;
static const int CL_LUMINANCE = 0x10B9;
static const int CL_Rx = 0x10BA;
static const int CL_RGx = 0x10BB;
static const int CL_RGBx = 0x10BC;
static const int CL_DEPTH = 0x10BD;
static const int CL_DEPTH_STENCIL = 0x10BE;
static const int CL_SNORM_INT8 = 0x10D0;
static const int CL_SNORM_INT16 = 0x10D1;
static const int CL_UNORM_INT8 = 0x10D2;
static const int CL_UNORM_INT16 = 0x10D3;
static const int CL_UNORM_SHORT_565 = 0x10D4;
static const int CL_UNORM_SHORT_555 = 0x10D5;
static const int CL_UNORM_INT_101010 = 0x10D6;
static const int CL_SIGNED_INT8 = 0x10D7;
static const int CL_SIGNED_INT16 = 0x10D8;
static const int CL_SIGNED_INT32 = 0x10D9;
static const int CL_UNSIGNED_INT8 = 0x10DA;
static const int CL_UNSIGNED_INT16 = 0x10DB;
static const int CL_UNSIGNED_INT32 = 0x10DC;
static const int CL_HALF_FLOAT = 0x10DD;
static const int CL_FLOAT = 0x10DE;
static const int CL_UNORM_INT24 = 0x10DF;
static const int CL_MEM_OBJECT_BUFFER = 0x10F0;
static const int CL_MEM_OBJECT_IMAGE2D = 0x10F1;
static const int CL_MEM_OBJECT_IMAGE3D = 0x10F2;
static const int CL_MEM_OBJECT_IMAGE2D_ARRAY = 0x10F3;
static const int CL_MEM_OBJECT_IMAGE1D = 0x10F4;
static const int CL_MEM_OBJECT_IMAGE1D_ARRAY = 0x10F5;
static const int CL_MEM_OBJECT_IMAGE1D_BUFFER = 0x10F6;
static const int CL_MEM_TYPE = 0x1100;
static const int CL_MEM_FLAGS = 0x1101;
static const int CL_MEM_SIZE = 0x1102;
static const int CL_MEM_HOST_PTR = 0x1103;
static const int CL_MEM_MAP_COUNT = 0x1104;
static const int CL_MEM_REFERENCE_COUNT = 0x1105;
static const int CL_MEM_CONTEXT = 0x1106;
static const int CL_MEM_ASSOCIATED_MEMOBJECT = 0x1107;
static const int CL_MEM_OFFSET = 0x1108;
static const int CL_IMAGE_FORMAT = 0x1110;
static const int CL_IMAGE_ELEMENT_SIZE = 0x1111;
static const int CL_IMAGE_ROW_PITCH = 0x1112;
static const int CL_IMAGE_SLICE_PITCH = 0x1113;
static const int CL_IMAGE_WIDTH = 0x1114;
static const int CL_IMAGE_HEIGHT = 0x1115;
static const int CL_IMAGE_DEPTH = 0x1116;
static const int CL_IMAGE_ARRAY_SIZE = 0x1117;
static const int CL_IMAGE_BUFFER = 0x1118;
static const int CL_IMAGE_NUM_MIP_LEVELS = 0x1119;
static const int CL_IMAGE_NUM_SAMPLES = 0x111A;
static const int CL_ADDRESS_NONE = 0x1130;
static const int CL_ADDRESS_CLAMP_TO_EDGE = 0x1131;
static const int CL_ADDRESS_CLAMP = 0x1132;
static const int CL_ADDRESS_REPEAT = 0x1133;
static const int CL_ADDRESS_MIRRORED_REPEAT = 0x1134;
static const int CL_FILTER_NEAREST = 0x1140;
static const int CL_FILTER_LINEAR = 0x1141;
static const int CL_SAMPLER_REFERENCE_COUNT = 0x1150;
static const int CL_SAMPLER_CONTEXT = 0x1151;
static const int CL_SAMPLER_NORMALIZED_COORDS = 0x1152;
static const int CL_SAMPLER_ADDRESSING_MODE = 0x1153;
static const int CL_SAMPLER_FILTER_MODE = 0x1154;
static const int CL_MAP_READ = (1 << 0);
static const int CL_MAP_WRITE = (1 << 1);
static const int CL_MAP_WRITE_INVALIDATE_REGION = (1 << 2);
static const int CL_PROGRAM_REFERENCE_COUNT = 0x1160;
static const int CL_PROGRAM_CONTEXT = 0x1161;
static const int CL_PROGRAM_NUM_DEVICES = 0x1162;
static const int CL_PROGRAM_DEVICES = 0x1163;
static const int CL_PROGRAM_SOURCE = 0x1164;
static const int CL_PROGRAM_BINARY_SIZES = 0x1165;
static const int CL_PROGRAM_BINARIES = 0x1166;
static const int CL_PROGRAM_NUM_KERNELS = 0x1167;
static const int CL_PROGRAM_KERNEL_NAMES = 0x1168;
static const int CL_PROGRAM_BUILD_STATUS = 0x1181;
static const int CL_PROGRAM_BUILD_OPTIONS = 0x1182;
static const int CL_PROGRAM_BUILD_LOG = 0x1183;
static const int CL_PROGRAM_BINARY_TYPE = 0x1184;
static const int CL_PROGRAM_BINARY_TYPE_NONE = 0x0;
static const int CL_PROGRAM_BINARY_TYPE_COMPILED_OBJECT = 0x1;
static const int CL_PROGRAM_BINARY_TYPE_LIBRARY = 0x2;
static const int CL_PROGRAM_BINARY_TYPE_EXECUTABLE = 0x4;
static const int CL_BUILD_SUCCESS = 0;
static const int CL_BUILD_NONE = -1;
static const int CL_BUILD_ERROR = -2;
static const int CL_BUILD_IN_PROGRESS = -3;
static const int CL_KERNEL_FUNCTION_NAME = 0x1190;
static const int CL_KERNEL_NUM_ARGS = 0x1191;
static const int CL_KERNEL_REFERENCE_COUNT = 0x1192;
static const int CL_KERNEL_CONTEXT = 0x1193;
static const int CL_KERNEL_PROGRAM = 0x1194;
static const int CL_KERNEL_ATTRIBUTES = 0x1195;
static const int CL_KERNEL_ARG_ADDRESS_QUALIFIER = 0x1196;
static const int CL_KERNEL_ARG_ACCESS_QUALIFIER = 0x1197;
static const int CL_KERNEL_ARG_TYPE_NAME = 0x1198;
static const int CL_KERNEL_ARG_TYPE_QUALIFIER = 0x1199;
static const int CL_KERNEL_ARG_NAME = 0x119A;
static const int CL_KERNEL_ARG_ADDRESS_GLOBAL = 0x119B;
static const int CL_KERNEL_ARG_ADDRESS_LOCAL = 0x119C;
static const int CL_KERNEL_ARG_ADDRESS_CONSTANT = 0x119D;
static const int CL_KERNEL_ARG_ADDRESS_PRIVATE = 0x119E;
static const int CL_KERNEL_ARG_ACCESS_READ_ONLY = 0x11A0;
static const int CL_KERNEL_ARG_ACCESS_WRITE_ONLY = 0x11A1;
static const int CL_KERNEL_ARG_ACCESS_READ_WRITE = 0x11A2;
static const int CL_KERNEL_ARG_ACCESS_NONE = 0x11A3;
static const int CL_KERNEL_ARG_TYPE_NONE = 0;
static const int CL_KERNEL_ARG_TYPE_CONST = (1 << 0);
static const int CL_KERNEL_ARG_TYPE_RESTRICT = (1 << 1);
static const int CL_KERNEL_ARG_TYPE_VOLATILE = (1 << 2);
static const int CL_KERNEL_WORK_GROUP_SIZE = 0x11B0;
static const int CL_KERNEL_COMPILE_WORK_GROUP_SIZE = 0x11B1;
static const int CL_KERNEL_LOCAL_MEM_SIZE = 0x11B2;
static const int CL_KERNEL_PREFERRED_WORK_GROUP_SIZE_MULTIPLE = 0x11B3;
static const int CL_KERNEL_PRIVATE_MEM_SIZE = 0x11B4;
static const int CL_KERNEL_GLOBAL_WORK_SIZE = 0x11B5;
static const int CL_EVENT_COMMAND_QUEUE = 0x11D0;
static const int CL_EVENT_COMMAND_TYPE = 0x11D1;
static const int CL_EVENT_REFERENCE_COUNT = 0x11D2;
static const int CL_EVENT_COMMAND_EXECUTION_STATUS = 0x11D3;
static const int CL_EVENT_CONTEXT = 0x11D4;
static const int CL_COMMAND_NDRANGE_KERNEL = 0x11F0;
static const int CL_COMMAND_TASK = 0x11F1;
static const int CL_COMMAND_NATIVE_KERNEL = 0x11F2;
static const int CL_COMMAND_READ_BUFFER = 0x11F3;
static const int CL_COMMAND_WRITE_BUFFER = 0x11F4;
static const int CL_COMMAND_COPY_BUFFER = 0x11F5;
static const int CL_COMMAND_READ_IMAGE = 0x11F6;
static const int CL_COMMAND_WRITE_IMAGE = 0x11F7;
static const int CL_COMMAND_COPY_IMAGE = 0x11F8;
static const int CL_COMMAND_COPY_IMAGE_TO_BUFFER = 0x11F9;
static const int CL_COMMAND_COPY_BUFFER_TO_IMAGE = 0x11FA;
static const int CL_COMMAND_MAP_BUFFER = 0x11FB;
static const int CL_COMMAND_MAP_IMAGE = 0x11FC;
static const int CL_COMMAND_UNMAP_MEM_OBJECT = 0x11FD;
static const int CL_COMMAND_MARKER = 0x11FE;
static const int CL_COMMAND_ACQUIRE_GL_OBJECTS = 0x11FF;
static const int CL_COMMAND_RELEASE_GL_OBJECTS = 0x1200;
static const int CL_COMMAND_READ_BUFFER_RECT = 0x1201;
static const int CL_COMMAND_WRITE_BUFFER_RECT = 0x1202;
static const int CL_COMMAND_COPY_BUFFER_RECT = 0x1203;
static const int CL_COMMAND_USER = 0x1204;
static const int CL_COMMAND_BARRIER = 0x1205;
static const int CL_COMMAND_MIGRATE_MEM_OBJECTS = 0x1206;
static const int CL_COMMAND_FILL_BUFFER = 0x1207;
static const int CL_COMMAND_FILL_IMAGE = 0x1208;
static const int CL_COMPLETE = 0x0;
static const int CL_RUNNING = 0x1;
static const int CL_SUBMITTED = 0x2;
static const int CL_QUEUED = 0x3;
static const int CL_BUFFER_CREATE_TYPE_REGION = 0x1220;
static const int CL_PROFILING_COMMAND_QUEUED = 0x1280;
static const int CL_PROFILING_COMMAND_SUBMIT = 0x1281;
static const int CL_PROFILING_COMMAND_START = 0x1282;
static const int CL_PROFILING_COMMAND_END = 0x1283;
cl_int clGetPlatformIDs(cl_uint, cl_platform_id *, cl_uint *);
cl_int clGetPlatformInfo(cl_platform_id, cl_platform_info, size_t, void *, size_t *);
cl_int clGetDeviceIDs(cl_platform_id, cl_device_type, cl_uint, cl_device_id *, cl_uint *);
cl_int clGetDeviceInfo(cl_device_id, cl_device_info, size_t, void *, size_t *);
cl_int clCreateSubDevices(cl_device_id, const cl_device_partition_property *, cl_uint, cl_device_id *, cl_uint *);
cl_int clRetainDevice(cl_device_id);
cl_int clReleaseDevice(cl_device_id);
cl_context clCreateContext(const cl_context_properties *, cl_uint, const cl_device_id *, void (*)(const char *, const void *, size_t, void *), void *, cl_int *);
cl_context clCreateContextFromType(const cl_context_properties *, cl_device_type, void (*)(const char *, const void *, size_t, void *), void *, cl_int *);
cl_int clRetainContext(cl_context);
cl_int clReleaseContext(cl_context);
cl_int clGetContextInfo(cl_context, cl_context_info, size_t, void *, size_t *);
cl_command_queue clCreateCommandQueue(cl_context, cl_device_id, cl_command_queue_properties, cl_int *);
cl_int clRetainCommandQueue(cl_command_queue);
cl_int clReleaseCommandQueue(cl_command_queue);
cl_int clGetCommandQueueInfo(cl_command_queue, cl_command_queue_info, size_t, void *, size_t *);
cl_mem clCreateBuffer(cl_context, cl_mem_flags, size_t, void *, cl_int *);
cl_mem clCreateSubBuffer(cl_mem, cl_mem_flags, cl_buffer_create_type, const void *, cl_int *);
cl_mem clCreateImage(cl_context, cl_mem_flags, const cl_image_format *, const cl_image_desc *, void *, cl_int *);
cl_int clRetainMemObject(cl_mem);
cl_int clReleaseMemObject(cl_mem);
cl_int clGetSupportedImageFormats(cl_context, cl_mem_flags, cl_mem_object_type, cl_uint, cl_image_format *, cl_uint *);
cl_int clGetMemObjectInfo(cl_mem, cl_mem_info, size_t, void *, size_t *);
cl_int clGetImageInfo(cl_mem, cl_image_info, size_t, void *, size_t *);
cl_int clSetMemObjectDestructorCallback(cl_mem, void (*)(cl_mem, void *), void *);
cl_sampler clCreateSampler(cl_context, cl_bool, cl_addressing_mode, cl_filter_mode, cl_int *);
cl_int clRetainSampler(cl_sampler);
cl_int clReleaseSampler(cl_sampler);
cl_int clGetSamplerInfo(cl_sampler, cl_sampler_info, size_t, void *, size_t *);
cl_program clCreateProgramWithSource(cl_context, cl_uint, const char **, const size_t *, cl_int *);
cl_program clCreateProgramWithBinary(cl_context, cl_uint, const cl_device_id *, const size_t *, const unsigned char **, cl_int *, cl_int *);
cl_program clCreateProgramWithBuiltInKernels(cl_context, cl_uint, const cl_device_id *, const char *, cl_int *);
cl_int clRetainProgram(cl_program);
cl_int clReleaseProgram(cl_program);
cl_int clBuildProgram(cl_program, cl_uint, const cl_device_id *, const char *, void (*)(cl_program, void *), void *);
cl_int clCompileProgram(cl_program, cl_uint, const cl_device_id *, const char *, cl_uint, const cl_program *, const char **, void (*)(cl_program, void *), void *);
cl_program clLinkProgram(cl_context, cl_uint, const cl_device_id *, const char *, cl_uint, const cl_program *, void (*)(cl_program, void *), void *, cl_int *);
cl_int clUnloadPlatformCompiler(cl_platform_id);
cl_int clGetProgramInfo(cl_program, cl_program_info, size_t, void *, size_t *);
cl_int clGetProgramBuildInfo(cl_program, cl_device_id, cl_program_build_info, size_t, void *, size_t *);
cl_kernel clCreateKernel(cl_program, const char *, cl_int *);
cl_int clCreateKernelsInProgram(cl_program, cl_uint, cl_kernel *, cl_uint *);
cl_int clRetainKernel(cl_kernel);
cl_int clReleaseKernel(cl_kernel);
cl_int clSetKernelArg(cl_kernel, cl_uint, size_t, const void *);
cl_int clGetKernelInfo(cl_kernel, cl_kernel_info, size_t, void *, size_t *);
cl_int clGetKernelArgInfo(cl_kernel, cl_uint, cl_kernel_arg_info, size_t, void *, size_t *);
cl_int clGetKernelWorkGroupInfo(cl_kernel, cl_device_id, cl_kernel_work_group_info, size_t, void *, size_t *);
cl_int clWaitForEvents(cl_uint, const cl_event *);
cl_int clGetEventInfo(cl_event, cl_event_info, size_t, void *, size_t *);
cl_event clCreateUserEvent(cl_context, cl_int *);
cl_int clRetainEvent(cl_event);
cl_int clReleaseEvent(cl_event);
cl_int clSetUserEventStatus(cl_event, cl_int);
cl_int clSetEventCallback(cl_event, cl_int, void (*)(cl_event, cl_int, void *), void *);
cl_int clGetEventProfilingInfo(cl_event, cl_profiling_info, size_t, void *, size_t *);
cl_int clFlush(cl_command_queue);
cl_int clFinish(cl_command_queue);
cl_int clEnqueueReadBuffer(cl_command_queue, cl_mem, cl_bool, size_t, size_t, void *, cl_uint, const cl_event *, cl_event *);
cl_int clEnqueueReadBufferRect(cl_command_queue, cl_mem, cl_bool, const size_t *, const size_t *, const size_t *, size_t, size_t, size_t, size_t, void *, cl_uint, const cl_event *, cl_event *);
cl_int clEnqueueWriteBuffer(cl_command_queue, cl_mem, cl_bool, size_t, size_t, const void *, cl_uint, const cl_event *, cl_event *);
cl_int clEnqueueWriteBufferRect(cl_command_queue, cl_mem, cl_bool, const size_t *, const size_t *, const size_t *, size_t, size_t, size_t, size_t, const void *, cl_uint, const cl_event *, cl_event *);
cl_int clEnqueueFillBuffer(cl_command_queue, cl_mem, const void *, size_t, size_t, size_t, cl_uint, const cl_event *, cl_event *);
cl_int clEnqueueCopyBuffer(cl_command_queue, cl_mem, cl_mem, size_t, size_t, size_t, cl_uint, const cl_event *, cl_event *);
cl_int clEnqueueCopyBufferRect(cl_command_queue, cl_mem, cl_mem, const size_t *, const size_t *, const size_t *, size_t, size_t, size_t, size_t, cl_uint, const cl_event *, cl_event *);
cl_int clEnqueueReadImage(cl_command_queue, cl_mem, cl_bool, const size_t *, const size_t *, size_t, size_t, void *, cl_uint, const cl_event *, cl_event *);
cl_int clEnqueueWriteImage(cl_command_queue, cl_mem, cl_bool, const size_t *, const size_t *, size_t, size_t, const void *, cl_uint, const cl_event *, cl_event *);
cl_int clEnqueueFillImage(cl_command_queue, cl_mem, const void *, const size_t *, const size_t *, cl_uint, const cl_event *, cl_event *);
cl_int clEnqueueCopyImage(cl_command_queue, cl_mem, cl_mem, const size_t *, const size_t *, const size_t *, cl_uint, const cl_event *, cl_event *);
cl_int clEnqueueCopyImageToBuffer(cl_command_queue, cl_mem, cl_mem, const size_t *, const size_t *, size_t, cl_uint, const cl_event *, cl_event *);
cl_int clEnqueueCopyBufferToImage(cl_command_queue, cl_mem, cl_mem, size_t, const size_t *, const size_t *, cl_uint, const cl_event *, cl_event *);
void *clEnqueueMapBuffer(cl_command_queue, cl_mem, cl_bool, cl_map_flags, size_t, size_t, cl_uint, const cl_event *, cl_event *, cl_int *);
void *clEnqueueMapImage(cl_command_queue, cl_mem, cl_bool, cl_map_flags, const size_t *, const size_t *, size_t *, size_t *, cl_uint, const cl_event *, cl_event *, cl_int *);
cl_int clEnqueueUnmapMemObject(cl_command_queue, cl_mem, void *, cl_uint, const cl_event *, cl_event *);
cl_int clEnqueueMigrateMemObjects(cl_command_queue, cl_uint, const cl_mem *, cl_mem_migration_flags, cl_uint, const cl_event *, cl_event *);
cl_int clEnqueueNDRangeKernel(cl_command_queue, cl_kernel, cl_uint, const size_t *, const size_t *, const size_t *, cl_uint, const cl_event *, cl_event *);
cl_int clEnqueueTask(cl_command_queue, cl_kernel, cl_uint, const cl_event *, cl_event *);
cl_int clEnqueueNativeKernel(cl_command_queue, void (*)(void *), void *, size_t, cl_uint, const cl_mem *, const void **, cl_uint, const cl_event *, cl_event *);
cl_int clEnqueueMarkerWithWaitList(cl_command_queue, cl_uint, const cl_event *, cl_event *);
cl_int clEnqueueBarrierWithWaitList(cl_command_queue, cl_uint, const cl_event *, cl_event *);
void *clGetExtensionFunctionAddressForPlatform(cl_platform_id, const char *);
cl_mem clCreateImage2D(cl_context, cl_mem_flags, const cl_image_format *, size_t, size_t, size_t, void *, cl_int *);
cl_mem clCreateImage3D(cl_context, cl_mem_flags, const cl_image_format *, size_t, size_t, size_t, size_t, size_t, void *, cl_int *);
cl_int clEnqueueMarker(cl_command_queue, cl_event *);
cl_int clEnqueueWaitForEvents(cl_command_queue, cl_uint, const cl_event *);
cl_int clEnqueueBarrier(cl_command_queue);
cl_int clUnloadCompiler(void);
void *clGetExtensionFunctionAddress(const char *);
]]

-- If the OpenCL library has been linked to the application, use OpenCL
-- symbols from default, global namespace. Otherwise, dynamically load
-- the OpenCL library into its own, non-global C library namespace.
local C = ffi.C
if not pcall(function() return ffi.C.clGetPlatformIDs end) then
  if jit.os=="Linux" then
    C = ffi.load("/usr/lib64/libOpenCL.so.1")
  elseif jit.os=="Windows" then
    C = ffi.load("OpenCL")
  end
end
return C
