# JPL meeting, Nov 14-15 2018



## Wednesday

### Brent's presentation

- Layover flagging: baseline is to do nothing (currently on hold)
- Dark water flagging: still need to characterize
- phase unwrapping: current priority
- airswot data reveal errors we're not currently simulating, and need to.
- LiDAR scenes need to be analyzed, what classed of features need to be considered?
  - Validation sites? Catch several km away to capture layover topo



PIXC product tables

- Get this from Mike (or Brent)? I don't have it. 

### Xiaoqing's presentation (phase unwrapping)

- height ambiguity: $\lambda x / B$ --> ~8m height ambiguity in near range, 60 in far range
- aspects of phase unwrapping
  - Spatial unwrapping (PHASS, SNAPHU)
  - ambiguity inconsistency, split into regions
  - Absolute ambiguity resolution



### Mike's presentation (RiverObs)



Need an estimate of reach uncertainties to be able to flag whether or not to use a reach (currently just use percent non-missing nodes). 



### Brent again -- uncertainty

(See hand-written notes)



## Thursday

### Tamlin: ice flagging (lake and river)

 

### Phil: River product status

- Report mode, maximum number of channels (reach, node)

- 9-10 basins per continent



### Rui's talk

- 4 cases done, 5 to go
- I'll check layover bias against Curtis's model using Sac simulation



### Dusty's presentation

Running GDEM through RiverObs

Need some way to share analyses



### Benoit - layover using simulator



### Alex - RiverObs devel

Do prior db in netcdf



### Tamlin: Raster product

Need to add these fields:

- height error (from Brent's work)
- area error (from Brent's work)
- $\sigma_0$ uncertainty (Brent will check on how to do aggregate this)







