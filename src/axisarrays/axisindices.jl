using .AxisIndices: AbstractAxis,AxisIndices

valfromaxis(ax::AbstractAxis) = keys(ax)

getdata(a::AxisIndices.AxisIndicesArray) = parent(a)

yaxcreate(::Type{<:AxisIndices.AxisIndicesArray}, data, dnames, dvals, atts) =
  AxisIndices.AxisIndicesArray(data, (dvals...,))
