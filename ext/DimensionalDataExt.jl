module DimensionalDataExt
using DimensionalData: DimArray, DimensionalData, data, Dim, metadata
import YAXArrayBase: dimname, dimnames, dimvals, dimtype, iscontdim, getattributes, getdata, yaxcreate
_dname(::DimensionalData.Dim{N}) where N = N
_dname(d::DimensionalData.Dimension) = DimensionalData.name(d)
dimname(x::DimArray, i) = _dname(DimensionalData.dims(x)[i])


dimvals(x::DimArray,i) = DimensionalData.dims(x)[i].val

# the dimension's type with its parameters stripped: `D1` for a `D1`, `Dim{:lon}` for a `Dim{:lon}`
dimtype(x::DimArray, i) = DimensionalData.basetypeof(DimensionalData.dims(x)[i])

getdata(x::DimArray) = data(x)

getattributes(x::DimArray) = metadata(x)

function yaxcreate(::Type{<:DimArray},data,dnames,dvals,atts)
  d = ntuple(ndims(data)) do i
    Dim{Symbol(dnames[i])}(dvals[i])
  end
  DimArray(data,d,metadata = atts)
end

# with dimension types from the source where it has them
function yaxcreate(::Type{<:DimArray},data,dnames,dtypes,dvals,atts)
  d = ntuple(ndims(data)) do i
    T = dtypes[i]
    T === nothing ? Dim{Symbol(dnames[i])}(dvals[i]) : T(dvals[i])
  end
  DimArray(data,d,metadata = atts)
end
end