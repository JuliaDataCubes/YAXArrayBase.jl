module AxisIndicesExt
import YAXArrayBase: dimname, dimnames, dimvals, iscontdim, getattributes, getdata, yaxcreate, valfromaxis
using AxisIndices

valfromaxis(ax::AxisIndices.AbstractAxis) = keys(ax)

getdata(a::AxisIndices.AxisIndicesArray) = parent(a)

yaxcreate(::Type{<:AxisIndices.AxisIndicesArray}, data, dnames, dvals, atts) =
  AxisIndices.AxisIndicesArray(data, (dvals...,))
end