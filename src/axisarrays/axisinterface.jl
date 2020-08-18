import Dates: TimeType
# Functions to be implemented, so that an array type
# can be used as an YAXArray. Here fakkback methods are implemented
# for the AbstractArray's
"""
    dimvals(x, i)

Returns the values associated to the i-th dimensions of the
array `x`
"""
dimvals(x::AbstractArray, i) = valfromaxis(axes(x,i))

"""
    dimname(x,i)

Returns the name of the i-th dimension of the array x as a symbol.
"""
dimname(::AbstractArray,i) = Symbol("Dim_",i)
#Mandatory interface ends here

# Optional methods
"""
    iscontdim(x, i)

Returns a boolean indicating if the i-th dimension of the array
should be interpreted as a continouus range (true) or as categorical (false).
"""
function iscontdim(x, i)
  iscontdimval(dimvals(x,i))
end
iscontdimval(v) = (eltype(v) <: Union{Number,TimeType}) && (issorted(v) || issorted(v,rev=true))

"""
    iscompressed(x)

Returns a boolean indicating if the underlying data is compressed
and therefore random access is slow.
"""
iscompressed(x) = false

"""
    dimnames(x)

Returns a tuple of dimension names for al dimensions of x.
"""
dimnames(x) = ntuple(i->dimname(x,i), ndims(x))

"""
    getattributes(x)

If the data type supports storing additional attributes,
this returns a Dict with key-value pairs where the attribute names
(keys) are encoded as Strings.
"""
getattributes(x) = Dict{String,Any}()

"""
    getdata(x)

Returns a handle to the raw data of the array, which can be indexed
as a normal Julia Array. This might return the object itself, but ideally
if returns only the AbstractArray/DiskArray wrapped by the type.
"""
getdata(x) = x

"""
    valfromaxis(x)

If for a data type the dimension values are encoded in an object returned by `Base.axes(x)`
one can define a method for this function that returns the dimension values from that axis.
"""
valfromaxis(x) = x

"""
    yaxconvert(T::Type,x)

Converts an AbstractArray x that implements the interface to type T.
"""
function yaxconvert(T::Type{<:Any},x)
  yaxcreate(T, getdata(x), dimnames(x),dimvals.(Ref(x),1:ndims(x)),getattributes(x))
end

"""
    yaxcreate(T::Type,data,dnames,dvals,attributes)

Creates a new array with the given dimension names, values and attributes.
"""
function yaxcreate(T,data,dname,dvals,attributes) end
