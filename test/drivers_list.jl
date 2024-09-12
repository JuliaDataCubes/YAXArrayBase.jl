using YAXArrayBase
# test drivers loading
YAXArrayBase.backendlist
# start loading drivers
using NetCDF
using Zarr
# the fix!
using ArchGDAL
AG=ArchGDAL
import Downloads
p = Downloads.download("https://download.osgeo.org/geotiff/samples/gdal_eg/cea.tif")
r = AG.readraster(p)

ds_zarr = to_dataset(p, driver=:gdal)
get_varnames(ds_zarr)
get_var_dims(ds_zarr, "Gray")
get_var_attrs(ds_zarr, "Gray")
get_var_handle(ds_zarr, "Gray")

