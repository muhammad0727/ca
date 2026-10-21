# Lab 6 – ALU for a Single-Cycle RISC-V Processor (RV32I)

Operations: **ADD, SUB, SLL, SRL, AND, OR, XOR, BEQ**. Board: **Basys 3** (100 MHz).

| File | Task | What it is |
|---|---|---|
| `diagrams/ALU_1bit.svg/.png` | 1(a) | 1-bit ALU slice |
| `diagrams/ALU_32bit.svg/.png` | 1(b), 1(c) | 32-bit ALU, word-level data flow (matches `ALU.v`) |
| `ALU.v` | 2 | the ALU |
| `ALU_tb.v` | 2 | self-checking ALU testbench (71 checks, 720 ns) |
| `top_alu_system.v` | 3 | FPGA top: FSM + ALU + Lab 5 interfaces |
| `tb_top_alu_system.v` | 3 | self-checking testbench for the top (43 checks, ~5.1 µs) |
| `switches.v`, `leds.v`, `debouncer.v`, `constraints.xdc` | 3 | copied **unchanged** from Lab 5 |

## ALUControl encoding

Patterson & Hennessy codes for AND/OR/ADD/SUB, the other RV32I operations on unused codes.
Lab 9's ALU-control unit must produce these same codes.

| ALUControl | Op | ALUResult |
|---|---|---|
| `0000` | AND | `A & B` |
| `0001` | OR  | `A \| B` |
| `0010` | ADD | `A + B` |
| `0011` | XOR | `A ^ B` |
| `0100` | SLL | `A << B[4:0]` |
| `0101` | SRL | `A >> B[4:0]` (zero-fill) |
| `0110` | SUB | `A - B` |
| others | –   | `0` |

`Zero = (ALUResult == 0)`. **BEQ** has no code of its own: the processor uses SUB and branches when
`Zero = 1`, because `A - B = 0` exactly when `A == B`.

## How the ALU works (`ALU.v`)

* **One adder for ADD and SUB.** `A - B = A + ~B + 1`. The `sub` signal makes the B-mux pass `~B`
  and also enters as the carry-in (the `+1`). Carry-out is dropped, so results wrap mod 2³².
* **Logic unit:** `A & B`, `A | B`, `A ^ B`, which use the original B, not the inverted one.
* **Shifter:** shift amount is `B[4:0]` (0–31), as in RV32I. `>>` is logical, so zeros come in
  from the left (SRL, not SRA).
* **Result mux:** a `case` on ALUControl with a `default` branch, which keeps the logic purely
  combinational (no latch).
* **Zero detector:** a 32-input NOR of the result.

The 1-bit diagram is one slice of the same hardware: the adder of `ALU.v` is 32 of those full
adders chained through the carry, bit 0's CarryIn being `SUB`. Shifts move bits *between* slices,
so a slice can't compute them on its own; they come from the shared barrel shifter.

## FPGA top (`top_alu_system.v`)

The ports are the same as the Lab 5 top (`clk`, `pbin`, `physical_sw`, `physical_leds`), so
`constraints.xdc` is reused unchanged. Operands are `OPERAND_A = 0x10101010` and
`OPERAND_B = 0x01010101` (parameters, defaults from the manual).

**FSM** (one loop every 3 clocks = 30 ns, so the LEDs follow the switches instantly):

```
 reset ──► S_IDLE ──► S_READ ──► S_EXEC ──► S_WRITE ─┐
                        ▲                            │
                        └────────────────────────────┘
 S_READ : readEnable  → switch interface, snapshot switches into sw_reg
 S_EXEC : run the ALU, capture ALUResult, Zero, ALUControl
 S_WRITE: writeEnable → LED interface, write the selected view
```

The Lab 5 interfaces are named after the opposite device: module **`leds`** *reads the switches*
(it has `input switches`, `output readData`), and module **`switches`** *drives the LEDs* (it
has `input writeData`, `output leds`). They are used exactly as given.

### Switch map

| Switch | Function |
|---|---|
| `sw[3:0]` | ALUControl (manual mode) |
| `sw[12]` | `0`: B = 0x01010101 · `1`: B = A (makes BEQ **taken**) |
| `sw[14:13]` | LED view: `00` ALUResult[15:0] · `01` ALUResult[31:16] · `1x` status |
| `sw[15]` | `0` manual · `1` auto: steps ADD→SUB→SLL→SRL→AND→OR→XOR→BEQ, 2 s each |
| centre button | reset |

**Status view:** `LED15 = Zero`, `LED[6:4]` = auto step (0 ADD … 7 BEQ, 0 in manual mode),
`LED[3:0]` = ALUControl executed. Auto mode always starts again at ADD.

### Expected LEDs for the RA demo (manual mode, `sw[12]=0`)

| Op | `sw[3:0]` | ALUResult | view 00 / 01 (LEDs on) | status view |
|---|---|---|---|---|
| ADD | 0010 | `0x11111111` | `0x1111` → LED 12, 8, 4, 0 | `0x0002` |
| SUB | 0110 | `0x0F0F0F0F` | `0x0F0F` → LED 11–8, 3–0 | `0x0006` |
| SLL | 0100 | `0x20202020` | `0x2020` → LED 13, 5 | `0x0004` |
| SRL | 0101 | `0x08080808` | `0x0808` → LED 11, 3 | `0x0005` |
| AND | 0000 | `0x00000000` | all off | `0x8000` → LED15 (Zero) |
| OR  | 0001 | `0x11111111` | `0x1111` | `0x0001` |
| XOR | 0011 | `0x11111111` | `0x1111` | `0x0003` |
| BEQ, A≠B | 0110 | `0x0F0F0F0F` | `0x0F0F` | `0x0006` → LED15 off: **not taken** |
| BEQ, `sw[12]=1` (A=A) | 0110 | `0x00000000` | all off | `0x8006` → LED15 on: **taken** |

With these operands both 16-bit halves are the same and ADD/OR/XOR give the same value. That is
why the status view shows ALUControl, and why the testbenches use extra operands.

## Running it in Vivado

1. New RTL project, part **xc7a35tcpg236-1** (Basys 3).
2. Design sources: `ALU.v`, `top_alu_system.v`, `switches.v`, `leds.v`, `debouncer.v`.
   Constraints: `constraints.xdc`. Simulation sources: `ALU_tb.v`, `tb_top_alu_system.v`.
3. **ALU simulation:** right-click `ALU_tb` → *Set as Top* → Run Behavioral Simulation.
   It finishes inside the default 1000 ns. The Tcl console should end with `ALL TESTS PASSED`.
   In the waveform, right-click `op_name` → Radix → ASCII to see the operation names.
4. **Top simulation:** set `tb_top_alu_system` as top. It runs ~5.1 µs, so press **Run All**.
   The testbench overrides `STEP_CYCLES` to 20 clocks so auto mode steps quickly.
5. **RTL schematic:** *RTL Analysis → Open Elaborated Design → Schematic*. Screenshot this view. The
   *synthesized* schematic is almost empty because A and B are constants: Vivado pre-computes
   every result, so only a small mux of constants is left.
6. Generate bitstream, program the board, and walk through the demo table above.

Checked with Icarus Verilog 12 (`-g2001 -Wall`, no warnings), not with Vivado xsim. Both
testbenches pass, and mutation testing (deliberately broken copies of the design) showed they catch
8/8 ALU bugs and 9/9 top-level bugs.

**Note:** the Lab 5 `debouncer` is a pass-through (`pbout = pbin`). That is harmless here because
the button is only used as reset, and nothing depends on counting presses.
