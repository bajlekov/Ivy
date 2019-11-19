set(LLVM_LINK_COMPONENTS
  Core
  IRReader
  OrcJIT
  Support
  nativecodegen
  )

if( NOT LLVM_BUILD_EXAMPLES )
  set(EXCLUDE_FROM_ALL ON)
endif()
llvm_add_library(ivyJIT SHARED ivyJIT.cpp)
if( LLVM_BUILD_EXAMPLES )
  install(TARGETS ivyJIT RUNTIME DESTINATION examples)
endif()
set_target_properties(ivyJIT PROPERTIES FOLDER "Examples")