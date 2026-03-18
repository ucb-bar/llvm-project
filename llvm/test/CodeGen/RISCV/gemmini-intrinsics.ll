; RUN: llc -mtriple=riscv64 -verify-machineinstrs < %s | FileCheck %s

define void @gemmini_all() {
entry:
  call void @llvm.riscv.flush(i64 1, i64 0)
  call void @llvm.riscv.config(i64 2, i64 3)
  call void @llvm.riscv.mvin(i64 4, i64 5)
  call void @llvm.riscv.mvin2(i64 6, i64 7)
  call void @llvm.riscv.mvin3(i64 8, i64 9)
  call void @llvm.riscv.mvout(i64 10, i64 11)
  call void @llvm.riscv.preload(i64 12, i64 13)
  call void @llvm.riscv.compute.preloaded(i64 14, i64 15)
  call void @llvm.riscv.compute.accumulated(i64 16, i64 17)
  call void @llvm.riscv.loop.ws.config.bounds(i64 18, i64 19)
  call void @llvm.riscv.loop.ws.config.addrs.ab(i64 20, i64 21)
  call void @llvm.riscv.loop.ws.config.addrs.dc(i64 22, i64 23)
  call void @llvm.riscv.loop.ws.config.strides.ab(i64 24, i64 25)
  call void @llvm.riscv.loop.ws.config.strides.dc(i64 26, i64 27)
  call void @llvm.riscv.loop.ws(i64 28, i64 29)
  call void @llvm.riscv.loop.conv.ws.config1(i64 30, i64 31)
  call void @llvm.riscv.loop.conv.ws.config2(i64 32, i64 33)
  call void @llvm.riscv.loop.conv.ws.config3(i64 34, i64 35)
  call void @llvm.riscv.loop.conv.ws.config4(i64 36, i64 37)
  call void @llvm.riscv.loop.conv.ws.config5(i64 38, i64 39)
  call void @llvm.riscv.loop.conv.ws.config6(i64 40, i64 41)
  call void @llvm.riscv.loop.conv.ws(i64 42, i64 43)
  ret void
}

; CHECK-LABEL: gemmini_all:
; CHECK: gemmini.flush
; CHECK: gemmini.config
; CHECK: gemmini.mvin
; CHECK: gemmini.mvin2
; CHECK: gemmini.mvin3
; CHECK: gemmini.mvout
; CHECK: gemmini.preload
; CHECK: gemmini.compute.preloaded
; CHECK: gemmini.compute.accumulated
; CHECK: gemmini.loop_ws.config.bounds
; CHECK: gemmini.loop_ws.config.addrs.ab
; CHECK: gemmini.loop_ws.config.addrs.dc
; CHECK: gemmini.loop_ws.config.strides.ab
; CHECK: gemmini.loop_ws.config.strides.dc
; CHECK: gemmini.loop_ws
; CHECK: gemmini.loop_conv_ws.config1
; CHECK: gemmini.loop_conv_ws.config2
; CHECK: gemmini.loop_conv_ws.config3
; CHECK: gemmini.loop_conv_ws.config4
; CHECK: gemmini.loop_conv_ws.config5
; CHECK: gemmini.loop_conv_ws.config6
; CHECK: gemmini.loop_conv_ws
; CHECK: ret

declare void @llvm.riscv.flush(i64, i64)
declare void @llvm.riscv.config(i64, i64)
declare void @llvm.riscv.mvin(i64, i64)
declare void @llvm.riscv.mvin2(i64, i64)
declare void @llvm.riscv.mvin3(i64, i64)
declare void @llvm.riscv.mvout(i64, i64)
declare void @llvm.riscv.preload(i64, i64)
declare void @llvm.riscv.compute.preloaded(i64, i64)
declare void @llvm.riscv.compute.accumulated(i64, i64)
declare void @llvm.riscv.loop.ws.config.bounds(i64, i64)
declare void @llvm.riscv.loop.ws.config.addrs.ab(i64, i64)
declare void @llvm.riscv.loop.ws.config.addrs.dc(i64, i64)
declare void @llvm.riscv.loop.ws.config.strides.ab(i64, i64)
declare void @llvm.riscv.loop.ws.config.strides.dc(i64, i64)
declare void @llvm.riscv.loop.ws(i64, i64)
declare void @llvm.riscv.loop.conv.ws.config1(i64, i64)
declare void @llvm.riscv.loop.conv.ws.config2(i64, i64)
declare void @llvm.riscv.loop.conv.ws.config3(i64, i64)
declare void @llvm.riscv.loop.conv.ws.config4(i64, i64)
declare void @llvm.riscv.loop.conv.ws.config5(i64, i64)
declare void @llvm.riscv.loop.conv.ws.config6(i64, i64)
declare void @llvm.riscv.loop.conv.ws(i64, i64)
