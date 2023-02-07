module AxisIndicesExt
using AxisIndices: AxisIndices, AbstractAxis,AxisArray
import YAXArrayBase: valfromaxis, getdata, yaxcreate
valfromaxis(ax::AbstractAxis) = keys(ax)

getdata(a::AxisIndices.AxisArray) = parent(a)

yaxcreate(::Type{<:AxisIndices.AxisArray}, data, dnames, dvals, atts) =
  AxisIndices.AxisArray(data, (dvals...,))

end