module DimensionalDataExt
using DimensionalData: DimArray, DimensionalData, data, Dim, metadata, NoMetadata, Metadata, val
import YAXArrayBase: dimname, dimnames, dimvals, iscontdim, getattributes, getdata, yaxcreate
_dname(::DimensionalData.Dim{N}) where N = N
_dname(d::DimensionalData.Dimension) = DimensionalData.name(d)
dimname(x::DimArray, i) = _dname(DimensionalData.dims(x)[i])


dimvals(x::DimArray,i) = DimensionalData.dims(x)[i].val

getdata(x::DimArray) = data(x)

# the interface promises a Dict with String keys; DimensionalData's default metadata is
# `NoMetadata()` and its `Metadata` wraps a Dict whose keys may be Symbols
getattributes(x::DimArray) = _attributes(metadata(x))
_attributes(::NoMetadata) = Dict{String,Any}()
_attributes(m::Metadata) = _attributes(val(m))
_attributes(d::AbstractDict) = Dict{String,Any}(string(k) => v for (k, v) in d)
_attributes(m) = m

function yaxcreate(::Type{<:DimArray},data,dnames,dvals,atts)
  d = ntuple(ndims(data)) do i
    Dim{Symbol(dnames[i])}(dvals[i])
  end
  DimArray(data,d,metadata = atts)
end
end