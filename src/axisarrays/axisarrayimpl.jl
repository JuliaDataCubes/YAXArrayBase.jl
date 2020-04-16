@require ESDL="359177bc-a543-11e8-11b7-bb015dba3358" begin
using .ESDL.Cubes: ESDLArray
# Implementation for ESDLArray
dimvals(x::ESDLArray, i) = x.axes[i].values

function dimname(x::ESDLArray, i)
  axsym(x.axes[i])
end

getattributes(x::ESDLArray) = x.properties

iscontdim(x::ESDLArray, i) = isa(x.axes[i], RangeAxis)

getdata(x::ESDLArray) = x.data
end

@require DimensionalData="0703355e-b756-11e9-17c0-8b28908087d0" begin
using .DimensionalData: DimensionalArray, DimensionalData

dimname(x::DimensionalArray, i) = nameof(typeof(DimensionalData.dims(x)[i]))

dimvals(x::DimensionalArray,i) = DimensionalData.dims(x)[i].val
end

@require AxisArrays="39de3d68-74b9-583c-8d2d-e117c070f3a9" begin
using .AxisArrays: AxisArrays, AxisArray

dimname(a::AxisArray, i) = AxisArrays.axisnames(a)[i]
dimnames(a::AxisArray) = AxisArrays.axisnames(a)
dimvals(a::AxisArray, i) = AxisArrays.axisvalues(a)[i]
iscontdim(a::AxisArray, i) = AxisArrays.axistrait(AxisArrays.axes(a,i)) <: AxisArrays.Dimensional
end

@require AxisIndices="f52c9ee2-1b1c-4fd8-8546-6350938c7f11" begin
using .AxisIndices: AbstractAxis, AxisIndicesArray

valfromaxis(ax::AbstractAxis) = keys(ax)

getdata(a::AxisIndicesArray) = parent(a)
end
