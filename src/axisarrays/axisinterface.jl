# Functions to be implemented, so that an array type
# can be used as an ESDLArray. Here fakkback methods are implemented
# for the AbstractArray's
dimvals(x::AbstractArray, i) = valfromaxis(axes(x,i))

dimname(::AbstractArray,i) = Symbol("Dim_",i)
#Mandatory interface ends here
# Optional methods
function iscontdim(x, i)
  v = dimvals(x,i)
  (eltype(v) <: Number) && (issorted(v) || issorted(v,rev=true))
end

iscompressed(x) = false

dimnames(x::AbstractArray) = ntuple(i->dimname(x,i), ndims(x))

getattributes(x) = Dict{String,Any}()

getdata(x) = x

valfromaxis(x) = x
