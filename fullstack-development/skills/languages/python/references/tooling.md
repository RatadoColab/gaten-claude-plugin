# Python — Ferramentas e Ambiente

Toolchain recomendada para projetos Python **3.14** em set/2026. Tudo configurado num único
`pyproject.toml`.

---

## uv — Gerenciamento de Pacotes e Versões

`uv` é o padrão de facto: substitui `pip`, `pip-tools`, `virtualenv`, `pipx` e `pyenv` num binário.

```bash
uv init meu-projeto              # scaffold com pyproject.toml + .python-version
uv python install 3.14          # instala o interpretador (3.14t para o build free-threaded)
uv add "pydantic>=2.12" httpx    # adiciona dep e atualiza uv.lock
uv add --dev pytest ruff mypy    # dependências de desenvolvimento
uv sync                          # cria/atualiza o .venv a partir do lock
uv run pytest                    # executa no ambiente do projeto, sem activate
uv lock --upgrade                # recalcula o lock
uv build                         # gera sdist + wheel
```

`uv.lock` é multi-plataforma e determinístico — versionar. Dispensa `requirements.txt` pinado; gerar
um só se algum consumidor externo exigir (`uv export --format requirements-txt`).

Fixar a versão do interpretador em `.python-version` (lido por `uv` e por CI) e em
`requires-python` no `pyproject.toml`.

---

## ruff — Lint + Formatação

`ruff` substitui `black`, `isort`, `flake8`, `pyupgrade`, `pydocstyle` e dezenas de plugins. É ordens
de grandeza mais rápido e roda como linter **e** formatter.

```bash
uv run ruff check --fix .        # lint com autofix
uv run ruff format .             # formatação (compatível com o estilo do black)
```

---

## Type checking

| Ferramenta | Nota |
|---|---|
| `mypy --strict` | Baseline recomendado para código de produção |
| `pyright` | Mais rápido, inferência mais agressiva; base do Pylance no VS Code |
| `ty` (Astral) | Type checker novo, em preview — acompanhar, ainda não adotar como único gate |

```bash
uv run mypy src
```

Type checkers nunca avaliam anotações em runtime — comportam-se igual sob PEP 649. Diferenças de
avaliação tardia só afetam ferramentas que introspeccionam em runtime.

---

## pyproject.toml — Configuração de Referência

```toml
[project]
name = "meu-projeto"
version = "0.1.0"
requires-python = ">=3.14"
dependencies = [
    "pydantic>=2.12",
    "httpx>=0.27",
]

[dependency-groups]
dev = ["pytest>=8", "pytest-cov", "ruff", "mypy"]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.ruff]
line-length = 88
target-version = "py314"

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM", "RUF"]   # pycodestyle, pyflakes, isort, pyupgrade, bugbear...
ignore = ["E501"]                                    # linha longa fica a cargo do formatter

[tool.mypy]
python_version = "3.14"
strict = true
warn_unreachable = true

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = ["--strict-markers", "--strict-config", "-ra"]

[tool.coverage.run]
source = ["src"]
branch = true
```

`target-version = "py314"` faz o `ruff` reescrever para os idiomas mais novos (ex.: `Optional[X]` →
`X | None`, `TypeVar` legado → sintaxe PEP 695 via regra `UP`).

---

## pre-commit

```yaml
# .pre-commit-config.yaml — fixar cada `rev` na tag mais recente ao configurar
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: <tag mais recente>
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: <tag mais recente>
    hooks:
      - id: mypy
        additional_dependencies: [pydantic]
```

```bash
uv run pre-commit install
```

---

## Ferramentas de diagnóstico da stdlib (3.14)

| Comando | Uso |
|---|---|
| `python -m asyncio ps PID` / `pstree PID` | Tabela / árvore de tasks de um processo async vivo |
| `python -m pdb -p PID` | Anexa o debugger a um processo em execução (PEP 768) |
| `python -X importtime=2 app.py` | Perfil de tempo de import, agora marcando módulos em cache |
| `python -m json data.json` | Formata/valida JSON (substitui `python -m json.tool`) |

---

## Docker

```dockerfile
FROM python:3.14-slim AS base
COPY --from=ghcr.io/astral-sh/uv:0.9.2 /uv /usr/local/bin/uv   # fixar a versão, não `latest`

WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project     # camada de deps, cacheável

COPY . .
RUN uv sync --frozen --no-dev
CMD ["uv", "run", "python", "-m", "meu_pacote"]
```

Para o build free-threaded, trocar a base por `python:3.14t-slim` (ou `python:3.14-slim` + `uv python
install 3.14t`). Medir a penalidade single-thread antes de adotar.

---

## Supply chain

Auditoria de dependências, SBOM e assinatura ficam em **`domains/security/SKILL.md`** (dependências da
aplicação, A03/A05) e **`domains/devsecops/SKILL.md`** (scanning no pipeline). Não duplicar aqui —
apenas garantir `uv.lock` versionado e `uv sync --frozen` em CI.
