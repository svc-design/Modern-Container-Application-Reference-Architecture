#!/usr/bin/env python3
"""Utility commands for managing Pulumi stacks in this repository."""
from __future__ import annotations

import argparse
from datetime import datetime
import os
import stat
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Dict, Optional, Union

PROJECT_DIR = Path(__file__).resolve().parent
DEFAULT_BACKUPS_DIR = Path("backups")
DEFAULT_CONFIG_PATHS: Dict[str, str] = {
    "aws": "config/aws-global",
    "alicloud": "config/alicloud",
    "vultr": "config/vultr",
}
CLOUD_CHOICES = tuple(DEFAULT_CONFIG_PATHS.keys())
DEFAULT_CREDENTIALS_FILE = Path(
    os.environ.get("IAC_CREDENTIALS_FILE", Path.home() / ".iac/credentials")
)
DEFAULT_PASSPHRASE_FILE = Path.home() / ".pulumi-passphrase"


class CLIError(RuntimeError):
    """Raised when the CLI encounters a user facing error."""


@dataclass
class PulumiContext:
    """Holds configuration required for running Pulumi commands."""

    pulumi_bin: str
    stack_name: Optional[str]
    backend_url: Optional[str]
    backups_dir: Path
    cloud: Optional[str]

    def run(
        self,
        *args: str,
        check: bool = True,
        capture_output: bool = False,
        stdin: Optional[str] = None,
    ) -> subprocess.CompletedProcess[str]:
        """Execute a Pulumi command."""
        try:
            return subprocess.run(  # noqa: S603,S607 (command comes from environment)
                [self.pulumi_bin, *args],
                check=check,
                capture_output=capture_output,
                text=True,
                input=stdin,
            )
        except FileNotFoundError as exc:  # pragma: no cover - runtime safeguard
            raise CLIError(
                f"Unable to locate Pulumi executable '{self.pulumi_bin}'."
            ) from exc


# ---------------------------------------------------------------------------
# Credential loading helpers
# ---------------------------------------------------------------------------

def _to_dict(value: Any) -> Dict[str, Any]:
    return value if isinstance(value, dict) else {}


def _find_section(data: Dict[str, Any], name: str) -> Dict[str, Any]:
    lname = name.lower()
    for key, value in _to_dict(data).items():
        if str(key).lower() == lname:
            return _to_dict(value)
    return {}


def _find_value(section: Dict[str, Any], *names: str) -> Optional[Any]:
    target_names = {name.lower() for name in names}
    for key, value in _to_dict(section).items():
        if str(key).lower() in target_names:
            return value
    return None


def _ensure_string(value: Any) -> Optional[str]:
    return value.strip() if isinstance(value, str) else None


def _expand_path(value: str) -> Path:
    return Path(os.path.expandvars(value)).expanduser()


def _select_backend(backends: Any) -> Optional[str]:
    if isinstance(backends, str):
        return _ensure_string(backends)

    if isinstance(backends, (list, tuple)):
        candidates = [candidate for candidate in (_ensure_string(item) for item in backends) if candidate]
        for candidate in candidates:
            if candidate.lower().startswith("s3://"):
                return candidate
        return candidates[0] if candidates else None

    if isinstance(backends, dict):
        direct = _find_value(backends, "url", "uri", "s3", "backend")
        if isinstance(direct, (str, list, tuple, dict)):
            selected = _select_backend(direct)
            if selected:
                return selected
        for value in backends.values():
            selected = _select_backend(value)
            if selected:
                return selected

    return None


def _maybe_set_env(key: str, raw_value: Any) -> None:
    value = _ensure_string(raw_value)
    if value and not os.environ.get(key):
        os.environ[key] = value


def _warn(message: str) -> None:
    print(f"[警告] {message}", file=sys.stderr)


def _load_credentials_file(path: Path) -> None:
    if not path.exists():
        return

    try:
        perms = stat.S_IMODE(path.stat().st_mode)
        if perms != 0o400:
            _warn(f"{path} 权限建议设置为 0400（当前: {oct(perms)}）。")
    except OSError:
        pass

    try:
        import yaml
    except ModuleNotFoundError:  # pragma: no cover - depends on runtime
        _warn("解析凭据文件需要 PyYAML，请运行 'pip install PyYAML'.")
        return

    try:
        with path.open("r", encoding="utf-8") as handler:
            data: Dict[str, Any] = yaml.safe_load(handler) or {}
    except FileNotFoundError:
        return
    except yaml.YAMLError as exc:  # type: ignore[attr-defined]
        _warn(f"无法解析凭据文件: {exc}")
        return

    iac_state = _find_section(data, "iac_state")
    backend_section = _find_section(iac_state, "backend")
    _maybe_set_env("IAC_STATE_BACKEND", _select_backend(backend_section))
    backend_region = _find_value(backend_section, "region", "aws_region", "default_region")
    _maybe_set_env("AWS_REGION", backend_region)
    _maybe_set_env("AWS_DEFAULT_REGION", backend_region)

    state_auth = _find_section(iac_state, "auth")
    _maybe_set_env("AWS_ACCESS_KEY_ID", _find_value(state_auth, "ak", "access_key"))
    _maybe_set_env("AWS_SECRET_ACCESS_KEY", _find_value(state_auth, "sk", "secret_key"))

    aws_section = (
        _find_section(data, "aws-global")
        or _find_section(data, "aws_global")
        or _find_section(data, "aws")
    )
    _maybe_set_env("AWS_ACCESS_KEY_ID", _find_value(aws_section, "ak", "access_key", "access_key_id"))
    _maybe_set_env("AWS_SECRET_ACCESS_KEY", _find_value(aws_section, "sk", "secret_key", "secret_access_key"))
    aws_region = _find_value(aws_section, "region", "aws_region", "default_region")
    _maybe_set_env("AWS_REGION", aws_region)
    _maybe_set_env("AWS_DEFAULT_REGION", aws_region)

    alicloud_section = _find_section(data, "alicloud")
    _maybe_set_env("ALICLOUD_ACCESS_KEY", _find_value(alicloud_section, "ak", "access_key", "access_key_id"))
    _maybe_set_env("ALICLOUD_SECRET_KEY", _find_value(alicloud_section, "sk", "secret_key", "secret_access_key"))

    vultr_section = _find_section(data, "vultr")
    _maybe_set_env("VULTR_API_KEY", _find_value(vultr_section, "api_key", "apikey"))

    pulumi_section = _find_section(data, "pulumi")
    passphrase = _ensure_string(
        _find_value(
            pulumi_section,
            "passphrase",
            "config_passphrase",
            "pulumi_passphrase",
        )
    )
    if passphrase and not os.environ.get("PULUMI_CONFIG_PASSPHRASE"):
        os.environ["PULUMI_CONFIG_PASSPHRASE"] = passphrase

    passphrase_file = _ensure_string(
        _find_value(
            pulumi_section,
            "passphrase_file",
            "config_passphrase_file",
            "pulumi_passphrase_file",
        )
    )
    if passphrase_file and not os.environ.get("PULUMI_CONFIG_PASSPHRASE_FILE"):
        os.environ["PULUMI_CONFIG_PASSPHRASE_FILE"] = str(
            _expand_path(passphrase_file)
        )


def _ensure_region_harmony() -> None:
    if os.environ.get("AWS_REGION") and not os.environ.get("AWS_DEFAULT_REGION"):
        os.environ["AWS_DEFAULT_REGION"] = os.environ["AWS_REGION"]
    elif os.environ.get("AWS_DEFAULT_REGION") and not os.environ.get("AWS_REGION"):
        os.environ["AWS_REGION"] = os.environ["AWS_DEFAULT_REGION"]


# ---------------------------------------------------------------------------
# Command helpers
# ---------------------------------------------------------------------------

def _emit_process_output(result: subprocess.CompletedProcess[str]) -> None:
    if result.stdout:
        print(result.stdout, end="")
    if result.stderr:
        print(result.stderr, file=sys.stderr, end="")


def _should_retry_login(message: str) -> bool:
    lowered = message.lower()
    transient_terms = (
        "timeout",
        "temporarily unavailable",
        "connection reset",
        "connection refused",
        "i/o timeout",
        "tls handshake timeout",
        "requesterror",
    )
    return any(term in lowered for term in transient_terms)


def _login_backend_with_retry(context: PulumiContext, backend: str) -> None:
    default_attempts = 3
    default_delay = 2.0

    raw_attempts = os.environ.get("PULUMI_LOGIN_RETRIES")
    raw_delay = os.environ.get("PULUMI_LOGIN_RETRY_DELAY")

    attempts = default_attempts
    delay = default_delay

    if raw_attempts:
        try:
            attempts = max(1, int(raw_attempts))
        except ValueError:
            _warn(
                "PULUMI_LOGIN_RETRIES 必须为整数，已回退至默认值 3。",
            )
    if raw_delay:
        try:
            delay = max(0.0, float(raw_delay))
        except ValueError:
            _warn(
                "PULUMI_LOGIN_RETRY_DELAY 必须为数字，已回退至默认值 2 秒。",
            )

    last_error: Optional[subprocess.CompletedProcess[str]] = None
    for attempt in range(1, attempts + 1):
        result = context.run(
            "login",
            backend,
            check=False,
            capture_output=True,
        )
        if result.returncode == 0:
            _emit_process_output(result)
            return

        last_error = result
        combined_message = "\n".join(
            part.strip()
            for part in (result.stderr or "", result.stdout or "")
            if part
        )

        if attempt == attempts or not _should_retry_login(combined_message):
            _emit_process_output(result)
            detail = combined_message or "Pulumi 未返回详细错误信息"
            raise CLIError(
                "Pulumi 登录 S3 backend 失败，请检查网络连通性、代理设置或 S3 权限。"
                f" 原始错误：{detail}",
            )

        wait_seconds = min(delay * (2 ** (attempt - 1)), 30.0)
        short_error = combined_message.splitlines()[0] if combined_message else "未知错误"
        _warn(
            "Pulumi 登录失败 (第 {attempt} 次)。将在 {wait:.1f}s 后重试。错误: {error}".format(
                attempt=attempt,
                wait=wait_seconds,
                error=short_error,
            )
        )
        time.sleep(wait_seconds)

    if last_error is not None:
        _emit_process_output(last_error)
    raise CLIError("Pulumi 登录失败，且未返回具体错误信息。")


def _require_backend(context: PulumiContext) -> str:
    backend = (
        context.backend_url
        or os.environ.get("IAC_STATE_BACKEND")
        or os.environ.get("IAC_State_backend")
    )
    if not backend:
        raise CLIError("未设置 IAC_STATE_BACKEND 环境变量，无法连接到 S3 backend.")
    if not backend.startswith("s3://"):
        raise CLIError("IAC_STATE_BACKEND 必须为 s3:// 开头的 Pulumi 后端地址.")
    if not os.environ.get("AWS_REGION") and not os.environ.get("AWS_DEFAULT_REGION"):
        raise CLIError(
            "未设置 AWS_REGION 或 AWS_DEFAULT_REGION 环境变量，无法登录到 S3 backend."
            " 请在凭据文件中添加 region 字段，或在运行脚本前导出该环境变量。"
        )

    context.backend_url = backend
    _require_passphrase()
    _login_backend_with_retry(context, backend)
    return backend


def _require_stack(context: PulumiContext) -> str:
    stack_name = context.stack_name or os.environ.get("PULUMI_STACK")
    if not stack_name:
        raise CLIError("未设置 PULUMI_STACK 环境变量.")

    context.stack_name = stack_name
    result = context.run("stack", "select", stack_name, check=False, capture_output=True)
    if result.returncode != 0:
        context.run("stack", "init", stack_name)
    return stack_name


def _require_passphrase() -> None:
    if os.environ.get("PULUMI_CONFIG_PASSPHRASE"):
        return

    file_env = os.environ.get("PULUMI_CONFIG_PASSPHRASE_FILE")
    if file_env:
        file_path = _expand_path(file_env)
        if file_path.is_file():
            os.environ["PULUMI_CONFIG_PASSPHRASE_FILE"] = str(file_path)
            return
        raise CLIError(
            f"PULUMI_CONFIG_PASSPHRASE_FILE 指向不存在的文件: {file_path}."
            " 请确认该文件存在或改用 PULUMI_CONFIG_PASSPHRASE 环境变量。"
        )

    if DEFAULT_PASSPHRASE_FILE.is_file():
        os.environ.setdefault(
            "PULUMI_CONFIG_PASSPHRASE_FILE", str(DEFAULT_PASSPHRASE_FILE)
        )
        return

    raise CLIError(
        "未检测到 Pulumi passphrase，无法登录到 S3 backend."
        " 请设置 PULUMI_CONFIG_PASSPHRASE 环境变量，"
        "或创建 ~/.pulumi-passphrase 文件并写入密钥后重试。"
    )


def _command_init(context: PulumiContext, _: argparse.Namespace) -> None:
    backend = _require_backend(context)
    stack_name = _require_stack(context)
    print(f"Pulumi backend 已配置: {backend}")
    print(f"Pulumi stack 已就绪: {stack_name}")


def _command_create(context: PulumiContext, _: argparse.Namespace) -> None:
    _require_backend(context)
    stack = _require_stack(context)
    context.run("up", "--stack", stack, "--yes", "--skip-preview")


def _command_migrate(context: PulumiContext, _: argparse.Namespace) -> None:
    _require_backend(context)
    stack = _require_stack(context)
    context.run("refresh", "--stack", stack, "--yes")


def _command_upgrade(context: PulumiContext, _: argparse.Namespace) -> None:
    _require_backend(context)
    stack = _require_stack(context)
    context.run("up", "--stack", stack, "--yes")


def _command_backup(context: PulumiContext, _: argparse.Namespace) -> None:
    _require_backend(context)
    stack = _require_stack(context)

    backups_dir = context.backups_dir
    backups_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.utcnow().strftime("%Y%m%d%H%M%S")
    backup_file = backups_dir / f"{stack}-{timestamp}.json"
    export = context.run("stack", "export", "--stack", stack, capture_output=True)
    backup_file.write_text(export.stdout, encoding="utf-8")
    print(f"Pulumi stack 已备份到 {backup_file}")


def _command_restore(context: PulumiContext, args: argparse.Namespace) -> None:
    _require_backend(context)
    stack = _require_stack(context)

    backup_path = args.file or os.environ.get("BACKUP_FILE", "")
    if not backup_path:
        raise CLIError("restore 命令需要提供备份文件路径作为参数或通过 BACKUP_FILE 环境变量传入.")

    backup_file = Path(backup_path)
    if not backup_file.is_file():
        raise CLIError(f"找不到备份文件 {backup_file}.")

    contents = backup_file.read_text(encoding="utf-8")
    context.run("stack", "import", "--stack", stack, stdin=contents)


def _command_destroy(context: PulumiContext, _: argparse.Namespace) -> None:
    _require_backend(context)
    stack = _require_stack(context)
    context.run("destroy", "--stack", stack, "--yes")


COMMANDS: Dict[str, Callable[[PulumiContext, argparse.Namespace], None]] = {
    "init": _command_init,
    "create": _command_create,
    "migrate": _command_migrate,
    "upgrade": _command_upgrade,
    "backup": _command_backup,
    "restore": _command_restore,
    "destroy": _command_destroy,
}


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="cli.py",
        description="Pulumi stack helper commands for the Modern Container Application reference architecture.",
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument(
        "--credentials",
        dest="credentials",
        type=Path,
        metavar="CREDENTIALS",
        help="自定义凭据文件路径，默认读取 ~/.iac/credentials",
    )
    parser.add_argument(
        "--cloud",
        dest="cloud",
        choices=CLOUD_CHOICES,
        metavar="{aws, alicloud, vultr}",
        required=True,
        help="选择部署的云厂商（支持 aws、alicloud、vultr）",
    )

    parent = argparse.ArgumentParser(add_help=False, formatter_class=argparse.RawTextHelpFormatter)
    parent.add_argument(
        "--stack",
        dest="stack",
        help="Pulumi Stack 名称（默认读取 PULUMI_STACK 环境变量）",
    )
    parent.add_argument(
        "--backend",
        dest="backend",
        help="Pulumi backend 地址（默认读取 IAC_STATE_BACKEND 环境变量或凭据文件）",
    )
    parent.add_argument(
        "--backups-dir",
        dest="backups_dir",
        type=Path,
        help="备份文件保存目录，默认为 ./backups",
    )
    parser.usage = (
        "cli.py [-h] [--credentials CREDENTIALS 默认~/.iac/credentials] "
        "--cloud {aws, alicloud, vultr} {init,create,migrate,upgrade,backup,restore,destroy}"
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    for command, handler in COMMANDS.items():
        help_text = {
            "init": "登录 backend 并准备 Pulumi Stack",
            "create": "执行 pulumi up --yes --skip-preview",
            "migrate": "执行 pulumi refresh --yes",
            "upgrade": "执行 pulumi up --yes",
            "backup": "导出 Pulumi stack 状态到备份文件",
            "restore": "从备份文件恢复 Pulumi stack",
            "destroy": "销毁当前 Pulumi stack 资源",
        }[command]
        subparser = subparsers.add_parser(
            command,
            parents=[parent],
            help=help_text,
            formatter_class=argparse.RawTextHelpFormatter,
        )
        subparser.set_defaults(handler=handler)
        if command == "restore":
            subparser.add_argument(
                "file",
                nargs="?",
                help="备份文件路径；也可使用 BACKUP_FILE 环境变量",
            )

    return parser


def main(argv: Optional[list[str]] = None) -> None:
    os.chdir(PROJECT_DIR)
    parser = _build_parser()
    args = parser.parse_args(argv)

    credentials_path = args.credentials or DEFAULT_CREDENTIALS_FILE
    _load_credentials_file(credentials_path)
    _ensure_region_harmony()

    backups_dir_value: Optional[Union[Path, str]]
    if args.backups_dir is not None:
        backups_dir_value = args.backups_dir
    else:
        backups_dir_value = os.environ.get("PULUMI_BACKUP_DIR")

    backups_dir = Path(backups_dir_value) if backups_dir_value else DEFAULT_BACKUPS_DIR

    context = PulumiContext(
        pulumi_bin=os.environ.get("PULUMI_BIN", "pulumi"),
        stack_name=args.stack or os.environ.get("PULUMI_STACK") or os.environ.get("STACK_NAME") or os.environ.get("STACK"),
        backend_url=args.backend or os.environ.get("IAC_STATE_BACKEND") or os.environ.get("IAC_State_backend"),
        backups_dir=backups_dir,
        cloud=args.cloud or os.environ.get("IAC_CLOUD") or os.environ.get("PULUMI_CLOUD"),
    )

    if args.stack:
        os.environ["PULUMI_STACK"] = args.stack
    if args.backend:
        os.environ["IAC_STATE_BACKEND"] = args.backend
    if args.backups_dir:
        os.environ["PULUMI_BACKUP_DIR"] = str(args.backups_dir)
    if args.cloud:
        os.environ["IAC_CLOUD"] = args.cloud

    cloud = context.cloud
    config_path = os.environ.get("CONFIG_PATH")
    if not config_path and cloud:
        default_path = DEFAULT_CONFIG_PATHS.get(cloud)
        if default_path:
            os.environ["CONFIG_PATH"] = default_path

    handler = getattr(args, "handler", COMMANDS[args.command])

    try:
        handler(context, args)
    except CLIError as exc:
        print(f"[错误] {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
    except subprocess.CalledProcessError as exc:
        print(f"[错误] Pulumi 命令执行失败: {' '.join(exc.cmd)}", file=sys.stderr)
        raise SystemExit(exc.returncode) from exc


if __name__ == "__main__":
    main()
