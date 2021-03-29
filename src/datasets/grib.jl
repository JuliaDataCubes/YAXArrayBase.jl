using .CfGRIB: CfGRIB
using DiskArrays: AbstractDiskArray, DiskArrays, GridChunks
# Define a DiskArray version of OnDiskArray, which is actually a subtype of AbstractArray
struct CFDiskVariable{T,N} <: AbstractDiskArray{T,N}
    a::CfGRIB.OnDiskArray
    s::NTuple{N,Int}
    cs::GridChunks{N}
end
function CFDiskVariable(d::CfGRIB.OnDiskArray)
    s = size(d)
    N = length(s)
    cs = reverse(DiskArrays.estimate_chunksize(reverse(s), sizeof(d.dtype)))
    CFDiskVariable{d.dtype,N}(d, s, GridChunks(s,cs))
end
Base.size(v::CFDiskVariable) = v.s
DiskArrays.eachchunk(b::CFDiskVariable) = b.cs
DiskArrays.haschunks(::CFDiskVariable) = DiskArrays.Chunked()
function DiskArrays.readblock!(b::CFDiskVariable,aout,r::AbstractUnitRange...)
    res = b.a[r...]
    aout .= reshape(res, size(aout))
    nothing
end

#And implement the Dataset interface
struct CfGRIBDataset
    ds::CfGRIB.DataSet
end
YAXArrayBase.to_dataset(::Type{CfGRIBDataset},p::String) = CfGRIBDataset(CfGRIB.DataSet(p))
toarray(a::CfGRIB.OnDiskArray) = CFDiskVariable(a)
toarray(a) = a
toarray(a::Number) = fill(a)
function YAXArrayBase.get_var_handle(ds::CfGRIBDataset, name) 
    toarray(ds.ds.variables[string(name)].data)
end
Base.haskey(ds::CfGRIBDataset, k) = haskey(ds.ds.variables, k)

YAXArrayBase.get_varnames(ds::CfGRIBDataset) = collect(keys(ds.ds.variables))

YAXArrayBase.get_var_dims(ds::CfGRIBDataset, k) = ds.ds.variables[k].dimensions

function YAXArrayBase.get_var_attrs(ds::CfGRIBDataset,name)
    ds.ds.variables[string(name)].attributes
end

using YAXArrayBase: backendlist, backendregex
backendlist[:GRIB] = CfGRIBDataset
push!(backendregex,r".grb$"=>CfGRIBDataset)
push!(backendregex,r".grib$"=>CfGRIBDataset);

