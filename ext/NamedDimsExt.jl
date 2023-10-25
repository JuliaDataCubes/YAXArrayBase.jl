module NamedDimsExt

using NamedDims: NamedDimsArray
import YAXArrayBase: dimname, dimnames, dimvals, iscontdim, getattributes, getdata, yaxcreate, valfromaxis
dimname(a::NamedDimsArray{N},i) where N = N[i]
dimnames(a::NamedDimsArray{N}) where N = N
getdata(a::NamedDimsArray) = parent(a)
function yaxcreate(::Type{<:NamedDimsArray},data, dnames, dvals, atts)
  n = ntuple(i->dnames[i],ndims(data))
  NamedDimsArray(data,n)
end
end