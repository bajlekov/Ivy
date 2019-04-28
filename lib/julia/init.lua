local ffi = require "ffi"
local bit = require "bit"

assert(jit.arch == "x64", "Only x64 support yet")

local dllpath = "lib/julia/"

do
	--gcc -Iinclude/julia -E stub.c -o out.h
	local header = io.open(dllpath.."julia.h", "r")
	ffi.cdef(header:read("*a"))
	header:close()
end

local jl
if jit.os == "Windows" then
	dllpath = dllpath.."Windows/"

	-- dependencies of libjulia.dll from dumpbin.exe
	ffi.load(dllpath.."libwinpthread-1.dll", true)
	ffi.load(dllpath.."libgcc_s_seh-1.dll", true)
	ffi.load(dllpath.."libssp-0.dll", true)
	ffi.load(dllpath.."libstdc++-6.dll", true)
	ffi.load(dllpath.."LLVM.dll", true)
	jl = ffi.load(dllpath.."libjulia.dll", true)
	--jl = ffi.load(dllpath.."libjulia-debug.dll", true)

	-- runtime dependencies
	ffi.load(dllpath.."libpcre2-8.dll", true)
	ffi.load(dllpath.."libgmp.dll", true)
	ffi.load(dllpath.."libmpfr.dll", true)
	ffi.load(dllpath.."libdSFMT.dll", true)
	ffi.load(dllpath.."libquadmath-0.dll", true)
	ffi.load(dllpath.."libgfortran-3.dll", true)
	ffi.load(dllpath.."libopenblas64_.dll", true)
	ffi.load(dllpath.."libssh2.dll", true)
	ffi.load(dllpath.."libgit2.dll", true)

	-- runtime warnings
	ffi.load(dllpath.."libsuitesparseconfig.dll", true)
	ffi.load(dllpath.."libccolamd.dll", true)
	ffi.load(dllpath.."libcamd.dll", true)
	ffi.load(dllpath.."libamd.dll", true)
	ffi.load(dllpath.."libcolamd.dll", true)
	ffi.load(dllpath.."libcholmod.dll", true)
	ffi.load(dllpath.."libsuitesparse_wrapper.dll", true)

	---[[ Remaining Julia dlls
  ffi.load(dllpath.."7z.dll", true)
  --ffi.load(dllpath.."libarpack.dll", true)
  ffi.load(dllpath.."libccalltest.dll", true)
  ffi.load(dllpath.."libexpat-1.dll", true)
  --ffi.load(dllpath.."libfftw3.dll", true)         -- fft functions
  --ffi.load(dllpath.."libfftw3f.dll", true)        -- fft functions
  ffi.load(dllpath.."libmbedcrypto.dll", true)
  ffi.load(dllpath.."libmbedx509.dll", true)
  ffi.load(dllpath.."libmbedtls.dll", true)
  ffi.load(dllpath.."libopenlibm.dll", true)
  --ffi.load(dllpath.."libopenspecfun.dll", true)
  ffi.load(dllpath.."libpcre2-posix.dll", true)
  ffi.load(dllpath.."libspqr.dll", true)
  ffi.load(dllpath.."libumfpack.dll", true)
  --ffi.load(dllpath.."libuv-2.dll", true)
  ffi.load(dllpath.."zlib1.dll", true)
	ffi.load(dllpath.."libatomic-1.dll", true)
  --]]

	ffi.cdef [[
	__attribute__ ((visibility("default"))) void jl_init__threading(void);
	__attribute__ ((visibility("default"))) void jl_init_with_image__threading(const char *julia_bindir, const char *image_relative_path);
	]]

	jl.jl_init_with_image__threading(dllpath, "sys.dll")

elseif jit.os == "Linux" then
	dllpath = dllpath.."Linux/"

	jl = ffi.load(dllpath.."libjulia.so", true)

	-- runtime dependencies
	ffi.load(dllpath.."libgfortran.so", true)
	ffi.load(dllpath.."libopenblas64_.so", true)

	-- additional libraries as needed

	jl.jl_init_with_image__threading("lib/julia/Linux/", "sys.so")
end

-- helper functions
local function jl_astaggedvalue(v)
	return ffi.cast("jl_taggedvalue_t*", ffi.cast("char*", v) - ffi.sizeof("jl_taggedvalue_t"))
end
local function jl_typeof(v)
	return ffi.cast("jl_value_t*", bit.band(jl_astaggedvalue(v).header, bit.bnot(ffi.cast("uintptr_t", 15))))
end
local function jl_typeis(v, t)
	return jl_typeof(v) == ffi.cast("jl_value_t*", t)
end
local function jl_get_function(m, name)
	return ffi.cast("jl_function_t*", jl.jl_get_global(m, jl.jl_symbol(name)))
end
local function jl_call(fun, ...)
	local args = {...}
	local nargs = #args
	local jl_args = ffi.new("jl_value_t* [?]", nargs)
	for k, v in ipairs(args) do
		jl_args[k - 1] = ffi.cast("jl_value_t *", v) -- automatically cast arguments to jl_value_t
	end
	return jl.jl_call(fun, jl_args, nargs)
end


local frames = {} -- keep reference to gc frames to allow gc operation on frames

local function jl_gc_push(...) -- push multiple values in a gc frame onto the gc stack
	local args = {...}
	local nargs = #args
	local frame = ffi.new("void*[?]", nargs + 2)

	frames[tonumber(ffi.cast("uintptr_t", frame))] = frame

	frame[0] = ffi.cast("void*", nargs * 2)
	frame[1] = jl.jl_get_ptls_states().pgcstack
	for k, v in ipairs(args) do
		frame[k + 1] = ffi.cast("void*", v)
	end
	jl.jl_get_ptls_states().pgcstack = ffi.cast("jl_gcframe_t*", frame)
end
local function jl_gc_pop()
	local frame = jl.jl_get_ptls_states().pgcstack
	jl.jl_get_ptls_states().pgcstack = jl.jl_get_ptls_states().pgcstack.prev
	frames[tonumber(ffi.cast("uintptr_t", frame))] = nil
	collectgarbage("collect")
end


local julia = {}

local float32 = ffi.cast("jl_value_t*", jl.jl_float32_type)
local int64 = ffi.cast("jl_value_t*", jl.jl_int64_type)

local float32_3D_array = jl.jl_apply_array_type(float32, 3)
local float32_2D_array = jl.jl_apply_array_type(float32, 2)
local float32_1D_array = jl.jl_apply_array_type(float32, 1)

local int64_3D_tuple = jl.jl_apply_tuple_type_v(ffi.new("jl_value_t* [3]", int64, int64, int64), 3)
local int64_2D_tuple = jl.jl_apply_tuple_type_v(ffi.new("jl_value_t* [2]", int64, int64), 2)

local dims_3D = jl.jl_new_struct_uninit(int64_3D_tuple)
local dims_2D = jl.jl_new_struct_uninit(int64_2D_tuple)

local dims_3D_data = ffi.cast("int64_t*", dims_3D)
local dims_2D_data = ffi.cast("int64_t*", dims_2D)

jl_gc_push(float32_3D_array, float32_2D_array, float32_1D_array)
jl_gc_push(int64_3D_tuple, int64_2D_tuple)
jl_gc_push(dims_3D, dims_2D)

jl.jl_gc_collect(0)

-- which values to anchor for GC?

function julia.array(buffer)
	if type(buffer)=="table" and buffer.type=="data" then
		-- TODO: check strides
		assert(buffer.sx<=buffer.sy)
		assert(buffer.sy<=buffer.sz)
		local data = buffer.data
		dims_3D_data[0] = buffer.x
		dims_3D_data[1] = buffer.y
		dims_3D_data[2] = buffer.z
		return jl.jl_ptr_to_array(float32_3D_array, data, dims_3D, 0)
	end

	if type(buffer)=="cdata" then
		return jl.jl_ptr_to_array_1d(float32_1D_array, buffer, ffi.sizeof(buffer)/4, 0)
	end
end

julia.gcPush = jl_gc_push
julia.gcPop = jl_gc_pop
function julia.gcEnable() jl.jl_gc_enable(1) end
function julia.gcDisable() jl.jl_gc_enable(0) end
function julia.gcCollect() jl.jl_gc_collect(0) end

julia.evalString = jl.jl_eval_string
function julia.evalFile(input)
	local source = io.open(input, "rb")
	local string = source:read("*a")
	source:close()
	return julia.evalString(string)
end

function julia.evalFunction(fun, ...)
	if type(fun)=="string" then
		fun = jl_get_function(jl.jl_main_module, fun)
	end
	return jl_call(fun, ...)
end

function julia.evalBaseFunction(fun, ...)
	local fun = jl_get_function(jl.jl_base_module, fun)
	return jl_call(fun, ...)
end

julia.type = jl_typeof

function julia.print(...)
	julia.evalBaseFunction("println", ...)
end

local s = julia.evalString [["[OK] Julia subsystem initialized"]]
julia.print(s)

return julia
