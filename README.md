# IEEE 754 Single-Precision Floating-Point Adder/Subtractor

A fully combinational SystemVerilog module that adds or subtracts two 32-bit IEEE 754 single-precision (binary32) floating-point numbers, with selectable rounding mode.

## Features

- Add or subtract via a single `op` input
- Handles normal numbers, subnormals, zeros, infinities, and NaNs
- Five IEEE 754 rounding modes, selectable at runtime
- Guard, round, and sticky bits for correct rounding
- Overflow handling that respects the rounding mode
- Purely combinational (no clock or reset)

## Interface

```systemverilog
module FP_Adder_Subtractor(
    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic        op,
    output logic [31:0] result,
    input  logic [2:0]  rounding_mode
);
```

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `A` | input | 32 | First operand (IEEE 754 binary32) |
| `B` | input | 32 | Second operand (IEEE 754 binary32) |
| `op` | input | 1 | `0` → `A + B`, `1` → `A - B` |
| `rounding_mode` | input | 3 | Rounding mode (see below) |
| `result` | output | 32 | Result (IEEE 754 binary32) |

### Rounding modes

| `rounding_mode` | Mode |
|-----------------|------|
| `3'b000` | Round to nearest, ties to even (default) |
| `3'b001` | Round toward zero (truncate) |
| `3'b010` | Round toward −∞ |
| `3'b011` | Round toward +∞ |
| `3'b100` | Round to nearest, ties away from zero |
| others | Treated as round to nearest, ties to even |

## How it works

1. **Unpack**: split each operand into sign, exponent, and fraction. The hidden bit is `1` for normal numbers and `0` for subnormals (subnormals use an effective exponent of 1). For subtraction, the sign of `B` is flipped.
2. **Special cases**: NaN, infinity, and zero + zero inputs are resolved up front.
3. **Swap**: the operand with the larger magnitude becomes the "large" operand.
4. **Align**: the smaller significand is right-shifted by the exponent difference. Shifted-out bits are collected into a sticky bit. Significands are extended with 3 extra bits (guard, round, sticky).
5. **Add/subtract**: the significands are added if the effective signs match, otherwise subtracted.
6. **Normalize**: a carry-out shifts right by one (exponent + 1). Cancellation shifts left until the leading one is restored, stopping at the minimum exponent so subnormal results are preserved.
7. **Round**: round-increment logic is chosen by `rounding_mode` using the guard, round, and sticky bits. A rounding carry bumps the exponent.
8. **Pack**: handle overflow (infinity or max finite value depending on mode), subnormal results, and assemble the final result.

## Special-case behavior

| Case | Result |
|------|--------|
| Either operand is NaN | Quiet NaN `32'h7FC00000` |
| `+∞ + −∞` (effective) | Quiet NaN `32'h7FC00000` |
| One infinity operand | Infinity with the appropriate sign |
| Exact cancellation (`x − x`) | `+0`, or `−0` in round-toward-−∞ mode |
| Overflow | ±∞, or ±max finite for modes that round toward zero in that direction |

## Usage

```systemverilog
logic [31:0] a, b, sum;

FP_Adder_Subtractor u_fp_add (
    .A             (a),
    .B             (b),
    .op            (1'b0),     // 0 = add, 1 = subtract
    .rounding_mode (3'b000),   // round to nearest even
    .result        (sum)
);
```

### Simple testbench example

```systemverilog
`timescale 1ns / 1ps

module tb_FP_Adder_Subtractor;
    logic [31:0] A, B, result;
    logic        op;
    logic [2:0]  rounding_mode;

    FP_Adder_Subtractor dut (.*);

    initial begin
        rounding_mode = 3'b000;

        // 1.5 + 2.25 = 3.75
        A = 32'h3FC00000; B = 32'h40100000; op = 0; #10;
        $display("1.5 + 2.25 = %h (expect 40700000)", result);

        // 5.0 - 2.0 = 3.0
        A = 32'h40A00000; B = 32'h40000000; op = 1; #10;
        $display("5.0 - 2.0 = %h (expect 40400000)", result);

        $finish;
    end
endmodule
```

## Known limitations

- **No exception flags**: overflow, underflow, inexact, and invalid are not reported.
- **NaN payloads are not propagated**: any NaN result is the canonical quiet NaN `0x7FC00000`.
- **Signed zero edge case**: when both inputs are zero, the result is `+0` unless the mode is round-toward-−∞. IEEE 754 requires `(−0) + (−0) = −0` in all modes, so that case does not currently match.
- **Verification**: this repository contains the RTL only. Test thoroughly (for example against a software reference or a tool like Berkeley TestFloat) before relying on it.

## Tools

Written in SystemVerilog (uses `logic` and `always_comb`). It should work with Vivado, Questa/ModelSim, VCS, Verilator, and other tools with SystemVerilog support.

## Files

| File | Description |
|------|-------------|
| `FP_Adder_Subtractor.sv` | The adder/subtractor module |


