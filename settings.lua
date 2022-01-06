do local _={
  halideEnable=false,
  halideGpuEnable=false,
  hostLowMemory=true,
  imageLoader="native",
  imagePath="img.jpg",
  juliaEnable=false,
  linkCache=true,
  linkDebug=false,
  nativeProfile=false,
  nodeAutoConnect=true,
  openclBuildParams="-cl-std=CL1.2 -Iops/include ",
  openclCache=false,
  openclDebug=false,
  openclDevice=1,
  openclLowMemory=false,
  openclPlatform=1,
  openclProfile=false,
  openclWorkgroupSize={
    16,
    16,
    1
  },
  scaleUI=1,
  scaleUIpreference="auto",
  schedulerProfile=false,
  splineType="bezier"
}
return _
end