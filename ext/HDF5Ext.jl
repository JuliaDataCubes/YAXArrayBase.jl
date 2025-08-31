module HDF5Ext
import YAXArrayBase: YAXArrayBase as YAB
using HDF5

"""
    HDF5Dataset

Dataset backend to read HDF5 files using HDF5.jl
"""
struct HDF5Dataset
    filename::String
    mode::String
    handle::Base.RefValue{Union{Nothing,HDF5.File}}
end
function HDF5Dataset(filename; mode="r")
    HDF5Dataset(filename, mode, Ref{Union{Nothing,HDF5.File}}(nothing))
end
function dsopen(f, ds::HDF5Dataset)
    if ds.handle[] === nothing || !Base.isopen(ds.handle[])
        HDF5.h5open(f, ds.filename, ds.mode)
    else
        f(ds.handle[])
    end
end
function YAB.open_dataset_handle(f, ds::HDF5Dataset)
    if ds.handle[] === nothing || !Base.isopen(ds.handle[])
        try
            ds.handle[] = HDF5.h5open(ds.filename, ds.mode)
            f(ds)
        finally
            ds.handle[] = nothing
        end
    else
        f(ds)
    end
end

function __init__()
    @debug "new driver key :HDF5, updating backendlist."
    YAB.backendlist[:HDF5] = HDF5Dataset
    push!(YAB.backendregex, r".h5$" => HDF5Dataset)
end

function get_all_paths(file, prefix="")
    paths = String[]

    for key in keys(file)
        full_path = isempty(prefix) ? key : "$prefix/$key"
        obj = file[key]

        if isa(obj, HDF5.Dataset)
            push!(paths, full_path)
        elseif isa(obj, HDF5.Group)
            append!(paths, get_all_paths(obj, full_path))
        end
    end

    return paths
end

function get_dims(f, var)
    dims = String[]
    ds = f[var]
    if haskey(ds, "DIMENSION_LIST")
        dimension_list = read_attribute(ds, "DIMENSION_LIST")
        for dimensions in dimension_list
            for dim_ref in dimensions
                push!(dims, HDF5.name(f[dim_ref]))
            end
        end
    end
    return dims
end

"Return a list of variable names"
YAB.get_varnames(ds::HDF5Dataset) = dsopen(get_all_paths, ds)

"Return a list of dimension names for a given variable"
YAB.get_var_dims(ds::HDF5Dataset, name) = dsopen(x -> get_dims(x, name), ds)

function get_var_attrs(file, name)
    attributes = Dict(attrs(file[name]))
    pop!(attributes, "DIMENSION_LIST", nothing)  # Remove DIMENSION_LIST if present
    return attributes
end

"Return a dict with the attributes for a given variable"
YAB.get_var_attrs(ds::HDF5Dataset, name) = dsopen(v -> get_var_attrs(v, name), ds)

"Return a dict with global attributes for the dataset"
YAB.get_global_attrs(ds::HDF5Dataset) = dsopen(h5 -> Dict(attrs(h5)), ds)

"Return a DiskArray handle to a dataset"
function YAB.get_var_handle(ds::HDF5Dataset, i; persist=true)
    if persist || ds.handle[] === nothing
        s, et = NetCDF.open(j -> (size(j), eltype(j)), ds.filename, i)
        NetCDFVariable{et,length(s)}(ds.filename, i, s)
    else
        ds.handle[][i]
    end
end
Base.haskey(ds::HDF5Dataset, k) = dsopen(h5 -> haskey(h5, k), ds)


end
