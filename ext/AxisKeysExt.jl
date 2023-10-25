module AxisKeysExt
using AxisKeys
import YAXArrayBase: dimname, dimnames, dimvals, iscontdim, getattributes, getdata, yaxcreate, valfromaxis

dimnames(a::AxisKeys.KeyedArray) = AxisKeys.dimnames(a)

dimvals(a::AxisKeys.KeyedArray,i) = AxisKeys.getproperty(a,AxisKeys.dimnames(a,i))

getdata(a::AxisKeys.KeyedArray) = parent(parent(a))

yaxcreate(::Type{<:AxisKeys.KeyedArray}, data, dnames, dvals, atts) =
  AxisKeys.KeyedArray(data; map(i->dnames[i]=>dvals[i],1:ndims(data))...)
end