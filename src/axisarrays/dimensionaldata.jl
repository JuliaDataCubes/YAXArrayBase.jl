using .DimensionalData: DimensionalArray, DimensionalData, data, Dim, metadata

_dname(::DimensionalData.Dim{N}) where N = N
dimname(x::DimensionalArray, i) = _dname(DimensionalData.dims(x)[i])


dimvals(x::DimensionalArray,i) = DimensionalData.dims(x)[i].val

getdata(x::DimensionalArray) = data(x)

getattributes(x::DimensionalArray) = metadata(x)

function yaxcreate(::Type{<:DimensionalArray},data,dnames,dvals,atts)
  d = ntuple(ndims(data)) do i
    Dim{Symbol(dnames[i])}(dvals[i])
  end
  DimensionalArray(data,d,metadata = atts)
end
