# YAXArrayBase.jl

![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->
[![Build Status](https://travis-ci.com/JuliaDataCubes/YAXArrayBase.jl.svg?branch=master)](https://travis-ci.com/JuliaDataCubes/YAXArrayBase.jl)
[![codecov.io](http://codecov.io/github/JuliaDataCubes/YAXArrayBase.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaDataCubes/YAXArrayBase.jl?branch=master)

# YAXArrayBase

A package defining an interface to work with named dimension that might have values associated with them.

## Suported backends:

- DimensionalData
- AxisArrays
- AxisIndices
- YAXArrays
- NamedDims
- ArchGDAL raster types

# Usage

## Conversion between axis array types

````julia
using AxisArrays, DimensionalData, YAXArrayBase
a = AxisArray(rand(10,2), row = 11:20, col=["One","Two"])
````
````
2-dimensional AxisArray{Float64,2,...} with axes:
    :row, 11:20
    :col, ["One", "Two"]
And data, a 10×2 Array{Float64,2}:
 0.0467821  0.116614
 0.944797   0.827642
 0.593597   0.883222
 0.365977   0.368537
 0.486696   0.591154
 0.622487   0.572724
 0.805211   0.0480554
 0.570345   0.627014
 0.687585   0.936112
 0.149575   0.237352
 ````

 ````julia
 yaxconvert(DimensionalArray,a)
 ````
 ````
 DimensionalArray with dimensions:
 Dim row (type Dim): 11:20
 Dim col (type Dim): String[One, Two]
and data: 10×2 Array{Float64,2}
 0.0467821  0.116614
 0.944797   0.827642
 0.593597   0.883222
 0.365977   0.368537
 0.486696   0.591154
 0.622487   0.572724
 0.805211   0.0480554
 0.570345   0.627014
 0.687585   0.936112
 0.149575   0.237352
````

## The axis array interface

This is done through the axis array interface, the most important functions are `dimvals` and `dimnames`:

````julia
dimnames(a)
````
````
(:row, :col)
````

````julia
dimvals(a,1)
````
````
11:20
````

Look at `src/axisinterface` to get a full description of the interface.
