#include "llvm/ExecutionEngine/Orc/LLJIT.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Support/SourceMgr.h"

#include <iostream>

using namespace llvm;
using namespace llvm::orc;
using namespace llvm::sys;
using namespace std;

ExitOnError ExitOnErr;

extern "C" void ivyjit_init() {
  InitializeNativeTarget();
  InitializeNativeTargetAsmPrinter();
}

extern "C" void* ivyjit_new() {
  auto JTMB = JITTargetMachineBuilder(Triple("x86_64-pc-windows-gnu"));
  JTMB.setCPU(getHostCPUName());
  auto DL = ExitOnErr(JTMB.getDefaultDataLayoutForTarget());

  auto J = ExitOnErr(LLJIT::Create(move(JTMB), DL));
  J->getMainJITDylib().setGenerator(
    ExitOnErr(
      //DynamicLibrarySearchGenerator::Load("tasksys.dll", DL)
      DynamicLibrarySearchGenerator::GetForCurrentProcess(DL)
    )
  );
  return J.release();
}

extern "C" void ivyjit_module(void *J, const char *file) {
  ThreadSafeContext context(llvm::make_unique<LLVMContext>());
    SMDiagnostic err;
    auto module = ThreadSafeModule(
      parseIRFile(file, err, *context.getContext()),
      context
    );
    if (!module) {
      err.print(file, errs());
      exit(1);
    }
  ExitOnErr(((LLJIT*)J)->addIRModule(move(module)));
}

extern "C" void* ivyjit_lookup(void *J, const char *symbol) {
  auto s = ExitOnErr(((LLJIT*)J)->lookup(symbol));
  return (void*)s.getAddress();
}

extern "C" void ivyjit_free(void *J) {
  free ((LLJIT*)J);
}
