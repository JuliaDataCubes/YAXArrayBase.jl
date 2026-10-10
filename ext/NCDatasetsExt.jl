module NCDatasetsExt

import YAXArrayBase: YAXArrayBase as YAB
using NCDatasets

"""
    NCDatasetsDataset

Dataset backend to read NetCDF files using NCDatasets.jl

Variables are handed to YAXArrays as raw storage values (`nc[name].var`):
YAXArrays applies `missing_value`, `scale_factor`, `add_offset` and time
units itself, as it does for the NetCDF.jl backend.

The following keyword arguments are allowed when using :ncdatasets
as a data sink:

- `compress = -1` set the deflate level for the NetCDF file
- `zstdlevel = nothing` set the Zstandard level (requires an NCDatasets
  with Zstandard support and the zstd HDF5 filter, e.g. H5Zzstd)
"""
struct NCDatasetsDataset
    filename::String
    mode::String
    handle::Base.RefValue{Union{Nothing, NCDataset}}
end

function NCDatasetsDataset(filename; mode="r")
    NCDatasetsDataset(filename, mode, Ref{Union{Nothing, NCDataset}}(nothing))
end

# Helper to execute a function block with a safe file handle
function dsopen(f, ds::NCDatasetsDataset)
    if ds.handle[] === nothing
        NCDataset(ds.filename, ds.mode) do nc
            f(nc)
        end
    else
        f(ds.handle[])
    end
end

function YAB.open_dataset_handle(f, ds::NCDatasetsDataset)
    if ds.handle[] === nothing
        try
            ds.handle[] = NCDataset(ds.filename, ds.mode)
            f(ds)
        finally
            ds.handle[] === nothing || close(ds.handle[])
            ds.handle[] = nothing
        end
    else
        f(ds)
    end
end

# Implement the DiskArrays read/write interface
import DiskArrays: AbstractDiskArray, readblock!, writeblock!, haschunks, eachchunk

# raw storage variable, bypassing the CF layer of NCDatasets (see above)
rawvar(nc, name) = nc[name].var

# --- Variable representation ---
struct NCDatasetsVariable{T,N} <: AbstractDiskArray{T,N}
    filename::String
    mode::String
    varname::String
    size::NTuple{N,Int}
end

Base.size(v::NCDatasetsVariable) = v.size

readblock!(v::NCDatasetsVariable, aout, r::AbstractUnitRange...) =
    NCDataset(nc -> (aout .= rawvar(nc, v.varname)[r...]; nothing), v.filename, v.mode)
writeblock!(v::NCDatasetsVariable, a, r::AbstractUnitRange...) =
    NCDataset(nc -> (rawvar(nc, v.varname)[r...] = a; nothing), v.filename, "a")
for m in (:haschunks, :eachchunk)
    @eval $m(v::NCDatasetsVariable) =
        NCDataset(nc -> $m(rawvar(nc, v.varname)), v.filename, v.mode)
end

# deflate or Zstandard (the latter only with an NCDatasets that supports it)
function YAB.iscompressed(v::NCDatasetsVariable)
    NCDataset(v.filename, v.mode) do nc
        rv = rawvar(nc, v.varname)
        _, isdeflated, level = deflate(rv)
        iszstd = isdefined(NCDatasets, :zstandard) && first(NCDatasets.zstandard(rv))
        (isdeflated && level > 0) || iszstd
    end
end

# --- Dataset interface implementations ---
YAB.get_varnames(ds::NCDatasetsDataset) = dsopen(nc -> collect(keys(nc)), ds)
YAB.get_var_dims(ds::NCDatasetsDataset, name) = dsopen(nc -> collect(dimnames(nc[name])), ds)
YAB.get_global_attrs(ds::NCDatasetsDataset) = dsopen(nc -> Dict(nc.attrib), ds)
Base.haskey(ds::NCDatasetsDataset, k) = dsopen(nc -> haskey(nc, k), ds)

function YAB.get_var_attrs(ds::NCDatasetsDataset, name)
    dsopen(ds) do nc
        a = Dict{String,Any}(string(k) => v for (k, v) in nc[name].attrib)
        # YAXArrays only honours missing_value; let _FillValue count too
        haskey(a, "_FillValue") && !haskey(a, "missing_value") &&
            (a["missing_value"] = a["_FillValue"])
        a
    end
end

function YAB.get_var_handle(ds::NCDatasetsDataset, i; persist = true)
    if persist || ds.handle[] === nothing
        s, et = dsopen(nc -> (size(rawvar(nc, i)), eltype(rawvar(nc, i))), ds)
        NCDatasetsVariable{et, length(s)}(ds.filename, ds.mode, i, s)
    else
        rawvar(ds.handle[], i)
    end
end

# --- Dataset creation and variable addition ---
function YAB.create_empty(::Type{NCDatasetsDataset}, path, gatts=Dict())
    NCDataset(path, "c", attrib = gatts) do nc
        # Creates file structure on disk
    end
    NCDatasetsDataset(path, mode="a") # Return in append mode
end

function YAB.add_var(p::NCDatasetsDataset, T::Type, varname, s, dimnames, attr;
    chunksize=s, compress = -1, zstdlevel = nothing)

    dsopen(p) do nc
        # Define dimensions if they don't exist yet
        for (dname, dlen) in zip(dimnames, s)
            if !haskey(nc.dim, dname)
                defDim(nc, dname, dlen)
            end
        end

        # only pass the storage options that are actually requested; in
        # particular zstdlevel is not understood by every NCDatasets version
        kw = (; chunksizes = chunksize, attrib = attr)
        compress > -1 && (kw = (; kw..., deflatelevel = min(compress, 9), shuffle = true))
        zstdlevel === nothing || (kw = (; kw..., zstdlevel))
        defVar(nc, varname, T, dimnames; kw...)
    end

    NCDatasetsVariable{T, length(s)}(p.filename, p.mode, varname, s)
end

# --- Parallel and Missings support flags ---
YAB.allow_parallel_write(::Type{<:NCDatasetsDataset}) = false
YAB.allow_parallel_write(::NCDatasetsDataset) = false
# NCDatasets' defVar wants a DataType; Union{Missing,T} is handled by
# YAXArrays through missing_value, as for NetCDF.jl
YAB.allow_missings(::Type{<:NCDatasetsDataset}) = false
YAB.allow_missings(::NCDatasetsDataset) = false

# --- Extension Registration ---
function __init__()
    @debug "new driver key :ncdatasets, updating backendlist."
    YAB.backendlist[:ncdatasets] = NCDatasetsDataset
    push!(YAB.backendregex, r".nc$" => NCDatasetsDataset)
end

end # module
