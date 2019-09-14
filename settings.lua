do local _={
  cubicSpline=false,
  halideEnable=false,
  halideGpuEnable=false,
  hostLowMemory=true,
  imageLoader="native",
  imagePath="img.jpg",
  juliaEnable=false,
  linkCache=true,
  linkDebug=false,
  nativeCoreCount=8,
  nativeProfile=false,
  nodeAutoConnect=true,
  openclBuildParams="-cl-std=CL1.2 -Iops/ocl ",
  openclDebug=false,
  openclCache=false,
  openclDevice=1,
  openclLowMemory=false,
  openclPlatform=3,
  openclProfile=false,
  openclWorkgroupSize={
    16,
    16,
    1
  },
  scaleUI=1
}
return _
end