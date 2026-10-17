from __future__ import annotations

import ast
import math
import operator
from dataclasses import dataclass
from typing import Any

MAX_SOURCE_BYTES = 8_192
MAX_AST_NODES = 300
MAX_AST_DEPTH = 18
MAX_ARGUMENTS = 8
MAX_COLLECTION_ITEMS = 500
MAX_STRING_LENGTH = 2_048
MAX_TOTAL_ITERATIONS = 1_000
MAX_STEPS = 10_000


@dataclass(frozen=True)
class _Failure:
    code: str
    message: str


class _PracticeFailure(Exception):
    def __init__(self, code: str, message: str) -> None:
        super().__init__(message)
        self.code = code
        self.message = message


class _Return(Exception):
    def __init__(self, value: Any) -> None:
        self.value = value


class _Budget:
    def __init__(self) -> None:
        self.steps = 0
        self.iterations = 0

    def step(self) -> None:
        self.steps += 1
        if self.steps > MAX_STEPS:
            raise _PracticeFailure("iteration_limit", "The practice step limit was reached.")

    def iteration(self) -> None:
        self.iterations += 1
        if self.iterations > MAX_TOTAL_ITERATIONS:
            raise _PracticeFailure("iteration_limit", "The practice loop limit was reached.")


_ALLOWED_NODES = {
    ast.Module, ast.FunctionDef, ast.arguments, ast.arg, ast.Return, ast.If, ast.For,
    ast.Assign, ast.AugAssign, ast.Raise, ast.Pass, ast.Name, ast.Load, ast.Store,
    ast.Constant, ast.List, ast.Tuple, ast.Dict, ast.UnaryOp, ast.Not, ast.UAdd,
    ast.USub, ast.BinOp, ast.Add, ast.Sub, ast.Mult, ast.Div, ast.FloorDiv, ast.Mod,
    ast.Compare, ast.Eq, ast.NotEq, ast.Lt, ast.LtE, ast.Gt, ast.GtE, ast.In,
    ast.NotIn, ast.BoolOp, ast.And, ast.Or, ast.Subscript, ast.Slice, ast.Call,
}

_BINARY_OPERATORS = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.Div: operator.truediv,
    ast.FloorDiv: operator.floordiv,
    ast.Mod: operator.mod,
}
_COMPARE_OPERATORS = {
    ast.Eq: operator.eq,
    ast.NotEq: operator.ne,
    ast.Lt: operator.lt,
    ast.LtE: operator.le,
    ast.Gt: operator.gt,
    ast.GtE: operator.ge,
    ast.In: lambda left, right: left in right,
    ast.NotIn: lambda left, right: left not in right,
}
_AUGMENTED_OPERATORS = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.Div: operator.truediv,
    ast.FloorDiv: operator.floordiv,
    ast.Mod: operator.mod,
}
_SAFE_BUILTINS = {"len", "range", "sum", "min", "max", "abs"}


def _validate_external_value(value: Any, depth: int = 0) -> None:
    if depth > 8:
        raise _PracticeFailure("invalid_arguments", "Input data is nested too deeply.")
    if value is None or isinstance(value, bool):
        return
    if isinstance(value, int):
        if value.bit_length() > 256:
            raise _PracticeFailure("invalid_arguments", "Input integer is too large.")
        return
    if isinstance(value, float):
        if not math.isfinite(value) or abs(value) > 1e100:
            raise _PracticeFailure("invalid_arguments", "Input number is outside the supported range.")
        return
    if isinstance(value, str):
        try:
            value.encode("utf-8")
        except UnicodeEncodeError:
            raise _PracticeFailure("invalid_arguments", "Input text must contain valid Unicode.") from None
        if len(value) > MAX_STRING_LENGTH:
            raise _PracticeFailure("invalid_arguments", "Input text is too long.")
        return
    if isinstance(value, list):
        if len(value) > MAX_COLLECTION_ITEMS:
            raise _PracticeFailure("invalid_arguments", "Input list has too many items.")
        for item in value:
            _validate_external_value(item, depth + 1)
        return
    if isinstance(value, tuple):
        if len(value) > MAX_COLLECTION_ITEMS:
            raise _PracticeFailure("invalid_arguments", "Input tuple has too many items.")
        for item in value:
            _validate_external_value(item, depth + 1)
        return
    if isinstance(value, dict):
        if len(value) > MAX_COLLECTION_ITEMS:
            raise _PracticeFailure("invalid_arguments", "Input object has too many fields.")
        for key, item in value.items():
            if not isinstance(key, str) or len(key) > 128:
                raise _PracticeFailure("invalid_arguments", "Input object keys must be short text.")
            _validate_external_value(item, depth + 1)
        return
    raise _PracticeFailure("invalid_arguments", "Input data must use JSON values only.")


def _check_runtime_value(value: Any) -> Any:
    try:
        _validate_external_value(value)
    except _PracticeFailure as failure:
        if failure.code == "invalid_arguments":
            raise _PracticeFailure("invalid_result", "The result is outside the supported value range.") from None
        raise
    return value


def _validate_program(source: str) -> ast.FunctionDef:
    if not isinstance(source, str) or not source.strip():
        raise _PracticeFailure("syntax_error", "Write one function named solve(values, ...).")
    try:
        source_size = len(source.encode("utf-8"))
    except UnicodeEncodeError:
        raise _PracticeFailure("syntax_error", "Python code must contain valid Unicode text.") from None
    if source_size > MAX_SOURCE_BYTES:
        raise _PracticeFailure("code_too_large", "The code is longer than the practice limit.")
    try:
        tree = ast.parse(source, mode="exec")
    except (SyntaxError, ValueError, MemoryError):
        raise _PracticeFailure("syntax_error", "Check the Python syntax and indentation.") from None

    nodes = list(ast.walk(tree))
    if len(nodes) > MAX_AST_NODES:
        raise _PracticeFailure("code_too_large", "The code has too many syntax elements.")
    pending = [(tree, 0)]
    while pending:
        node, depth = pending.pop()
        if depth > MAX_AST_DEPTH or type(node) not in _ALLOWED_NODES:
            raise _PracticeFailure(
                "unsupported_syntax",
                "This trainer supports a small Python subset: variables, lists, math, if, for, and return.",
            )
        pending.extend((child, depth + 1) for child in ast.iter_child_nodes(node))

    if len(tree.body) != 1 or not isinstance(tree.body[0], ast.FunctionDef):
        raise _PracticeFailure("unsupported_syntax", "Define exactly one function named solve.")
    function = tree.body[0]
    if any(isinstance(node, ast.FunctionDef) and node is not function for node in nodes):
        raise _PracticeFailure("unsupported_syntax", "Nested functions are not supported.")
    if (
        function.name != "solve"
        or function.decorator_list
        or function.returns is not None
        or function.type_comment is not None
        or function.args.vararg is not None
        or function.args.kwarg is not None
        or function.args.kwonlyargs
        or function.args.posonlyargs
        or function.args.defaults
        or function.args.kw_defaults
        or not 1 <= len(function.args.args) <= MAX_ARGUMENTS
        or not function.body
    ):
        raise _PracticeFailure("unsupported_syntax", "Use one plain solve function with required positional parameters.")
    names = [argument.arg for argument in function.args.args]
    if len(set(names)) != len(names) or any(not name.isidentifier() or name.startswith("__") for name in names):
        raise _PracticeFailure("unsupported_syntax", "Function parameters must be unique simple names.")

    parent_by_child = {
        child: parent
        for parent in nodes
        for child in ast.iter_child_nodes(parent)
    }
    for node in nodes:
        if isinstance(node, (ast.FunctionDef, ast.If, ast.For)) and getattr(node, "orelse", None):
            if isinstance(node, ast.FunctionDef) or isinstance(node, ast.For):
                raise _PracticeFailure("unsupported_syntax", "Function and loop else clauses are not supported.")
        if isinstance(node, ast.FunctionDef) and len(node.args.args) != len(names):
            raise _PracticeFailure("unsupported_syntax", "Nested functions are not supported.")
        if isinstance(node, (ast.Assign, ast.AugAssign)):
            targets = node.targets if isinstance(node, ast.Assign) else [node.target]
            if len(targets) != 1 or not isinstance(targets[0], ast.Name):
                raise _PracticeFailure("unsupported_syntax", "Assign values to one variable at a time.")
        if isinstance(node, ast.For) and not isinstance(node.target, ast.Name):
            raise _PracticeFailure("unsupported_syntax", "Loop variables must be simple names.")
        if isinstance(node, ast.Call):
            is_raise_value_error = (
                isinstance(node.func, ast.Name)
                and node.func.id == "ValueError"
                and isinstance(parent_by_child.get(node), ast.Raise)
            )
            if not is_raise_value_error and (
                not isinstance(node.func, ast.Name) or node.func.id not in _SAFE_BUILTINS
            ):
                raise _PracticeFailure("unsupported_syntax", "Only len, range, sum, min, max, and abs may be called.")
            if node.keywords:
                raise _PracticeFailure("unsupported_syntax", "Keyword arguments are not supported in this trainer.")
        if isinstance(node, ast.Raise):
            call = node.exc
            if (
                not isinstance(call, ast.Call)
                or not isinstance(call.func, ast.Name)
                or call.func.id != "ValueError"
                or len(call.args) != 1
                or call.keywords
                or not isinstance(call.args[0], ast.Constant)
                or not isinstance(call.args[0].value, str)
            ):
                raise _PracticeFailure("unsupported_syntax", "Only raise ValueError('message') is supported.")
        if isinstance(node, ast.AugAssign) and type(node.op) not in _AUGMENTED_OPERATORS:
            raise _PracticeFailure("unsupported_syntax", "This arithmetic operation is not supported.")
    return function


class _Interpreter:
    def __init__(self, env: dict[str, Any]) -> None:
        self.env = env
        self.budget = _Budget()

    def evaluate(self, node: ast.expr) -> Any:
        self.budget.step()
        if isinstance(node, ast.Constant):
            value = node.value
            if not (value is None or isinstance(value, (bool, int, float, str))):
                raise _PracticeFailure("unsupported_syntax", "This literal type is not supported.")
            return _check_runtime_value(value)
        if isinstance(node, ast.Name):
            if node.id not in self.env:
                raise _PracticeFailure("NameError", f"Name '{node.id}' is not defined.")
            return self.env[node.id]
        if isinstance(node, ast.List):
            return _check_runtime_value([self.evaluate(item) for item in node.elts])
        if isinstance(node, ast.Tuple):
            return _check_runtime_value(tuple(self.evaluate(item) for item in node.elts))
        if isinstance(node, ast.Dict):
            result = {}
            for key_node, value_node in zip(node.keys, node.values, strict=True):
                key = self.evaluate(key_node)
                if not isinstance(key, str):
                    raise _PracticeFailure("TypeError", "Dictionary keys must be text in this trainer.")
                result[key] = self.evaluate(value_node)
            return _check_runtime_value(result)
        if isinstance(node, ast.UnaryOp):
            value = self.evaluate(node.operand)
            if isinstance(node.op, ast.Not):
                return not value
            if isinstance(node.op, ast.UAdd) and type(value) in (int, float):
                return value
            if isinstance(node.op, ast.USub) and type(value) in (int, float):
                return _check_runtime_value(-value)
            raise _PracticeFailure("TypeError", "This unary operation needs a number.")
        if isinstance(node, ast.BinOp):
            left = self.evaluate(node.left)
            right = self.evaluate(node.right)
            operation = _BINARY_OPERATORS.get(type(node.op))
            if operation is None:
                raise _PracticeFailure("unsupported_syntax", "This arithmetic operation is not supported.")
            if type(node.op) in {ast.Sub, ast.Mult, ast.Div, ast.FloorDiv, ast.Mod}:
                if type(left) not in (int, float) or type(right) not in (int, float):
                    raise _PracticeFailure("TypeError", "This arithmetic operation needs numbers.")
            if type(node.op) is ast.Add and not (
                type(left) is type(right) and type(left) in (int, float, str, list, tuple)
            ):
                raise _PracticeFailure("TypeError", "These values cannot be added in this trainer.")
            if type(node.op) is ast.Mult and (
                type(left) in (str, list, tuple) or type(right) in (str, list, tuple)
            ):
                collection, count = (left, right) if type(left) in (str, list, tuple) else (right, left)
                if type(count) is not int or count < 0 or len(collection) * count > MAX_COLLECTION_ITEMS:
                    raise _PracticeFailure("iteration_limit", "The resulting collection is too large.")
            try:
                return _check_runtime_value(operation(left, right))
            except _PracticeFailure:
                raise
            except (ArithmeticError, TypeError, ValueError, OverflowError) as exc:
                raise _PracticeFailure(type(exc).__name__, str(exc)[:160]) from None
        if isinstance(node, ast.Compare):
            left = self.evaluate(node.left)
            for operation_node, comparator in zip(node.ops, node.comparators, strict=True):
                right = self.evaluate(comparator)
                operation = _COMPARE_OPERATORS.get(type(operation_node))
                if operation is None:
                    raise _PracticeFailure("unsupported_syntax", "This comparison is not supported.")
                try:
                    if not operation(left, right):
                        return False
                except TypeError as exc:
                    raise _PracticeFailure("TypeError", str(exc)[:160]) from None
                left = right
            return True
        if isinstance(node, ast.BoolOp):
            values = node.values
            if isinstance(node.op, ast.And):
                result: Any = True
                for item in values:
                    result = self.evaluate(item)
                    if not result:
                        return result
                return result
            if isinstance(node.op, ast.Or):
                result = False
                for item in values:
                    result = self.evaluate(item)
                    if result:
                        return result
                return result
        if isinstance(node, ast.Subscript):
            container = self.evaluate(node.value)
            index = self.evaluate(node.slice)
            try:
                return _check_runtime_value(container[index])
            except (IndexError, KeyError, TypeError) as exc:
                raise _PracticeFailure(type(exc).__name__, str(exc)[:160]) from None
        if isinstance(node, ast.Slice):
            lower = self.evaluate(node.lower) if node.lower is not None else None
            upper = self.evaluate(node.upper) if node.upper is not None else None
            step = self.evaluate(node.step) if node.step is not None else None
            if any(value is not None and type(value) is not int for value in (lower, upper, step)):
                raise _PracticeFailure("TypeError", "Slice indexes must be integers.")
            if step == 0:
                raise _PracticeFailure("ValueError", "Slice step cannot be zero.")
            return slice(lower, upper, step)
        if isinstance(node, ast.Call):
            name = node.func.id
            args = [self.evaluate(argument) for argument in node.args]
            try:
                if name == "len" and len(args) == 1 and isinstance(args[0], (str, list, tuple, dict, range)):
                    return len(args[0])
                if name == "range" and 1 <= len(args) <= 3 and all(type(item) is int for item in args):
                    result = range(*args)
                    if len(result) > MAX_COLLECTION_ITEMS:
                        raise _PracticeFailure("iteration_limit", "The practice loop limit was reached.")
                    return result
                if name == "sum" and len(args) == 1 and isinstance(args[0], (list, tuple, range)):
                    if len(args[0]) > MAX_COLLECTION_ITEMS:
                        raise _PracticeFailure("iteration_limit", "The practice loop limit was reached.")
                    if any(type(item) not in (int, float) for item in args[0]):
                        raise _PracticeFailure("TypeError", "sum() expects numeric values in this trainer.")
                    return _check_runtime_value(sum(args[0]))
                if name in {"min", "max"} and len(args) == 1 and isinstance(args[0], (list, tuple, range)):
                    if len(args[0]) > MAX_COLLECTION_ITEMS:
                        raise _PracticeFailure("iteration_limit", "The practice loop limit was reached.")
                    if not args[0]:
                        raise _PracticeFailure("ValueError", f"{name}() arg is an empty sequence")
                    return _check_runtime_value((min if name == "min" else max)(args[0]))
                if name == "abs" and len(args) == 1 and type(args[0]) in (int, float):
                    return _check_runtime_value(abs(args[0]))
            except _PracticeFailure:
                raise
            except (ArithmeticError, TypeError, ValueError, OverflowError) as exc:
                raise _PracticeFailure(type(exc).__name__, str(exc)[:160]) from None
            raise _PracticeFailure("TypeError", f"'{name}' received unsupported arguments.")
        raise _PracticeFailure("unsupported_syntax", "This Python expression is not supported by the trainer.")

    def execute_block(self, statements: list[ast.stmt]) -> None:
        for statement in statements:
            self.budget.step()
            if isinstance(statement, ast.Return):
                value = self.evaluate(statement.value) if statement.value is not None else None
                raise _Return(_check_runtime_value(value))
            if isinstance(statement, ast.Pass):
                continue
            if isinstance(statement, ast.Assign):
                value = self.evaluate(statement.value)
                self.env[statement.targets[0].id] = value
                continue
            if isinstance(statement, ast.AugAssign):
                name = statement.target.id
                if name not in self.env:
                    raise _PracticeFailure("NameError", f"Name '{name}' is not defined.")
                operation = _AUGMENTED_OPERATORS[type(statement.op)]
                try:
                    self.env[name] = _check_runtime_value(operation(self.env[name], self.evaluate(statement.value)))
                except _PracticeFailure:
                    raise
                except (ArithmeticError, TypeError, ValueError, OverflowError) as exc:
                    raise _PracticeFailure(type(exc).__name__, str(exc)[:160]) from None
                continue
            if isinstance(statement, ast.If):
                branch = statement.body if self.evaluate(statement.test) else statement.orelse
                self.execute_block(branch)
                continue
            if isinstance(statement, ast.For):
                iterable = self.evaluate(statement.iter)
                if not isinstance(iterable, (list, tuple, str, range)):
                    raise _PracticeFailure("TypeError", "A for loop needs a list, tuple, text, or range.")
                if len(iterable) > MAX_COLLECTION_ITEMS:
                    raise _PracticeFailure("iteration_limit", "The practice loop limit was reached.")
                name = statement.target.id
                for value in iterable:
                    self.budget.iteration()
                    self.env[name] = value
                    self.execute_block(statement.body)
                continue
            if isinstance(statement, ast.Raise):
                message = statement.exc.args[0].value
                raise _PracticeFailure("ValueError", message[:160])
            raise _PracticeFailure("unsupported_syntax", "This Python statement is not supported by the trainer.")


def execute_python_practice(source: str, arguments: dict[str, Any]) -> dict[str, Any]:
    """Interpret one safe, bounded solve function without Python exec or subprocesses."""
    try:
        function = _validate_program(source)
        if not isinstance(arguments, dict) or len(arguments) > MAX_ARGUMENTS:
            raise _PracticeFailure("invalid_arguments", "Pass a small object of named input values.")
        expected_names = [argument.arg for argument in function.args.args]
        if set(arguments) != set(expected_names):
            raise _PracticeFailure("invalid_arguments", "Input names must match the solve function parameters.")
        for name, value in arguments.items():
            if not name.isidentifier() or name.startswith("__"):
                raise _PracticeFailure("invalid_arguments", "Input names must be simple identifiers.")
            _validate_external_value(value)
        interpreter = _Interpreter(dict(arguments))
        try:
            interpreter.execute_block(function.body)
            result = None
        except _Return as returned:
            result = returned.value
        _validate_external_value(result)
        return {"status": "ok", "result": result}
    except _PracticeFailure as failure:
        return {"status": "error", "code": failure.code, "message": failure.message[:200]}
    except (ArithmeticError, TypeError, ValueError, IndexError, KeyError, OverflowError) as exc:
        return {"status": "error", "code": type(exc).__name__, "message": str(exc)[:200]}
