using YAXArrayBase, NetCDF, Zarr, Test

@testset "Reading NetCDF" begin
import Downloads
p = Downloads.download("https://www.unidata.ucar.edu/software/netcdf/examples/sresa1b_ncar_ccsm3-example.nc")

p2 = mv(p,string(tempname(),".nc"))

ds_nc = YAXArrayBase.to_dataset(p2)
vn = get_varnames(ds_nc)
@test sort(vn) == ["area", "lat", "lat_bnds", "lon", "lon_bnds", "msk_rgn",
 "plev", "pr", "tas", "time", "time_bnds", "ua"]
@test get_var_dims(ds_nc, "tas") == ["lon", "lat", "time"]
@test get_var_dims(ds_nc, "area") == ["lon", "lat"]
@test get_var_dims(ds_nc, "time") == ["time"]
@test get_var_dims(ds_nc, "time_bnds") == ["bnds", "time"]
@test get_var_attrs(ds_nc,"tas")["long_name"] == "air_temperature"
h = get_var_handle(ds_nc, "tas")
@test !YAXArrayBase.iscompressed(h)
@test all(isapprox.(h[1:2,1:2], [215.893 217.168; 215.805 217.03]))
@test allow_parallel_write(ds_nc) == false
@test allow_missings(ds_nc) == false
end

@testset "Reading Zarr" begin
p = "gs://cmip6/CMIP6/HighResMIP/CMCC/CMCC-CM2-HR4/highresSST-present/r1i1p1f1/6hrPlev/psl/gn/v20170706/"
ds_zarr = to_dataset(p,driver=:zarr)
vn = get_varnames(ds_zarr)
@test sort(vn) == ["lat", "lat_bnds", "lon", "lon_bnds", "psl", "time", "time_bnds"]
@test get_var_dims(ds_zarr, "psl") == ["lon", "lat", "time"]
@test get_var_dims(ds_zarr, "time") == ["time"]
@test get_var_dims(ds_zarr, "time_bnds") == ["bnds", "time"]
@test get_var_attrs(ds_zarr,"psl")["long_name"] == "Sea Level Pressure"
h = get_var_handle(ds_zarr, "psl")
@test YAXArrayBase.iscompressed(h)
@test all(isapprox.(h[1:2,1:2,1], [99360.8  99334.9; 99360.8  99335.4]))
@test allow_parallel_write(ds_zarr) == true
@test allow_missings(ds_zarr) == true
end

function test_write(T)
    p = tempname()
    ds = create_empty(T, p)
add_var(ds, 0.5:1:9.5, "lon", ("lon",), Dict("units"=>"degrees_east"))
add_var(ds, 20:-1.0:1, "lat", ("lat",), Dict("units"=>"degrees_north"))
v = add_var(ds, Float32, "tas", (10,20), ("lon", "lat"), Dict{String,Any}("units"=>"Celsius"))

v[:,:] = collect(reshape(1:200, 10, 20))

@test sort(get_varnames(ds)) == ["lat","lon","tas"]
@test get_var_dims(ds, "tas") == ["lon", "lat"]
@test get_var_dims(ds, "lon") == ["lon"]
@test get_var_attrs(ds,"tas")["units"] == "Celsius"
h = get_var_handle(ds, "lon")
@test h[:] == 0.5:1:9.5
v = get_var_handle(ds, "tas")
@test v[1:2,1:2] == [1 11; 2 12]
end

@testset "Writing NetCDF" begin
  test_write(YAXArrayBase.NetCDFDataset)
end

@testset "Writing Zarr" begin
  test_write(YAXArrayBase.ZarrDataset)
end
