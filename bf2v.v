import os

const (
	ops = '<>+-.,[]'
)

enum Op {
	left_shift
	right_shift
	increment
	decrement
	output
	input
	left_jump
	right_jump
	nop
}

struct Config {
	tape_size int=8
}

struct Instruction {
	op     Op
mut:
	amount int
}

fn generate_op_map() map[string]Op {
	mut op_map := map[string]Op
	for n, op in ops {
		op_map[op.str()] = Op(n)
	}
	return op_map
}

fn parse(code string) []Instruction {
	mut ins := []Instruction
	op_map := generate_op_map()
	for chr in code {
		ins << Instruction{
			op_map[chr.str()],1}
	}
	ins << Instruction{
		Op.nop,0}
	return ins
}

fn isnop(last, ins Instruction) bool {
	if ins.op in [Op.left_shift, .right_shift] && last.op in [Op.left_shift, .right_shift] && last.op != ins.op {
		return true
	}
	else if ins.op in [Op.increment, .decrement] && last.op in [Op.increment, .decrement] && last.op != ins.op {
		return true
	}
	else if last.op == .left_jump && ins.op == .right_jump {
		return true
	}
	return false
}

fn convert(ins []Instruction, cfg &Config) string {
	mut code := ''
	mut last := Instruction{
		Op.nop,0}
	for instruction in ins {
		if instruction.op == last.op {
			last.amount++
		}
		else if isnop(last, instruction) {
			last = Instruction{
				Op.nop,0}
		}
		else {
			match last.op {
				.left_shift {
					if last.amount == 1 {
						code += 'ptr--\n\t'
					}
					else {
						code += 'ptr -= ${last.amount}\n\t'
					}
				}
				.right_shift {
					if last.amount == 1 {
						code += 'ptr++\n\t'
					}
					else {
						code += 'ptr += ${last.amount}\n\t'
					}
				}
				.increment {
					if last.amount == 1 {
						code += 'cells[ptr]++\n\t'
					}
					else {
						code += 'cells[ptr] += ${last.amount}\n\t'
					}
				}
				.decrement {
					if last.amount == 1 {
						code += 'cells[ptr]--\n\t'
					}
					else {
						code += 'cells[ptr] -= ${last.amount}\n\t'
					}
				}
				.output {
					for last.amount > 0 {
						code += 'print(cells[ptr].str())\n\t'
						last.amount--
					}
				}
				.input {
					for last.amount > 0 {
						code += 'cells[ptr] = byte(rl.read_char())\n\t'
						last.amount--
					}
				}
				.left_jump {
					for last.amount > 0 {
						code += 'for cells[ptr] != 0 {\n\t'
						last.amount--
					}
				}
				.right_jump {
					for last.amount > 0 {
						code += '}\n\t'
						last.amount--
					}
				}
				else {}
	}
			last = instruction
		}
	}
	code += 'println("")'
	return code
}

fn translate(code string) string {
	boilerplate := os.read_file('./boilerplate') or {
		panic('!')
	}
	ins := parse(code)
	mut rl := '// '
	for instruction in ins {
		if instruction.op == .input {
			rl = ''
		}
	}
	return boilerplate.replace_each(['%code', convert(ins, Config{}), '%rl', rl])
}

fn main() {
	if os.args.len != 3 {
		println('USAGE: ${os.args[0]} input_file output_file')
		exit(1)
	}
	source := os.read_file(os.args[1]) or {
		println('cannot read input_file')
		exit(1)
	}
	os.write_file(os.args[2], translate(source))
}
