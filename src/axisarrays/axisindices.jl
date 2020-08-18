using .AxisIndices: AbstractAxis,AxisIndices

valfromaxis(ax::AbstractAxis) = keys(ax)

getdata(a::AxisIndices.AxisArray) = parent(a)

yaxcreate(::Type{<:AxisIndices.AxisArray}, data, dnames, dvals, atts) =
  AxisIndices.AxisArray(data, map(i->dvals[i], 1:ndims(data))...)
