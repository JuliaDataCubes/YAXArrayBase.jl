module AxisArraysExt
using AxisArrays: AxisArrays, AxisArray
import YAXArrayBase: dimname, dimnames, dimvals, iscontdim, getattributes, getdata, yaxcreate
dimname(a::AxisArray, i) = AxisArrays.axisnames(a)[i]
dimnames(a::AxisArray) = AxisArrays.axisnames(a)
dimvals(a::AxisArray, i) = AxisArrays.axisvalues(a)[i]
iscontdim(a::AxisArray, i) = AxisArrays.axistrait(AxisArrays.axes(a,i)) <: AxisArrays.Dimensional
getdata(a::AxisArray) = parent(a)
function yaxcreate(::Type{<:AxisArray}, data, dnames, dvals, atts)
  d = ntuple(ndims(data)) do i
    dnames[i] => dvals[i]
  end
  AxisArray(data; d...)
end
end