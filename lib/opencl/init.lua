------------------------------------------------------------------------------
-- OpenCL for Lua.
-- Copyright © 2013–2015 Peter Colberg.
-- Distributed under the MIT license. (See accompanying file LICENSE.)
------------------------------------------------------------------------------

local C = require("lib.opencl.C")
local bit = require("bit")
local ffi = require("ffi")

local _M = {}

-- C types.
local char_n                            = ffi.typeof("char[?]")
local cl_bool                           = ffi.typeof("cl_bool")
local cl_bool_1                         = ffi.typeof("cl_bool[1]")
local cl_buffer_region                  = ffi.typeof("cl_buffer_region")
local cl_build_status                   = ffi.typeof("cl_build_status")
local cl_build_status_1                 = ffi.typeof("cl_build_status[1]")
local cl_command_queue                  = ffi.typeof("cl_command_queue")
local cl_command_queue_1                = ffi.typeof("cl_command_queue[1]")
local cl_command_queue_properties       = ffi.typeof("cl_command_queue_properties")
local cl_command_queue_properties_1     = ffi.typeof("cl_command_queue_properties[1]")
local cl_command_type                   = ffi.typeof("cl_command_type")
local cl_command_type_1                 = ffi.typeof("cl_command_type[1]")
local cl_context                        = ffi.typeof("cl_context")
local cl_context_1                      = ffi.typeof("cl_context[1]")
local cl_device_affinity_domain         = ffi.typeof("cl_device_affinity_domain")
local cl_device_affinity_domain_1       = ffi.typeof("cl_device_affinity_domain[1]")
local cl_device_exec_capabilities       = ffi.typeof("cl_device_exec_capabilities")
local cl_device_exec_capabilities_1     = ffi.typeof("cl_device_exec_capabilities[1]")
local cl_device_fp_config               = ffi.typeof("cl_device_fp_config")
local cl_device_fp_config_1             = ffi.typeof("cl_device_fp_config[1]")
local cl_device_id                      = ffi.typeof("cl_device_id")
local cl_device_id_1                    = ffi.typeof("cl_device_id[1]")
local cl_device_id_n                    = ffi.typeof("cl_device_id[?]")
local cl_device_local_mem_type          = ffi.typeof("cl_device_local_mem_type")
local cl_device_local_mem_type_1        = ffi.typeof("cl_device_local_mem_type[1]")
local cl_device_mem_cache_type          = ffi.typeof("cl_device_mem_cache_type")
local cl_device_mem_cache_type_1        = ffi.typeof("cl_device_mem_cache_type[1]")
local cl_device_partition_property      = ffi.typeof("cl_device_partition_property")
local cl_device_partition_property_3    = ffi.typeof("cl_device_partition_property[3]")
local cl_device_partition_property_n    = ffi.typeof("cl_device_partition_property[?]")
local cl_device_type                    = ffi.typeof("cl_device_type")
local cl_device_type_1                  = ffi.typeof("cl_device_type[1]")
local cl_event_1                        = ffi.typeof("cl_event[1]")
local cl_event_n                        = ffi.typeof("cl_event[?]")
local cl_int                            = ffi.typeof("cl_int")
local cl_int_1                          = ffi.typeof("cl_int[1]")
local cl_kernel_n                       = ffi.typeof("cl_kernel[?]")
local cl_kernel_arg_access_qualifier    = ffi.typeof("cl_kernel_arg_access_qualifier")
local cl_kernel_arg_access_qualifier_1  = ffi.typeof("cl_kernel_arg_access_qualifier[1]")
local cl_kernel_arg_address_qualifier   = ffi.typeof("cl_kernel_arg_address_qualifier")
local cl_kernel_arg_address_qualifier_1 = ffi.typeof("cl_kernel_arg_address_qualifier[1]")
local cl_kernel_arg_type_qualifier      = ffi.typeof("cl_kernel_arg_type_qualifier")
local cl_kernel_arg_type_qualifier_1    = ffi.typeof("cl_kernel_arg_type_qualifier[1]")
local cl_mem                            = ffi.typeof("cl_mem")
local cl_mem_1                          = ffi.typeof("cl_mem[1]")
local cl_mem_flags                      = ffi.typeof("cl_mem_flags")
local cl_mem_flags_1                    = ffi.typeof("cl_mem_flags[1]")
local cl_mem_object_type                = ffi.typeof("cl_mem_object_type")
local cl_mem_object_type_1              = ffi.typeof("cl_mem_object_type[1]")
local cl_platform_id                    = ffi.typeof("cl_platform_id")
local cl_platform_id_1                  = ffi.typeof("cl_platform_id[1]")
local cl_platform_id_n                  = ffi.typeof("cl_platform_id[?]")
local cl_program                        = ffi.typeof("cl_program")
local cl_program_1                      = ffi.typeof("cl_program[1]")
local cl_program_binary_type            = ffi.typeof("cl_program_binary_type")
local cl_program_binary_type_1          = ffi.typeof("cl_program_binary_type[1]")
local cl_sampler                        = ffi.typeof("cl_sampler")
local cl_sampler_1                      = ffi.typeof("cl_sampler[1]")
local cl_uint                           = ffi.typeof("cl_uint")
local cl_uint_1                         = ffi.typeof("cl_uint[1]")
local cl_ulong                          = ffi.typeof("cl_ulong")
local cl_ulong_1                        = ffi.typeof("cl_ulong[1]")
local const_char_ptr                    = ffi.typeof("const char *")
local const_char_ptr_1                  = ffi.typeof("const char *[1]")
local size_t                            = ffi.typeof("size_t")
local size_t_1                          = ffi.typeof("size_t[1]")
local size_t_3                          = ffi.typeof("size_t[3]")
local size_t_n                          = ffi.typeof("size_t[?]")
local unsigned_char_n                   = ffi.typeof("unsigned char[?]")
local unsigned_char_ptr                 = ffi.typeof("unsigned char *")
local unsigned_char_ptr_n               = ffi.typeof("unsigned char *[?]")
local void_ptr                          = ffi.typeof("void *")
local void_ptr_1                        = ffi.typeof("void *[1]")

-- Object methods.
local platform = {}
local device   = {}
local context  = {}
local mem      = {}
local queue    = {}
local program  = {}
local kernel   = {}
local event    = {}

-- Cache library functions.
local band, bor = bit.band, bit.bor

-- Converts a bit-field to a table of boolean values.
local function bittobool(b, map)
  local t = {}
  for k, v in pairs(map) do
    if band(b, k) ~= 0 then t[v] = true end
  end
  return t
end

-- Converts a sequence of strings to a bit-field.
local function strtobit(t, map)
  if type(t) == "string" then return map[t] end
  local b = 0
  for _, v in ipairs(t) do
    b = bor(b, map[v])
  end
  return b
end

-- OpenCL error messages.
local errors = {
  [C.CL_SUCCESS]                                   = "Success",
  [C.CL_DEVICE_NOT_FOUND]                          = "Device not found",
  [C.CL_DEVICE_NOT_AVAILABLE]                      = "Device not available",
  [C.CL_COMPILER_NOT_AVAILABLE]                    = "Compiler not available",
  [C.CL_MEM_OBJECT_ALLOCATION_FAILURE]             = "Memory object allocation failure",
  [C.CL_OUT_OF_RESOURCES]                          = "Out of resources",
  [C.CL_OUT_OF_HOST_MEMORY]                        = "Out of host memory",
  [C.CL_PROFILING_INFO_NOT_AVAILABLE]              = "Profiling information not available",
  [C.CL_MEM_COPY_OVERLAP]                          = "Memory copy overlap",
  [C.CL_IMAGE_FORMAT_MISMATCH]                     = "Image format mismatch",
  [C.CL_IMAGE_FORMAT_NOT_SUPPORTED]                = "Image format not supported",
  [C.CL_BUILD_PROGRAM_FAILURE]                     = "Build program failure",
  [C.CL_MAP_FAILURE]                               = "Map failure",
  [C.CL_MISALIGNED_SUB_BUFFER_OFFSET]              = "Misaligned sub-buffer offset",
  [C.CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST] = "Execution status error for events in wait list",
  [C.CL_COMPILE_PROGRAM_FAILURE]                   = "Compile program failure",
  [C.CL_LINKER_NOT_AVAILABLE]                      = "Linker not available",
  [C.CL_LINK_PROGRAM_FAILURE]                      = "Link program failure",
  [C.CL_DEVICE_PARTITION_FAILED]                   = "Device partition failed",
  [C.CL_KERNEL_ARG_INFO_NOT_AVAILABLE]             = "Kernel argument information not available",
  [C.CL_INVALID_VALUE]                             = "Invalid value",
  [C.CL_INVALID_DEVICE_TYPE]                       = "Invalid device type",
  [C.CL_INVALID_PLATFORM]                          = "Invalid platform",
  [C.CL_INVALID_DEVICE]                            = "Invalid device",
  [C.CL_INVALID_CONTEXT]                           = "Invalid context",
  [C.CL_INVALID_QUEUE_PROPERTIES]                  = "Invalid queue properties",
  [C.CL_INVALID_COMMAND_QUEUE]                     = "Invalid command-queue",
  [C.CL_INVALID_HOST_PTR]                          = "Invalid host pointer",
  [C.CL_INVALID_MEM_OBJECT]                        = "Invalid memory object",
  [C.CL_INVALID_IMAGE_FORMAT_DESCRIPTOR]           = "Invalid image format descriptor",
  [C.CL_INVALID_IMAGE_SIZE]                        = "Invalid image size",
  [C.CL_INVALID_SAMPLER]                           = "Invalid sampler",
  [C.CL_INVALID_BINARY]                            = "Invalid binary",
  [C.CL_INVALID_BUILD_OPTIONS]                     = "Invalid build options",
  [C.CL_INVALID_PROGRAM]                           = "Invalid program",
  [C.CL_INVALID_PROGRAM_EXECUTABLE]                = "Invalid program executable",
  [C.CL_INVALID_KERNEL_NAME]                       = "Invalid kernel name",
  [C.CL_INVALID_KERNEL_DEFINITION]                 = "Invalid kernel definition",
  [C.CL_INVALID_KERNEL]                            = "Invalid kernel",
  [C.CL_INVALID_ARG_INDEX]                         = "Invalid argument index",
  [C.CL_INVALID_ARG_VALUE]                         = "Invalid argument value",
  [C.CL_INVALID_ARG_SIZE]                          = "Invalid argument size",
  [C.CL_INVALID_KERNEL_ARGS]                       = "Invalid kernel arguments",
  [C.CL_INVALID_WORK_DIMENSION]                    = "Invalid work dimension",
  [C.CL_INVALID_WORK_GROUP_SIZE]                   = "Invalid work group size",
  [C.CL_INVALID_WORK_ITEM_SIZE]                    = "Invalid work item size",
  [C.CL_INVALID_GLOBAL_OFFSET]                     = "Invalid global offset",
  [C.CL_INVALID_EVENT_WAIT_LIST]                   = "Invalid event wait list",
  [C.CL_INVALID_EVENT]                             = "Invalid event",
  [C.CL_INVALID_OPERATION]                         = "Invalid operation",
  [C.CL_INVALID_GL_OBJECT]                         = "Invalid GL object",
  [C.CL_INVALID_BUFFER_SIZE]                       = "Invalid buffer size",
  [C.CL_INVALID_MIP_LEVEL]                         = "Invalid mipmap level",
  [C.CL_INVALID_GLOBAL_WORK_SIZE]                  = "Invalid global work size",
  [C.CL_INVALID_PROPERTY]                          = "Invalid property",
  [C.CL_INVALID_IMAGE_DESCRIPTOR]                  = "Invalid image descriptor",
  [C.CL_INVALID_COMPILER_OPTIONS]                  = "Invalid compiler options",
  [C.CL_INVALID_LINKER_OPTIONS]                    = "Invalid linker options",
  [C.CL_INVALID_DEVICE_PARTITION_COUNT]            = "Invalid device partition count",
}

setmetatable(errors, {__index = function() return "Unknown error code" end})

function _M.get_platforms()
  local num_platforms = cl_uint_1()
  local status = C.clGetPlatformIDs(0, nil, num_platforms)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  if num_platforms[0] == 0 then return end
  local platforms_buf = cl_platform_id_n(num_platforms[0])
  local status = C.clGetPlatformIDs(num_platforms[0], platforms_buf, nil)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  local platforms = {}
  for i = 0, num_platforms[0] - 1 do platforms[i + 1] = platforms_buf[i] end
  return platforms
end

do
  local function get_platform_info_string(name)
    return function(platform)
      local size = size_t_1()
      local status = C.clGetPlatformInfo(platform, name, 0, nil, size)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      if size[0] == 0 then return end
      local value = char_n(size[0])
      local status = C.clGetPlatformInfo(platform, name, ffi.sizeof(value), value, nil)
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      return ffi.string(value, size[0] - 1)
    end
  end

  local platform_info = {
    profile    = get_platform_info_string(C.CL_PLATFORM_PROFILE),
    version    = get_platform_info_string(C.CL_PLATFORM_VERSION),
    name       = get_platform_info_string(C.CL_PLATFORM_NAME),
    vendor     = get_platform_info_string(C.CL_PLATFORM_VENDOR),
    extensions = get_platform_info_string(C.CL_PLATFORM_EXTENSIONS),
  }

  function platform.get_info(platform, name)
    return platform_info[name](platform)
  end
end

do
  local device_types = {
    cpu         = C.CL_DEVICE_TYPE_CPU,
    gpu         = C.CL_DEVICE_TYPE_GPU,
    accelerator = C.CL_DEVICE_TYPE_ACCELERATOR,
    custom      = C.CL_DEVICE_TYPE_CUSTOM,
    default     = C.CL_DEVICE_TYPE_DEFAULT,
  }

  function platform.get_devices(platform, device_type)
    if device_type ~= nil then device_type = strtobit(device_type, device_types) else device_type = C.CL_DEVICE_TYPE_ALL end
    local num_devices = cl_uint_1()
    local status = C.clGetDeviceIDs(platform, device_type, 0, nil, num_devices)
    if status == C.CL_DEVICE_NOT_FOUND then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    if num_devices[0] == 0 then return end
    local devices_buf = cl_device_id_n(num_devices[0])
    local status = C.clGetDeviceIDs(platform, device_type, num_devices[0], devices_buf, nil)
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    local devices = {}
    for i = 0, num_devices[0] - 1 do devices[i + 1] = devices_buf[i] end
    return devices
  end
end

do
  local function get_device_info_size(name)
    return function(device)
      local value = size_t_1()
      local status = C.clGetDeviceInfo(device, name, ffi.sizeof(value), value, nil)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      if value[0] == 0 then return nil end
      return tonumber(value[0])
    end
  end

  local function get_device_info_uint(name)
    return function(device)
      local value = cl_uint_1()
      local status = C.clGetDeviceInfo(device, name, ffi.sizeof(value), value, nil)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      if value[0] == 0 then return nil end
      return tonumber(value[0])
    end
  end

  local function get_device_info_ulong(name)
    return function(device)
      local value = cl_ulong_1()
      local status = C.clGetDeviceInfo(device, name, ffi.sizeof(value), value, nil)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      if value[0] == 0 then return nil end
      return tonumber(value[0])
    end
  end

  local function get_device_info_bool(name)
    return function(device)
      local value = cl_bool_1()
      local status = C.clGetDeviceInfo(device, name, ffi.sizeof(value), value, nil)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      return value[0] == C.CL_TRUE
    end
  end

  local function get_device_info_string(name)
    return function(device)
      local size = size_t_1()
      local status = C.clGetDeviceInfo(device, name, 0, nil, size)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      if size[0] == 0 then return end
      local value = char_n(size[0])
      local status = C.clGetDeviceInfo(device, name, ffi.sizeof(value), value, nil)
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      return ffi.string(value, size[0] - 1)
    end
  end

  local device_fp_config = {
    [C.CL_FP_DENORM]           = "denorm",
    [C.CL_FP_INF_NAN]          = "inf_nan",
    [C.CL_FP_ROUND_TO_NEAREST] = "round_to_nearest",
    [C.CL_FP_ROUND_TO_ZERO]    = "round_to_zero",
    [C.CL_FP_ROUND_TO_INF]     = "round_to_inf",
    [C.CL_FP_FMA]              = "fma",
    [C.CL_FP_SOFT_FLOAT]       = "soft_float",
  }

  local function get_device_info_fp_config(name)
    return function(device)
      local value = cl_device_fp_config_1()
      local status = C.clGetDeviceInfo(device, name, ffi.sizeof(value), value, nil)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      if value[0] == 0 then return nil end
      return bittobool(tonumber(value[0]), device_fp_config)
    end
  end

  local device_exec_capabilities = {
    [C.CL_EXEC_KERNEL]        = "kernel",
    [C.CL_EXEC_NATIVE_KERNEL] = "native_kernel",
  }

  local function get_device_info_execution_capabilities(device)
    local value = cl_device_exec_capabilities_1()
    local status = C.clGetDeviceInfo(device, C.CL_DEVICE_EXECUTION_CAPABILITIES, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    if value[0] == 0 then return nil end
    return bittobool(tonumber(value[0]), device_exec_capabilities)
  end

  local device_mem_cache_type = {
    [C.CL_READ_ONLY_CACHE]  = "read_only",
    [C.CL_READ_WRITE_CACHE] = "read_write",
  }

  local function get_device_info_global_mem_cache_type(device)
    local value = cl_device_mem_cache_type_1()
    local status = C.clGetDeviceInfo(device, C.CL_DEVICE_GLOBAL_MEM_CACHE_TYPE, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    if value[0] == C.CL_NONE then return nil end
    return device_mem_cache_type[value[0]]
  end

  local device_local_mem_type = {
    [C.CL_LOCAL]  = "local",
    [C.CL_GLOBAL] = "global",
  }

  local function get_device_info_local_mem_type(device)
    local value = cl_device_local_mem_type_1()
    local status = C.clGetDeviceInfo(device, C.CL_DEVICE_LOCAL_MEM_TYPE, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    if value[0] == C.CL_NONE then return nil end
    return device_local_mem_type[value[0]]
  end

  local function get_device_info_sizes(name)
    return function(device)
      local size = size_t_1()
      local status = C.clGetDeviceInfo(device, name, 0, nil, size)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      local num_sizes = tonumber(size[0]) / ffi.sizeof(size_t)
      local value = size_t_n(num_sizes)
      local status = C.clGetDeviceInfo(device, name, ffi.sizeof(value), value, nil)
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      local sizes = {}
      for i = 0, num_sizes - 1 do sizes[i + 1] = tonumber(value[i]) end
      return sizes
    end
  end

  local function get_device_info_parent_device(device)
    local value = cl_device_id_1()
    local status = C.clGetDeviceInfo(device, C.CL_DEVICE_PARENT_DEVICE, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    if value[0] ~= nil then return cl_device_id(value[0]) end
  end

  local function get_device_info_platform(device)
    local value = cl_platform_id_1()
    local status = C.clGetDeviceInfo(device, C.CL_DEVICE_PLATFORM, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    if value[0] ~= nil then return cl_platform_id(value[0]) end
  end

  local device_type = {
    [C.CL_DEVICE_TYPE_CPU]         = "cpu",
    [C.CL_DEVICE_TYPE_GPU]         = "gpu",
    [C.CL_DEVICE_TYPE_ACCELERATOR] = "accelerator",
    [C.CL_DEVICE_TYPE_DEFAULT]     = "default",
    [C.CL_DEVICE_TYPE_CUSTOM]      = "custom",
  }

  local function get_device_info_type(device)
    local value = cl_device_type_1()
    local status = C.clGetDeviceInfo(device, C.CL_DEVICE_TYPE, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    if value[0] == 0 then return nil end
    return bittobool(tonumber(value[0]), device_type)
  end

  local command_queue_properties = {
    [C.CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE] = "out_of_order_exec_mode",
    [C.CL_QUEUE_PROFILING_ENABLE]              = "profiling",
  }

  local function get_device_info_queue_properties(device)
    local value = cl_command_queue_properties_1()
    local status = C.clGetDeviceInfo(device, C.CL_DEVICE_QUEUE_PROPERTIES, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    if value[0] == 0 then return nil end
    return bittobool(tonumber(value[0]), command_queue_properties)
  end

  local partition_property = {
    [C.CL_DEVICE_PARTITION_EQUALLY]            = "equally",
    [C.CL_DEVICE_PARTITION_BY_COUNTS]          = "by_counts",
    [C.CL_DEVICE_PARTITION_BY_AFFINITY_DOMAIN] = "by_affinity_domain",
  }

  local function get_device_info_partition_properties(device)
    local size = size_t_1()
    local status = C.clGetDeviceInfo(device, C.CL_DEVICE_PARTITION_PROPERTIES, 0, nil, size)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    local num_properties = tonumber(size[0]) / ffi.sizeof(cl_device_partition_property)
    local value = cl_device_partition_property_n(num_properties)
    local status = C.clGetDeviceInfo(device, C.CL_DEVICE_PARTITION_PROPERTIES, ffi.sizeof(value), value, nil)
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    local properties = {}
    for i = 0, num_properties - 1 do
      if value[i] == 0 then break end
      local partition_property = partition_property[tonumber(value[i])]
      if partition_property ~= nil then properties[partition_property] = true end
    end
    return properties
  end

  local partition_affinity_domain = {
    [C.CL_DEVICE_AFFINITY_DOMAIN_NUMA]               = "numa",
    [C.CL_DEVICE_AFFINITY_DOMAIN_L4_CACHE]           = "l4_cache",
    [C.CL_DEVICE_AFFINITY_DOMAIN_L3_CACHE]           = "l3_cache",
    [C.CL_DEVICE_AFFINITY_DOMAIN_L2_CACHE]           = "l2_cache",
    [C.CL_DEVICE_AFFINITY_DOMAIN_L1_CACHE]           = "l1_cache",
    [C.CL_DEVICE_AFFINITY_DOMAIN_NEXT_PARTITIONABLE] = "next_partitionable",
  }

  local function get_device_info_partition_affinity_domain(device)
    local value = cl_device_affinity_domain_1()
    local status = C.clGetDeviceInfo(device, C.CL_DEVICE_PARTITION_AFFINITY_DOMAIN, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    if value[0] == 0 then return end
    return bittobool(tonumber(value[0]), partition_affinity_domain)
  end

  local partition_property_value = {
    [C.CL_DEVICE_PARTITION_EQUALLY] = function(value)
      return "equally", tonumber(value[1])
    end,

    [C.CL_DEVICE_PARTITION_BY_COUNTS] = function(value)
      local counts = {}
      while value[1] ~= C.CL_DEVICE_PARTITION_BY_COUNTS_LIST_END do
        counts[#counts + 1] = tonumber(value[1])
        value = value + 1
      end
      return "by_counts", counts
    end,

    [C.CL_DEVICE_PARTITION_BY_AFFINITY_DOMAIN] = function(value)
      return "by_affinity_domain", partition_affinity_domain[tonumber(value[1])]
    end,
  }

  local function get_device_info_partition_type(device)
    local size = size_t_1()
    local status = C.clGetDeviceInfo(device, C.CL_DEVICE_PARTITION_TYPE, 0, nil, size)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    local num_properties = tonumber(size[0]) / ffi.sizeof(cl_device_partition_property)
    local value = cl_device_partition_property_n(num_properties + 1)
    local status = C.clGetDeviceInfo(device, C.CL_DEVICE_PARTITION_TYPE, ffi.sizeof(value), value, nil)
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    if value[0] == 0 then return end
    return partition_property_value[tonumber(value[0])](value)
  end

  local device_info = {
    address_bits                  = get_device_info_uint(C.CL_DEVICE_ADDRESS_BITS),
    available                     = get_device_info_bool(C.CL_DEVICE_AVAILABLE),
    built_in_kernels              = get_device_info_string(C.CL_DEVICE_BUILT_IN_KERNELS),
    compiler_available            = get_device_info_bool(C.CL_DEVICE_COMPILER_AVAILABLE),
    double_fp_config              = get_device_info_fp_config(C.CL_DEVICE_DOUBLE_FP_CONFIG),
    endian_little                 = get_device_info_bool(C.CL_DEVICE_ENDIAN_LITTLE),
    error_correction_support      = get_device_info_bool(C.CL_DEVICE_ERROR_CORRECTION_SUPPORT),
    execution_capabilities        = get_device_info_execution_capabilities,
    extensions                    = get_device_info_string(C.CL_DEVICE_EXTENSIONS),
    global_mem_cache_size         = get_device_info_ulong(C.CL_DEVICE_GLOBAL_MEM_CACHE_SIZE),
    global_mem_cache_type         = get_device_info_global_mem_cache_type,
    global_mem_cacheline_size     = get_device_info_uint(C.CL_DEVICE_GLOBAL_MEM_CACHELINE_SIZE),
    global_mem_size               = get_device_info_ulong(C.CL_DEVICE_GLOBAL_MEM_SIZE),
    half_fp_config                = get_device_info_fp_config(C.CL_DEVICE_HALF_FP_CONFIG),
    host_unified_memory           = get_device_info_bool(C.CL_DEVICE_HOST_UNIFIED_MEMORY),
    image_support                 = get_device_info_bool(C.CL_DEVICE_IMAGE_SUPPORT),
    image2d_max_height            = get_device_info_size(C.CL_DEVICE_IMAGE2D_MAX_HEIGHT),
    image2d_max_width             = get_device_info_size(C.CL_DEVICE_IMAGE2D_MAX_WIDTH),
    image3d_max_depth             = get_device_info_size(C.CL_DEVICE_IMAGE3D_MAX_DEPTH),
    image3d_max_height            = get_device_info_size(C.CL_DEVICE_IMAGE3D_MAX_HEIGHT),
    image3d_max_width             = get_device_info_size(C.CL_DEVICE_IMAGE3D_MAX_WIDTH),
    image_max_buffer_size         = get_device_info_size(C.CL_DEVICE_IMAGE_MAX_BUFFER_SIZE),
    image_max_array_size          = get_device_info_size(C.CL_DEVICE_IMAGE_MAX_ARRAY_SIZE),
    linker_available              = get_device_info_bool(C.CL_DEVICE_LINKER_AVAILABLE),
    local_mem_size                = get_device_info_ulong(C.CL_DEVICE_LOCAL_MEM_SIZE),
    local_mem_type                = get_device_info_local_mem_type,
    max_clock_frequency           = get_device_info_uint(C.CL_DEVICE_MAX_CLOCK_FREQUENCY),
    max_compute_units             = get_device_info_uint(C.CL_DEVICE_MAX_COMPUTE_UNITS),
    max_constant_args             = get_device_info_uint(C.CL_DEVICE_MAX_CONSTANT_ARGS),
    max_constant_buffer_size      = get_device_info_ulong(C.CL_DEVICE_MAX_CONSTANT_BUFFER_SIZE),
    max_mem_alloc_size            = get_device_info_ulong(C.CL_DEVICE_MAX_MEM_ALLOC_SIZE),
    max_parameter_size            = get_device_info_size(C.CL_DEVICE_MAX_PARAMETER_SIZE),
    max_read_image_args           = get_device_info_uint(C.CL_DEVICE_MAX_READ_IMAGE_ARGS),
    max_samplers                  = get_device_info_uint(C.CL_DEVICE_MAX_SAMPLERS),
    max_work_group_size           = get_device_info_size(C.CL_DEVICE_MAX_WORK_GROUP_SIZE),
    max_work_item_dimensions      = get_device_info_uint(C.CL_DEVICE_MAX_WORK_ITEM_DIMENSIONS),
    max_work_item_sizes           = get_device_info_sizes(C.CL_DEVICE_MAX_WORK_ITEM_SIZES),
    max_write_image_args          = get_device_info_uint(C.CL_DEVICE_MAX_WRITE_IMAGE_ARGS),
    mem_base_addr_align           = get_device_info_uint(C.CL_DEVICE_MEM_BASE_ADDR_ALIGN),
    min_data_type_align_size      = get_device_info_uint(C.CL_DEVICE_MIN_DATA_TYPE_ALIGN_SIZE),
    name                          = get_device_info_string(C.CL_DEVICE_NAME),
    native_vector_width_char      = get_device_info_uint(C.CL_DEVICE_NATIVE_VECTOR_WIDTH_CHAR),
    native_vector_width_short     = get_device_info_uint(C.CL_DEVICE_NATIVE_VECTOR_WIDTH_SHORT),
    native_vector_width_int       = get_device_info_uint(C.CL_DEVICE_NATIVE_VECTOR_WIDTH_INT),
    native_vector_width_long      = get_device_info_uint(C.CL_DEVICE_NATIVE_VECTOR_WIDTH_LONG),
    native_vector_width_float     = get_device_info_uint(C.CL_DEVICE_NATIVE_VECTOR_WIDTH_FLOAT),
    native_vector_width_double    = get_device_info_uint(C.CL_DEVICE_NATIVE_VECTOR_WIDTH_DOUBLE),
    native_vector_width_half      = get_device_info_uint(C.CL_DEVICE_NATIVE_VECTOR_WIDTH_HALF),
    opencl_c_version              = get_device_info_string(C.CL_DEVICE_OPENCL_C_VERSION),
    parent_device                 = get_device_info_parent_device,
    partition_max_sub_devices     = get_device_info_uint(C.CL_DEVICE_PARTITION_MAX_SUB_DEVICES),
    partition_properties          = get_device_info_partition_properties,
    partition_affinity_domain     = get_device_info_partition_affinity_domain,
    partition_type                = get_device_info_partition_type,
    platform                      = get_device_info_platform,
    preferred_vector_width_char   = get_device_info_uint(C.CL_DEVICE_PREFERRED_VECTOR_WIDTH_CHAR),
    preferred_vector_width_short  = get_device_info_uint(C.CL_DEVICE_PREFERRED_VECTOR_WIDTH_SHORT),
    preferred_vector_width_int    = get_device_info_uint(C.CL_DEVICE_PREFERRED_VECTOR_WIDTH_INT),
    preferred_vector_width_long   = get_device_info_uint(C.CL_DEVICE_PREFERRED_VECTOR_WIDTH_LONG),
    preferred_vector_width_float  = get_device_info_uint(C.CL_DEVICE_PREFERRED_VECTOR_WIDTH_FLOAT),
    preferred_vector_width_double = get_device_info_uint(C.CL_DEVICE_PREFERRED_VECTOR_WIDTH_DOUBLE),
    preferred_vector_width_half   = get_device_info_uint(C.CL_DEVICE_PREFERRED_VECTOR_WIDTH_HALF),
    printf_buffer_size            = get_device_info_size(C.CL_DEVICE_PRINTF_BUFFER_SIZE),
    preferred_interop_user_sync   = get_device_info_bool(C.CL_DEVICE_PREFERRED_INTEROP_USER_SYNC),
    profile                       = get_device_info_string(C.CL_DEVICE_PROFILE),
    profiling_timer_resolution    = get_device_info_size(C.CL_DEVICE_PROFILING_TIMER_RESOLUTION),
    queue_properties              = get_device_info_queue_properties,
    single_fp_config              = get_device_info_fp_config(C.CL_DEVICE_SINGLE_FP_CONFIG),
    type                          = get_device_info_type,
    vendor                        = get_device_info_string(C.CL_DEVICE_VENDOR),
    vendor_id                     = get_device_info_uint(C.CL_DEVICE_VENDOR_ID),
    version                       = get_device_info_string(C.CL_DEVICE_VERSION),
    driver_version                = get_device_info_string(C.CL_DRIVER_VERSION),
  }

  function device.get_info(device, name)
    return device_info[name](device)
  end
end

local function release_device(device)
  local status = C.clReleaseDevice(device)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
end

local function retain_device(device)
  local value = cl_device_id_1()
  local status = C.clGetDeviceInfo(device, C.CL_DEVICE_PARENT_DEVICE, ffi.sizeof(value), value, nil)
  if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return device end
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  if value[0] == nil then return device end
  local status = C.clRetainDevice(device)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  return ffi.gc(device, release_device)
end

do
  local partition_affinity_domain = {
    numa               = C.CL_DEVICE_AFFINITY_DOMAIN_NUMA,
    l4_cache           = C.CL_DEVICE_AFFINITY_DOMAIN_L4_CACHE,
    l3_cache           = C.CL_DEVICE_AFFINITY_DOMAIN_L3_CACHE,
    l2_cache           = C.CL_DEVICE_AFFINITY_DOMAIN_L2_CACHE,
    l1_cache           = C.CL_DEVICE_AFFINITY_DOMAIN_L1_CACHE,
    next_partitionable = C.CL_DEVICE_AFFINITY_DOMAIN_NEXT_PARTITIONABLE,
  }

  local partition_property_value = {
    equally = function(value)
      return cl_device_partition_property_3(C.CL_DEVICE_PARTITION_EQUALLY, value)
    end,

    by_counts = function(value)
      local num_properties = #value
      local properties = cl_device_partition_property_n(num_properties + 3)
      properties[0] = C.CL_DEVICE_PARTITION_BY_COUNTS
      for i = 1, num_properties do properties[i] = value[i] end
      properties[num_properties + 1] = C.CL_DEVICE_PARTITION_BY_COUNTS_LIST_END
      return properties
    end,

    by_affinity_domain = function(value)
      value = partition_affinity_domain[value]
      return cl_device_partition_property_3(C.CL_DEVICE_PARTITION_BY_AFFINITY_DOMAIN, value)
    end,
  }

  function device.create_sub_devices(in_device, name, value)
    local properties = partition_property_value[name](value)
    local num_devices = cl_uint_1()
    local status = C.clCreateSubDevices(in_device, properties, 0, nil, num_devices)
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    local out_devices_ptr = cl_device_id_n(num_devices[0])
    local status = C.clCreateSubDevices(in_device, properties, num_devices[0], out_devices_ptr, nil)
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    local out_devices = {}
    for i = 1, num_devices[0] do out_devices[i] = ffi.gc(out_devices_ptr[i - 1], release_device) end
    return out_devices
  end
end

local function release_context(context)
  local status = C.clReleaseContext(context)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
end

local function retain_context(context)
  local status = C.clRetainContext(context)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  return ffi.gc(context, release_context)
end

function _M.create_context(devices)
  local num_devices = #devices
  local devices = cl_device_id_n(num_devices, devices)
  local status = cl_int_1()
  local context = C.clCreateContext(nil, num_devices, devices, nil, nil, status)
  if status[0] ~= C.CL_SUCCESS then return error(errors[status[0]]) end
  return ffi.gc(context, release_context)
end

do
  local function get_context_object_info_uint(name)
    return function(context)
      local value = cl_uint_1()
      local status = C.clGetContextInfo(context, name, ffi.sizeof(value), value, nil)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      return value[0]
    end
  end

  local function get_context_info_devices(context)
    local size = size_t_1()
    local status = C.clGetContextInfo(context, C.CL_CONTEXT_DEVICES, 0, nil, size)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    local num_devices = tonumber(size[0]) / ffi.sizeof(cl_device_id)
    local value = cl_device_id_n(num_devices)
    local status = C.clGetContextInfo(context, C.CL_CONTEXT_DEVICES, ffi.sizeof(value), value, nil)
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    local devices = {}
    for i = 1, num_devices do devices[i] = retain_device(value[i - 1]) end
    return devices
  end

  local context_info = {
    num_devices     = get_context_object_info_uint(C.CL_CONTEXT_NUM_DEVICES),
    devices         = get_context_info_devices,
  }

  function context.get_info(context, name)
    return context_info[name](context)
  end
end

local function release_mem_object(mem)
  local status = C.clReleaseMemObject(mem)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
end

function context.release_mem_object(mem)
  return release_mem_object(ffi.gc(mem, nil))
end

local function retain_mem_object(mem)
  local status = C.clRetainMemObject(mem)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  return ffi.gc(mem, release_mem_object)
end

do
  local create_buffer_flags = {
    read_write      = C.CL_MEM_READ_WRITE,
    write_only      = C.CL_MEM_WRITE_ONLY,
    read_only       = C.CL_MEM_READ_ONLY,
    use_host_ptr    = C.CL_MEM_USE_HOST_PTR,
    alloc_host_ptr  = C.CL_MEM_ALLOC_HOST_PTR,
    copy_host_ptr   = C.CL_MEM_COPY_HOST_PTR,
    host_write_only = C.CL_MEM_HOST_WRITE_ONLY,
    host_read_only  = C.CL_MEM_HOST_READ_ONLY,
    host_no_access  = C.CL_MEM_HOST_NO_ACCESS,
  }

  function context.create_buffer(context, flags, size, host_ptr)
    if tonumber(flags) ~= nil then flags, size, host_ptr = nil, flags, size end
    if flags ~= nil then flags = strtobit(flags, create_buffer_flags) else flags = 0 end
    local status = cl_int_1()
    local mem = C.clCreateBuffer(context, flags, size, host_ptr, status)
    if status[0] ~= C.CL_SUCCESS then return error(errors[status[0]]) end
    return ffi.gc(mem, release_mem_object)
  end

  local create_sub_buffer_flags = {
    region = C.CL_BUFFER_CREATE_TYPE_REGION,
  }

  function mem.create_sub_buffer(buffer, flags, create_type, create_info)
    if create_info == nil then flags, create_type, create_info = nil, flags, create_type end
    if flags ~= nil then flags = strtobit(flags, create_buffer_flags) else flags = 0 end
    create_type = create_sub_buffer_flags[create_type]
    create_info = cl_buffer_region(create_info)
    local status = cl_int_1()
    local mem = C.clCreateSubBuffer(buffer, flags, create_type, create_info, status)
    if status[0] ~= C.CL_SUCCESS then return error(errors[status[0]]) end
    return ffi.gc(mem, release_mem_object)
  end
end

do
  local mem_type = {
    [C.CL_MEM_OBJECT_BUFFER]         = "buffer",
    [C.CL_MEM_OBJECT_IMAGE1D]        = "image1d",
    [C.CL_MEM_OBJECT_IMAGE1D_BUFFER] = "image1d_buffer",
    [C.CL_MEM_OBJECT_IMAGE1D_ARRAY]  = "image1d_array",
    [C.CL_MEM_OBJECT_IMAGE2D]        = "image2d",
    [C.CL_MEM_OBJECT_IMAGE2D_ARRAY]  = "image2d_array",
    [C.CL_MEM_OBJECT_IMAGE3D]        = "image3d",
  }

  local function get_mem_object_info_type(mem)
    local value = cl_mem_object_type_1()
    local status = C.clGetMemObjectInfo(mem, C.CL_MEM_TYPE, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return mem_type[value[0]]
  end

  local mem_flags = {
    [C.CL_MEM_READ_WRITE]      = "read_write",
    [C.CL_MEM_WRITE_ONLY]      = "write_only",
    [C.CL_MEM_READ_ONLY]       = "read_only",
    [C.CL_MEM_USE_HOST_PTR]    = "use_host_ptr",
    [C.CL_MEM_ALLOC_HOST_PTR]  = "alloc_host_ptr",
    [C.CL_MEM_COPY_HOST_PTR]   = "copy_host_ptr",
    [C.CL_MEM_HOST_WRITE_ONLY] = "host_write_only",
    [C.CL_MEM_HOST_READ_ONLY]  = "host_read_only",
    [C.CL_MEM_HOST_NO_ACCESS]  = "host_no_access",
  }

  local function get_mem_object_info_flags(mem)
    local value = cl_mem_flags_1()
    local status = C.clGetMemObjectInfo(mem, C.CL_MEM_FLAGS, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return bittobool(tonumber(value[0]), mem_flags)
  end

  local function get_mem_object_info_size(mem)
    local value = size_t_1()
    local status = C.clGetMemObjectInfo(mem, C.CL_MEM_SIZE, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return tonumber(value[0])
  end

  local function get_mem_object_info_host_ptr(mem)
    local value = void_ptr_1()
    local status = C.clGetMemObjectInfo(mem, C.CL_MEM_HOST_PTR, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    if value[0] == nil then return end
    return value[0]
  end

  local function get_mem_object_info_uint(name)
    return function(mem)
      local value = cl_uint_1()
      local status = C.clGetMemObjectInfo(mem, name, ffi.sizeof(value), value, nil)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      return value[0]
    end
  end

  local function get_mem_object_info_context(mem)
    local value = cl_context_1()
    local status = C.clGetMemObjectInfo(mem, C.CL_MEM_CONTEXT, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return retain_context(value[0])
  end

  local function get_mem_object_info_associated_memobject(mem)
    local value = cl_mem_1()
    local status = C.clGetMemObjectInfo(mem, C.CL_MEM_ASSOCIATED_MEMOBJECT, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    if value[0] == nil then return end
    return retain_mem_object(value[0])
  end

  local function get_mem_object_info_offset(mem)
    local value = cl_mem_1()
    local status = C.clGetMemObjectInfo(mem, C.CL_MEM_ASSOCIATED_MEMOBJECT, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    if value[0] == nil then return end
    local value = size_t_1()
    local status = C.clGetMemObjectInfo(mem, C.CL_MEM_OFFSET, ffi.sizeof(value), value, nil)
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return tonumber(value[0])
  end

  local mem_info = {
    type                 = get_mem_object_info_type,
    flags                = get_mem_object_info_flags,
    size                 = get_mem_object_info_size,
    host_ptr             = get_mem_object_info_host_ptr,
    map_count            = get_mem_object_info_uint(C.CL_MEM_MAP_COUNT),
    context              = get_mem_object_info_context,
    associated_memobject = get_mem_object_info_associated_memobject,
    offset               = get_mem_object_info_offset,
  }

  function mem.get_info(mem, name)
    return mem_info[name](mem)
  end
end

local function release_program(program)
  local status = C.clReleaseProgram(program)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
end

local function retain_program(program)
  local status = C.clRetainProgram(program)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  return ffi.gc(program, release_program)
end

function context.create_program_with_source(context, source)
  local sizes = ffi.new(size_t_1, #source)
  local strings = const_char_ptr_1(ffi.cast(const_char_ptr, source))
  local status = cl_int_1()
  local program = C.clCreateProgramWithSource(context, 1, strings, sizes, status)
  if status[0] ~= C.CL_SUCCESS then return error(errors[status[0]]) end
  return ffi.gc(program, release_program)
end

function program.build(program, devices, options)
  if type(devices) == "string" then devices, options = nil, devices end
  local num_devices = devices ~= nil and #devices or 0
  if devices ~= nil then devices = cl_device_id_n(num_devices, devices) end
  local status = C.clBuildProgram(program, num_devices, devices, options, nil, nil)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
end

do
  local function get_program_info_uint(name)
    return function(program)
      local value = cl_uint_1()
      local status = C.clGetProgramInfo(program, name, ffi.sizeof(value), value, nil)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      return value[0]
    end
  end

  local function get_program_info_context(program)
    local value = cl_context_1()
    local status = C.clGetProgramInfo(program, C.CL_PROGRAM_CONTEXT, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return retain_context(value[0])
  end

  local function get_program_info_devices(program)
    local size = size_t_1()
    local status = C.clGetProgramInfo(program, C.CL_PROGRAM_DEVICES, 0, nil, size)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    local num_devices = tonumber(size[0]) / ffi.sizeof(cl_device_id)
    local value = cl_device_id_n(num_devices)
    local status = C.clGetProgramInfo(program, C.CL_PROGRAM_DEVICES, ffi.sizeof(value), value, nil)
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    local devices = {}
    for i = 1, num_devices do devices[i] = retain_device(value[i - 1]) end
    return devices
  end

  local function get_program_info_string(name)
    return function(program)
      local size = size_t_1()
      local status = C.clGetProgramInfo(program, name, 0, nil, size)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      if size[0] == 0 then return end
      local value = char_n(size[0])
      local status = C.clGetProgramInfo(program, name, ffi.sizeof(value), value, nil)
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      return ffi.string(value, size[0] - 1)
    end
  end

  local function get_program_info_binary_sizes(program)
    local size = size_t_1()
    local status = C.clGetProgramInfo(program, C.CL_PROGRAM_BINARY_SIZES, 0, nil, size)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    local num_binaries = tonumber(size[0]) / ffi.sizeof(size_t)
    local value = size_t_n(num_binaries)
    local status = C.clGetProgramInfo(program, C.CL_PROGRAM_BINARY_SIZES, ffi.sizeof(value), value, nil)
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    local sizes = {}
    for i = 0, num_binaries - 1 do sizes[i + 1] = tonumber(value[i]) end
    return sizes
  end

  local function get_program_info_binaries(program)
    local size = size_t_1()
    local status = C.clGetProgramInfo(program, C.CL_PROGRAM_BINARY_SIZES, 0, nil, size)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    local num_binaries = tonumber(size[0]) / ffi.sizeof(size_t)
    local binary_sizes = size_t_n(num_binaries)
    local status = C.clGetProgramInfo(program, C.CL_PROGRAM_BINARY_SIZES, ffi.sizeof(binary_sizes), binary_sizes, nil)
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    local size = 0
    for i = 0, num_binaries - 1 do size = size + binary_sizes[i] end
    local binary = unsigned_char_n(size)
    local binaries_buf = unsigned_char_ptr_n(num_binaries)
    local offset = binary
    for i = 0, num_binaries - 1 do binaries_buf[i], offset = offset, offset + binary_sizes[i] end
    local status = C.clGetProgramInfo(program, C.CL_PROGRAM_BINARIES, ffi.sizeof(binaries_buf), binaries_buf, nil)
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    local binaries = {}
    for i = 0, num_binaries - 1 do
      if binary_sizes[i] > 0 then binaries[i + 1] = ffi.string(binaries_buf[i], binary_sizes[i]) end
    end
    return binaries
  end

  local function get_program_info_num_kernels(program)
    local value = size_t_1()
    local status = C.clGetProgramInfo(program, C.CL_PROGRAM_NUM_KERNELS, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return tonumber(value[0])
  end

  local program_info = {
    context         = get_program_info_context,
    num_devices     = get_program_info_uint(C.CL_PROGRAM_NUM_DEVICES),
    devices         = get_program_info_devices,
    source          = get_program_info_string(C.CL_PROGRAM_SOURCE),
    binary_sizes    = get_program_info_binary_sizes,
    binaries        = get_program_info_binaries,
    num_kernels     = get_program_info_num_kernels,
    kernel_names    = get_program_info_string(C.CL_PROGRAM_KERNEL_NAMES),
  }

  function program.get_info(program, name)
    return program_info[name](program)
  end
end

do
  local function get_program_build_info_string(name)
    return function(program, device)
      local size = size_t_1()
      local status = C.clGetProgramBuildInfo(program, device, name, 0, nil, size)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      if size[0] == 0 then return end
      local value = char_n(size[0])
      local status = C.clGetProgramBuildInfo(program, device, name, ffi.sizeof(value), value, nil)
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      return ffi.string(value, size[0] - 1)
    end
  end

  local build_status = {
    [C.CL_BUILD_ERROR]       = "error",
    [C.CL_BUILD_SUCCESS]     = "success",
    [C.CL_BUILD_IN_PROGRESS] = "in_progress",
  }

  local function get_program_build_info_status(program, device)
    local value = cl_build_status_1()
    local status = C.clGetProgramBuildInfo(program, device, C.CL_PROGRAM_BUILD_STATUS, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    if value[0] == C.CL_BUILD_NONE then return nil end
    return build_status[value[0]]
  end

  local binary_type = {
    [C.CL_PROGRAM_BINARY_TYPE_COMPILED_OBJECT] = "compiled_object",
    [C.CL_PROGRAM_BINARY_TYPE_LIBRARY]         = "library",
    [C.CL_PROGRAM_BINARY_TYPE_EXECUTABLE]      = "executable",
  }

  local function get_program_build_info_binary_type(program, device)
    local value = cl_program_binary_type_1()
    local status = C.clGetProgramBuildInfo(program, device, C.CL_PROGRAM_BINARY_TYPE, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    if value[0] == C.CL_PROGRAM_BINARY_TYPE_NONE then return nil end
    return binary_type[value[0]]
  end

  local program_build_info = {
    status       = get_program_build_info_status,
    log          = get_program_build_info_string(C.CL_PROGRAM_BUILD_LOG),
    options      = get_program_build_info_string(C.CL_PROGRAM_BUILD_OPTIONS),
    binary_type  = get_program_build_info_binary_type,
  }

  function program.get_build_info(program, device, name)
    return program_build_info[name](program, device)
  end
end

local function release_kernel(kernel)
  local status = C.clReleaseKernel(kernel)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
end

function program.create_kernel(program, name)
  local status = cl_int_1()
  local kernel = C.clCreateKernel(program, name, status)
  if status[0] ~= C.CL_SUCCESS then return error(errors[status[0]]) end
  return ffi.gc(kernel, release_kernel)
end

function program.create_kernels_in_program(program)
  local num_kernels = cl_int_1()
  local status = C.clCreateKernelsInProgram(program, 0, nil, num_kernels)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  local kernels_buf = cl_kernel_n(num_kernels[0])
  local status = C.clCreateKernelsInProgram(program, num_kernels[0], kernels_buf, nil)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  local kernels = {}
  for i = 1, num_kernels[0] do kernels[i] = ffi.gc(kernels_buf[i - 1], release_kernel) end
  return kernels
end

function kernel.set_arg(kernel, index, size, value)
  if ffi.istype(cl_mem, size) then size, value = ffi.sizeof(cl_mem), cl_mem_1(size) end
  if ffi.istype(cl_sampler, size) then size, value = ffi.sizeof(cl_sampler), cl_sampler_1(size) end
  if type(size) == "cdata" then size, value = ffi.sizeof(size), size end
  if size == nil then size = ffi.sizeof(cl_mem) end
  local status = C.clSetKernelArg(kernel, index, size, value)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
end

do
  local function get_kernel_arg_info_string(name)
    return function(kernel, index)
      local size = size_t_1()
      local status = C.clGetKernelArgInfo(kernel, index, name, 0, nil, size)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION or status == C.CL_KERNEL_ARG_INFO_NOT_AVAILABLE then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      if size[0] == 0 then return end
      local value = char_n(size[0])
      local status = C.clGetKernelArgInfo(kernel, index, name, ffi.sizeof(value), value, nil)
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      return ffi.string(value, size[0] - 1)
    end
  end

  local address_qualifier = {
    [C.CL_KERNEL_ARG_ADDRESS_GLOBAL]   = "global",
    [C.CL_KERNEL_ARG_ADDRESS_LOCAL]    = "local",
    [C.CL_KERNEL_ARG_ADDRESS_CONSTANT] = "constant",
    [C.CL_KERNEL_ARG_ADDRESS_PRIVATE]  = "private",
  }

  local function get_kernel_arg_info_address_qualifier(kernel, index)
    local value = cl_kernel_arg_address_qualifier_1()
    local status = C.clGetKernelArgInfo(kernel, index, C.CL_KERNEL_ARG_ADDRESS_QUALIFIER, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION or status == C.CL_KERNEL_ARG_INFO_NOT_AVAILABLE then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return address_qualifier[value[0]]
  end

  local access_qualifier = {
    [C.CL_KERNEL_ARG_ACCESS_READ_ONLY]  = "read_only",
    [C.CL_KERNEL_ARG_ACCESS_WRITE_ONLY] = "write_only",
    [C.CL_KERNEL_ARG_ACCESS_READ_WRITE] = "read_write",
  }

  local function get_kernel_arg_info_access_qualifier(kernel, index)
    local value = cl_kernel_arg_access_qualifier_1()
    local status = C.clGetKernelArgInfo(kernel, index, C.CL_KERNEL_ARG_ACCESS_QUALIFIER, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION or status == C.CL_KERNEL_ARG_INFO_NOT_AVAILABLE then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return access_qualifier[value[0]]
  end

  local type_qualifier = {
    [C.CL_KERNEL_ARG_TYPE_CONST]    = "const",
    [C.CL_KERNEL_ARG_TYPE_RESTRICT] = "restrict",
    [C.CL_KERNEL_ARG_TYPE_VOLATILE] = "volatile",
  }

  local function get_kernel_arg_info_arg_type_qualifier(kernel, index)
    local value = cl_kernel_arg_type_qualifier_1()
    local status = C.clGetKernelArgInfo(kernel, index, C.CL_KERNEL_ARG_TYPE_QUALIFIER, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION or status == C.CL_KERNEL_ARG_INFO_NOT_AVAILABLE then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return bittobool(tonumber(value[0]), type_qualifier)
  end

  local kernel_arg_info = {
    address_qualifier = get_kernel_arg_info_address_qualifier,
    access_qualifier  = get_kernel_arg_info_access_qualifier,
    type_name         = get_kernel_arg_info_string(C.CL_KERNEL_ARG_TYPE_NAME),
    type_qualifier    = get_kernel_arg_info_arg_type_qualifier,
    name              = get_kernel_arg_info_string(C.CL_KERNEL_ARG_NAME),
  }

  function kernel.get_arg_info(kernel, index, name)
    return kernel_arg_info[name](kernel, index)
  end
end

do
  local function get_kernel_work_group_info_size(name)
    return function(kernel, device)
      local value = size_t_1()
      local status = C.clGetKernelWorkGroupInfo(kernel, device, name, ffi.sizeof(value), value, nil)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      return tonumber(value[0])
    end
  end

  local function get_kernel_work_group_info_sizes(name)
    return function(kernel, device)
      local value = size_t_3()
      local status = C.clGetKernelWorkGroupInfo(kernel, device, name, ffi.sizeof(value), value, nil)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      return {tonumber(value[0]), tonumber(value[1]), tonumber(value[2])}
    end
  end

  local function get_kernel_work_group_info_ulong(name)
    return function(kernel, device)
      local value = cl_ulong_1()
      local status = C.clGetKernelWorkGroupInfo(kernel, device, name, ffi.sizeof(value), value, nil)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      return tonumber(value[0])
    end
  end

  local kernel_work_group_info = {
    global_work_size                   = get_kernel_work_group_info_sizes(C.CL_KERNEL_GLOBAL_WORK_SIZE),
    work_group_size                    = get_kernel_work_group_info_size(C.CL_KERNEL_WORK_GROUP_SIZE),
    compile_work_group_size            = get_kernel_work_group_info_sizes(C.CL_KERNEL_COMPILE_WORK_GROUP_SIZE),
    local_mem_size                     = get_kernel_work_group_info_ulong(C.CL_KERNEL_LOCAL_MEM_SIZE),
    preferred_work_group_size_multiple = get_kernel_work_group_info_size(C.CL_KERNEL_PREFERRED_WORK_GROUP_SIZE_MULTIPLE),
    private_mem_size                   = get_kernel_work_group_info_ulong(C.CL_KERNEL_PRIVATE_MEM_SIZE),
  }

  function kernel.get_work_group_info(kernel, device, name)
    if name == nil then device, name = nil, device end
    return kernel_work_group_info[name](kernel, device)
  end
end

do
  local function get_kernel_info_string(name)
    return function(kernel)
      local size = size_t_1()
      local status = C.clGetKernelInfo(kernel, name, 0, nil, size)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      if size[0] == 0 then return end
      local value = char_n(size[0])
      local status = C.clGetKernelInfo(kernel, name, ffi.sizeof(value), value, nil)
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      return ffi.string(value, size[0] - 1)
    end
  end

  local function get_kernel_info_uint(name)
    return function(kernel)
      local value = cl_uint_1()
      local status = C.clGetKernelInfo(kernel, name, ffi.sizeof(value), value, nil)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      return value[0]
    end
  end

  local function get_kernel_info_context(kernel)
    local value = cl_context_1()
    local status = C.clGetKernelInfo(kernel, C.CL_KERNEL_CONTEXT, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return retain_context(value[0])
  end

  local function get_kernel_info_program(kernel)
    local value = cl_program_1()
    local status = C.clGetKernelInfo(kernel, C.CL_KERNEL_PROGRAM, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return retain_program(value[0])
  end

  local kernel_info = {
    function_name   = get_kernel_info_string(C.CL_KERNEL_FUNCTION_NAME),
    num_args        = get_kernel_info_uint(C.CL_KERNEL_NUM_ARGS),
    context         = get_kernel_info_context,
    program         = get_kernel_info_program,
    attributes      = get_kernel_info_string(C.CL_KERNEL_ATTRIBUTES),
  }

  function kernel.get_info(kernel, name)
    return kernel_info[name](kernel)
  end
end

local function release_command_queue(queue)
  local status = C.clReleaseCommandQueue(queue)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
end

local function retain_command_queue(queue)
  local status = C.clRetainCommandQueue(queue)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  return ffi.gc(queue, release_command_queue)
end

do
  local command_queue_properties = {
    out_of_order_exec_mode = C.CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE,
    profiling              = C.CL_QUEUE_PROFILING_ENABLE,
  }

  function context.create_command_queue(context, device, properties)
    if properties ~= nil then properties = strtobit(properties, command_queue_properties) else properties = 0 end
    local status = cl_int_1()
    local queue = C.clCreateCommandQueue(context, device, properties, status)
    if status[0] ~= C.CL_SUCCESS then return error(errors[status[0]]) end
    return ffi.gc(queue, release_command_queue)
  end
end

do
  local function get_command_queue_info_context(queue)
    local value = cl_context_1()
    local status = C.clGetCommandQueueInfo(queue, C.CL_QUEUE_CONTEXT, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return retain_context(value[0])
  end

  local function get_command_queue_info_device(queue)
    local value = cl_device_id_1()
    local status = C.clGetCommandQueueInfo(queue, C.CL_QUEUE_DEVICE, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return retain_device(value[0])
  end

  local command_queue_properties = {
    [C.CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE] = "out_of_order_exec_mode",
    [C.CL_QUEUE_PROFILING_ENABLE]              = "profiling",
  }

  local function get_command_queue_info_properties(queue)
    local value = cl_command_queue_properties_1()
    local status = C.clGetCommandQueueInfo(queue, C.CL_QUEUE_PROPERTIES, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return bittobool(tonumber(value[0]), command_queue_properties)
  end

  local queue_info = {
    context         = get_command_queue_info_context,
    device          = get_command_queue_info_device,
    properties      = get_command_queue_info_properties,
  }

  function queue.get_info(queue, name)
    return queue_info[name](queue)
  end
end

local function release_event(event)
  local status = C.clReleaseEvent(event)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
end

function queue.enqueue_ndrange_kernel(queue, kernel, global_offset, global_size, local_size, events)
  local work_dim = #global_size
  global_size = size_t_n(work_dim, global_size)
  if global_offset ~= nil then global_offset = size_t_n(work_dim, global_offset) end
  if local_size ~= nil then local_size = size_t_n(work_dim, local_size) end
  local num_events = events ~= nil and #events or 0
  if events ~= nil then events = cl_event_n(num_events, events) end
  local event = cl_event_1()
  local status = C.clEnqueueNDRangeKernel(queue, kernel, work_dim, global_offset, global_size, local_size, num_events, events, event)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  return ffi.gc(event[0], release_event)
end

do
  local map_buffer_flags = {
    read                    = C.CL_MAP_READ,
    write                   = C.CL_MAP_WRITE,
    write_invalidate_region = C.CL_MAP_WRITE_INVALIDATE_REGION,
  }

  function queue.enqueue_map_buffer(queue, buffer, blocking, flags, offset, size, events)
    if offset == nil and size == nil then offset, size = 0, buffer:get_info("size") end
    flags = strtobit(flags, map_buffer_flags)
    local num_events = events ~= nil and #events or 0
    if events ~= nil then events = cl_event_n(num_events, events) end
    local event = cl_event_1()
    local status = cl_int_1()
    local ptr = C.clEnqueueMapBuffer(queue, buffer, blocking, flags, offset, size, num_events, events, event, status)
    if status[0] ~= C.CL_SUCCESS then return error(errors[status[0]]) end
    return ptr, ffi.gc(event[0], release_event)
  end
end

function queue.enqueue_unmap_mem_object(queue, mem, ptr, events)
  local num_events = events ~= nil and #events or 0
  if events ~= nil then events = cl_event_n(num_events, events) end
  local event = cl_event_1()
  local status = C.clEnqueueUnmapMemObject(queue, mem, ptr, num_events, events, event)
	print(errors[status])
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  return ffi.gc(event[0], release_event)
end

function queue.enqueue_read_buffer(queue, buffer, blocking, offset, size, ptr, events)
  if ptr == nil then offset, size, ptr, events = nil, nil, offset, size end
  if offset == nil and size == nil then offset, size = 0, buffer:get_info("size") end
  local num_events = events ~= nil and #events or 0
  if events ~= nil then events = cl_event_n(num_events, events) end
  local event = cl_event_1()
  local status = C.clEnqueueReadBuffer(queue, buffer, blocking, offset, size, ptr, num_events, events, event)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  return ffi.gc(event[0], release_event)
end

function queue.enqueue_write_buffer(queue, buffer, blocking, offset, size, ptr, events)
  if ptr == nil then offset, size, ptr, events = nil, nil, offset, size end
  if offset == nil and size == nil then offset, size = 0, buffer:get_info("size") end
  local num_events = events ~= nil and #events or 0
  if events ~= nil then events = cl_event_n(num_events, events) end
  local event = cl_event_1()
  local status = C.clEnqueueWriteBuffer(queue, buffer, blocking, offset, size, ptr, num_events, events, event)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  return ffi.gc(event[0], release_event)
end

function queue.enqueue_copy_buffer(queue, src_buffer, dst_buffer, src_offset, dst_offset, size, events)
  if src_offset == nil and dst_offset == nil and size == nil then src_offset, dst_offset, size = 0, 0, src_buffer:get_info("size") end
  local num_events = events ~= nil and #events or 0
  if events ~= nil then events = cl_event_n(num_events, events) end
  local event = cl_event_1()
  local status = C.clEnqueueCopyBuffer(queue, src_buffer, dst_buffer, src_offset, dst_offset, size, num_events, events, event)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  return ffi.gc(event[0], release_event)
end

function queue.enqueue_fill_buffer(queue, buffer, pattern, pattern_size, offset, size, events)
  if offset == nil and size == nil then offset, size = 0, buffer:get_info("size") end
  local num_events = events ~= nil and #events or 0
  if events ~= nil then events = cl_event_n(num_events, events) end
  local event = cl_event_1()
  local status = C.clEnqueueFillBuffer(queue, buffer, pattern, pattern_size, offset, size, num_events, events, event)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  return ffi.gc(event[0], release_event)
end

function queue.enqueue_marker_with_wait_list(queue, events)
  local num_events = events ~= nil and #events or 0
  if events ~= nil then events = cl_event_n(num_events, events) end
  local event = cl_event_1()
  local status = C.clEnqueueMarkerWithWaitList(queue, num_events, events, event)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  return ffi.gc(event[0], release_event)
end

function queue.enqueue_marker(queue)
  local event = cl_event_1()
  local status = C.clEnqueueMarker(queue, event)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  return ffi.gc(event[0], release_event)
end

function queue.enqueue_barrier_with_wait_list(queue, events)
  local num_events = events ~= nil and #events or 0
  if events ~= nil then events = cl_event_n(num_events, events) end
  local event = cl_event_1()
  local status = C.clEnqueueBarrierWithWaitList(queue, num_events, events, event)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
  return ffi.gc(event[0], release_event)
end

function queue.enqueue_barrier(queue)
  local status = C.clEnqueueBarrier(queue)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
end

function queue.enqueue_wait_for_events(queue, events)
  local num_events = #events
  events = cl_event_n(num_events, events)
  local status = C.clEnqueueWaitForEvents(queue, num_events, events)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
end

function queue.flush(queue)
  local status = C.clFlush(queue)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
end

function queue.finish(queue)
  local status = C.clFinish(queue)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
end

function _M.wait_for_events(events)
  local num_events = #events
  events = cl_event_n(num_events, events)
  local status = C.clWaitForEvents(num_events, events)
  if status ~= C.CL_SUCCESS then return error(errors[status]) end
end

do
  local function get_event_info_command_queue(event)
    local value = cl_command_queue_1()
    local status = C.clGetEventInfo(event, C.CL_EVENT_COMMAND_QUEUE, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return retain_command_queue(value[0])
  end

  local function get_event_info_context(event)
    local value = cl_context_1()
    local status = C.clGetEventInfo(event, C.CL_EVENT_CONTEXT, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return retain_context(value[0])
  end

  local command_type = {
    [C.CL_COMMAND_NDRANGE_KERNEL]       = "ndrange_kernel",
    [C.CL_COMMAND_TASK]                 = "task",
    [C.CL_COMMAND_NATIVE_KERNEL]        = "native_kernel",
    [C.CL_COMMAND_READ_BUFFER]          = "read_buffer",
    [C.CL_COMMAND_WRITE_BUFFER]         = "write_buffer",
    [C.CL_COMMAND_COPY_BUFFER]          = "copy_buffer",
    [C.CL_COMMAND_READ_IMAGE]           = "read_image",
    [C.CL_COMMAND_WRITE_IMAGE]          = "write_image",
    [C.CL_COMMAND_COPY_IMAGE]           = "copy_image",
    [C.CL_COMMAND_COPY_BUFFER_TO_IMAGE] = "copy_buffer_to_image",
    [C.CL_COMMAND_COPY_IMAGE_TO_BUFFER] = "copy_image_to_buffer",
    [C.CL_COMMAND_MAP_BUFFER]           = "map_buffer",
    [C.CL_COMMAND_MAP_IMAGE]            = "map_image",
    [C.CL_COMMAND_UNMAP_MEM_OBJECT]     = "unmap_mem_object",
    [C.CL_COMMAND_MARKER]               = "marker",
    [C.CL_COMMAND_ACQUIRE_GL_OBJECTS]   = "acquire_gl_objects",
    [C.CL_COMMAND_RELEASE_GL_OBJECTS]   = "release_gl_objects",
    [C.CL_COMMAND_READ_BUFFER_RECT]     = "read_buffer_rect",
    [C.CL_COMMAND_WRITE_BUFFER_RECT]    = "write_buffer_rect",
    [C.CL_COMMAND_COPY_BUFFER_RECT]     = "copy_buffer_rect",
    [C.CL_COMMAND_USER]                 = "user",
  }

  local function get_event_info_command_type(event)
    local value = cl_command_type_1()
    local status = C.clGetEventInfo(event, C.CL_EVENT_COMMAND_TYPE, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return command_type[value[0]]
  end

  local command_execution_status = {
    [C.CL_QUEUED]    = "queued",
    [C.CL_SUBMITTED] = "submitted",
    [C.CL_RUNNING]   = "running",
    [C.CL_COMPLETE]  = "complete",
  }

  local function get_event_info_command_execution_status(event)
    local value = cl_int_1()
    local status = C.clGetEventInfo(event, C.CL_EVENT_COMMAND_EXECUTION_STATUS, ffi.sizeof(value), value, nil)
    if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
    if status ~= C.CL_SUCCESS then return error(errors[status]) end
    return command_execution_status[value[0]]
  end

  local event_info = {
    command_queue            = get_event_info_command_queue,
    context                  = get_event_info_context,
    command_type             = get_event_info_command_type,
    command_execution_status = get_event_info_command_execution_status,
  }

  function event.get_info(event, name)
    return event_info[name](event)
  end
end

do
  local function get_event_profiling_info(name)
    return function(event)
      local value = cl_ulong_1()
      local status = C.clGetEventProfilingInfo(event, name, ffi.sizeof(value), value, nil)
      if status == C.CL_INVALID_VALUE or status == C.CL_INVALID_OPERATION then return end
      if status ~= C.CL_SUCCESS then return error(errors[status]) end
      return value[0]
    end
  end

  local event_profiling_info = {
    queued  = get_event_profiling_info(C.CL_PROFILING_COMMAND_QUEUED),
    submit  = get_event_profiling_info(C.CL_PROFILING_COMMAND_SUBMIT),
    start   = get_event_profiling_info(C.CL_PROFILING_COMMAND_START),
    ["end"] = get_event_profiling_info(C.CL_PROFILING_COMMAND_END),
  }

  function event.get_profiling_info(event, name)
    return event_profiling_info[name](event)
  end
end

ffi.metatype("struct _cl_platform_id",   {__index = platform})
ffi.metatype("struct _cl_device_id",     {__index = device  })
ffi.metatype("struct _cl_context",       {__index = context })
ffi.metatype("struct _cl_mem",           {__index = mem     })
ffi.metatype("struct _cl_command_queue", {__index = queue   })
ffi.metatype("struct _cl_program",       {__index = program })
ffi.metatype("struct _cl_kernel",        {__index = kernel  })
ffi.metatype("struct _cl_event",         {__index = event   })

return _M
