dimvals(x::NamedTuple,i) = x.axes[i]

_dname(::NamedTuple{N},i) where N = N[i]
_dname(::Tuple,i) = Symbol("Dim_",i)
dimname(x::NamedTuple, i) = _dname(x.axes,i)

#Special method to get all dim names
dimnames(x::NamedTuple) = _dnames(x.axes)
_dnames(::NamedTuple{N}) where N = N
_dnames(x) = ntuple(i->Symbol("Dim_",i), length(x))

getdata(x::NamedTuple) = x.values

function yaxcreate(::Type{<:NamedTuple},data,dnames,dvals,atts)
  axes = NamedTuple{dnames}(dvals)
  (axes = axes, values = data)
end
