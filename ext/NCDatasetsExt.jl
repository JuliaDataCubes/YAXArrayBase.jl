module NCDatasetsExt

import YAXArrayBase: YAXArrayBase as YAB
using NCDatasets

"""
    NCDatasetsDataset

Dataset backend to read NetCDF files using NCDatasets.jl
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
            close(ds.handle[])
            ds.handle[] = nothing
        end
    else
        f(ds)
    end
end

# Implement the DiskArrays read/write interface
import DiskArrays: AbstractDiskArray
import NCDatasets: readblock!, writeblock!, haschunks, eachchunk

# --- Variable representation ---
struct NCDatasetsVariable{T,N} <: AbstractDiskArray{T,N}
    filename::String
    mode::String
    varname::String
    size::NTuple{N,Int}
end

Base.size(v::NCDatasetsVariable) = v.size

function readblock!(v::NCDatasetsVariable, aout, r::AbstractUnitRange...)
    NCDataset(v.filename, v.mode) do nc
        aout .= nc[v.varname][r...]
    end
end

function writeblock!(v::NCDatasetsVariable, a, r::AbstractUnitRange...)
    NCDataset(v.filename, "a") do nc
        nc[v.varname][r...] = a
    end
end

# NCDatasets supports querying the deflate level from the variable
function YAB.iscompressed(v::NCDatasetsVariable)
    NCDataset(v.filename, v.mode) do nc
        cfvar = nc[v.varname]
        rawvar = hasproperty(cfvar, :var) ? cfvar.var : cfvar
        isshuffled, isdeflated, deflate_level = deflate(rawvar)
        return isdeflated && deflate_level > 0
    end
end

# --- Dataset interface implementations ---
YAB.get_varnames(ds::NCDatasetsDataset) = dsopen(nc -> collect(keys(nc)), ds)
YAB.get_var_dims(ds::NCDatasetsDataset, name) = [dsopen(nc -> dimnames(nc[name]), ds)...]
YAB.get_var_attrs(ds::NCDatasetsDataset, name) = dsopen(nc -> Dict(nc[name].attrib), ds)
YAB.get_global_attrs(ds::NCDatasetsDataset) = dsopen(nc -> Dict(nc.attrib), ds)
Base.haskey(ds::NCDatasetsDataset, k) = dsopen(nc -> haskey(nc, k), ds)

function YAB.get_var_handle(ds::NCDatasetsDataset, i; persist = true)
    if persist || ds.handle[] === nothing
        s, et = dsopen(nc -> (size(nc[i]), eltype(nc[i])), ds)
        NCDatasetsVariable{et, length(s)}(ds.filename, ds.mode, i, s)
    else
        ds.handle[][i]
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

        # Set up compression options
        deflatelevel = compress > -1 ? min(compress, 9) : 0
        shuffle = deflatelevel > 0

        # Define the compressed variable natively in NCDatasets
        defVar(nc, varname, T, dimnames,
               attrib = attr,
               chunksizes = chunksize,
               deflatelevel = deflatelevel,
               shuffle = shuffle,
               zstdlevel = zstdlevel)
    end

    NCDatasetsVariable{T, length(s)}(p.filename, p.mode, varname, s)
end

# --- Parallel and Missings support flags ---
YAB.allow_parallel_write(::Type{<:NCDatasetsDataset}) = false
YAB.allow_parallel_write(::NCDatasetsDataset) = false
YAB.allow_missings(::Type{<:NCDatasetsDataset}) = true
YAB.allow_missings(::NCDatasetsDataset) = true

# --- Extension Registration ---
function __init__()
    @debug "new driver key :ncdatasets, updating backendlist."
    YAB.backendlist[:ncdatasets] = NCDatasetsDataset
    push!(YAB.backendregex, r".nc$" => NCDatasetsDataset)
end

end # module
